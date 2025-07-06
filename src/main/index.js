const { app, BrowserWindow, ipcMain, shell } = require('electron');
const { autoUpdater } = require('electron-updater');
const path = require('path');
const ytdl = require('youtube-dl-exec');
const ytdlCore = require('ytdl-core');
const fs = require('fs').promises;
const { existsSync, createWriteStream } = require('fs');
const os = require('os');
const ffmpeg = require('fluent-ffmpeg');
const ffmpegStatic = require('ffmpeg-static');

// Configure ffmpeg
ffmpeg.setFfmpegPath(ffmpegStatic);

let mainWindow;
const isDev = process.argv.includes('--dev');

// Fix PATH for production environment
if (!isDev) {
  process.env.PATH = `/Library/Frameworks/Python.framework/Versions/3.13/bin:/usr/bin:/bin:/usr/local/bin:${process.env.PATH}`;
  console.log('Production: Enhanced PATH for yt-dlp');
}

// Configure auto-updater
autoUpdater.autoDownload = true;
autoUpdater.autoInstallOnAppQuit = true;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1200,
    minHeight: 700,
    icon: path.join(__dirname, '../../public/icon.png'),
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, '../preload/index.js')
    },
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    backgroundColor: '#09090b',
  });

  if (isDev) {
    mainWindow.loadURL('http://localhost:5173');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, '../../dist/index.html'));
    // Open DevTools in production to debug
    mainWindow.webContents.openDevTools();
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(() => {
  createWindow();
  
  // Check for updates every 6 hours
  if (!isDev) {
    autoUpdater.checkForUpdatesAndNotify();
    setInterval(() => {
      autoUpdater.checkForUpdatesAndNotify();
    }, 6 * 60 * 60 * 1000);
  }
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (mainWindow === null) {
    createWindow();
  }
});

// Function to transcribe large files in chunks
async function transcribeInChunks(audioFile, apiKey, geminiApiKey, geminiPrompt) {
  const FormData = require('form-data');
  const axios = require('axios');
  const tempDir = require('os').tmpdir();
  
  try {
    console.log('🔄 Iniciando transcripción por chunks...');
    
    // Get audio duration with error handling
    const duration = await new Promise((resolve, reject) => {
      ffmpeg.ffprobe(audioFile, (err, metadata) => {
        if (err) {
          console.error('Error getting audio duration:', err);
          reject(new Error(`No se pudo obtener la duración del audio: ${err.message}`));
        } else if (!metadata || !metadata.format || !metadata.format.duration) {
          reject(new Error('Metadata del audio inválida o corrupta'));
        } else {
          resolve(metadata.format.duration);
        }
      });
    });
    
    // Validate duration
    if (isNaN(duration) || duration <= 0) {
      throw new Error(`Duración de audio inválida: ${duration} segundos`);
    }
    
    console.log(`⏱️ Duración total del audio: ${Math.round(duration / 60)} minutos`);
    
    // Calculate chunk size (aim for ~20MB chunks)
    const stats = await fs.stat(audioFile);
    const fileSizeMB = stats.size / 1024 / 1024;
    const numChunks = Math.ceil(fileSizeMB / 20);
    const chunkDurationSeconds = duration / numChunks;
    
    // Validate chunk calculations
    if (numChunks <= 0 || isNaN(chunkDurationSeconds) || chunkDurationSeconds <= 0) {
      throw new Error(`Cálculo de chunks inválido: ${numChunks} chunks, ${chunkDurationSeconds}s cada uno`);
    }
    
    // Safety limit: too many chunks could overwhelm the system
    if (numChunks > 50) {
      throw new Error(`Video demasiado largo: requiere ${numChunks} chunks (máximo 50). El archivo es de ${fileSizeMB.toFixed(2)}MB, considera usar un video más corto.`);
    }
    
    // Safety limit: chunks too short could cause issues
    if (chunkDurationSeconds < 10) {
      throw new Error(`Chunks demasiado cortos (${chunkDurationSeconds.toFixed(1)}s). El video requiere chunks de al menos 10 segundos.`);
    }
    
    console.log(`📦 Dividiendo en ${numChunks} chunks de ~${Math.round(chunkDurationSeconds / 60)} minutos cada uno`);
    
    // Create chunks and transcribe in parallel
    const sessionId = Date.now();
    const chunkPromises = [];
    const chunkFiles = [];
    
    for (let i = 0; i < numChunks; i++) {
      const startTime = i * chunkDurationSeconds;
      const chunkFile = path.join(tempDir, `quotify_chunk_${sessionId}_${i}.ogg`);
      chunkFiles.push(chunkFile);
      
      // Create chunk with improved error handling
      const chunkPromise = new Promise((resolve, reject) => {
        const command = ffmpeg(audioFile)
          .seekInput(startTime)
          .duration(chunkDurationSeconds)
          .audioCodec('libopus')
          .audioBitrate('16k')
          .audioChannels(1)
          .audioFrequency(16000)
          .output(chunkFile)
          .on('end', () => {
            console.log(`✅ Chunk ${i + 1}/${numChunks} creado`);
            resolve();
          })
          .on('error', (err) => {
            console.error(`❌ Error creando chunk ${i + 1}:`, err.message);
            reject(new Error(`Error creando chunk ${i + 1}: ${err.message}`));
          })
          .on('stderr', (stderrLine) => {
            // Log ffmpeg stderr for debugging but don't fail
            if (stderrLine.includes('Error') || stderrLine.includes('Failed')) {
              console.warn(`⚠️ FFmpeg warning chunk ${i + 1}:`, stderrLine);
            }
          });
        
        try {
          command.run();
        } catch (runError) {
          reject(new Error(`Error iniciando ffmpeg para chunk ${i + 1}: ${runError.message}`));
        }
      });
      
      chunkPromises.push(chunkPromise);
    }
    
    // Wait for all chunks to be created with timeout
    try {
      await Promise.all(chunkPromises);
    } catch (chunkError) {
      // Clean up any created chunks
      for (const chunkFile of chunkFiles) {
        try {
          if (existsSync(chunkFile)) await fs.unlink(chunkFile);
        } catch (e) {}
      }
      throw new Error(`Error creando chunks: ${chunkError.message}`);
    }
    
    // Validate all chunks were created successfully
    const missingChunks = [];
    for (let i = 0; i < chunkFiles.length; i++) {
      const chunkFile = chunkFiles[i];
      if (!existsSync(chunkFile)) {
        missingChunks.push(i + 1);
      } else {
        const chunkStats = await fs.stat(chunkFile);
        if (chunkStats.size === 0) {
          missingChunks.push(`${i + 1} (vacío)`);
        }
      }
    }
    
    if (missingChunks.length > 0) {
      // Clean up
      for (const chunkFile of chunkFiles) {
        try {
          if (existsSync(chunkFile)) await fs.unlink(chunkFile);
        } catch (e) {}
      }
      throw new Error(`Chunks no creados correctamente: ${missingChunks.join(', ')}`);
    }
    
    console.log('📦 Todos los chunks creados, iniciando transcripción en paralelo...');
    
    // Transcribe all chunks in parallel
    const transcriptionPromises = chunkFiles.map(async (chunkFile, index) => {
      try {
        const chunkBuffer = await fs.readFile(chunkFile);
        const formData = new FormData();
        
        formData.append('file', chunkBuffer, {
          filename: `chunk_${index}.ogg`,
          contentType: 'audio/ogg'
        });
        formData.append('model', 'whisper-1');
        formData.append('response_format', 'verbose_json');
        formData.append('timestamp_granularities[]', 'word');
        
        console.log(`🎙️ Transcribiendo chunk ${index + 1}/${numChunks}...`);
        
        const response = await axios.post(
          'https://api.openai.com/v1/audio/transcriptions',
          formData,
          {
            headers: {
              'Authorization': `Bearer ${apiKey}`,
              ...formData.getHeaders()
            },
            maxBodyLength: Infinity,
            maxContentLength: Infinity,
            timeout: 300000 // 5 minutos por chunk
          }
        );
        
        // Validate OpenAI response
        if (!response.data) {
          throw new Error(`OpenAI retornó respuesta vacía para chunk ${index + 1}`);
        }
        
        const result = response.data;
        
        // Validate response structure
        if (!result.text && (!result.words || result.words.length === 0)) {
          console.warn(`⚠️ Chunk ${index + 1} sin contenido de audio, continuando...`);
          return { index, result: { text: '', words: [] } };
        }
        
        // Adjust timestamps based on chunk position
        const chunkStartTime = index * chunkDurationSeconds;
        
        if (result.words) {
          result.words = result.words.map(word => ({
            ...word,
            start: word.start + chunkStartTime,
            end: word.end + chunkStartTime
          }));
        }
        
        console.log(`✅ Chunk ${index + 1}/${numChunks} transcrito`);
        return { index, result };
        
      } catch (error) {
        console.error(`❌ Error en chunk ${index + 1}:`, error.message);
        throw error;
      }
    });
    
    // Wait for all transcriptions with error handling
    let transcriptionResults;
    try {
      transcriptionResults = await Promise.all(transcriptionPromises);
    } catch (transcriptionError) {
      // Clean up chunks
      for (const chunkFile of chunkFiles) {
        try {
          if (existsSync(chunkFile)) await fs.unlink(chunkFile);
        } catch (e) {}
      }
      throw new Error(`Error en transcripción de chunks: ${transcriptionError.message}`);
    }
    
    console.log('🔄 Uniendo chunks...');
    
    // Validate transcription results
    if (!transcriptionResults || transcriptionResults.length !== chunkFiles.length) {
      throw new Error(`Número incorrecto de resultados de transcripción: esperado ${chunkFiles.length}, obtenido ${transcriptionResults?.length || 0}`);
    }
    
    // Sort results by index and merge
    transcriptionResults.sort((a, b) => a.index - b.index);
    
    let mergedWords = [];
    let mergedText = '';
    
    for (const { result } of transcriptionResults) {
      if (result && result.words && Array.isArray(result.words)) {
        mergedWords = mergedWords.concat(result.words);
      }
      if (result && result.text && typeof result.text === 'string') {
        mergedText += (mergedText ? ' ' : '') + result.text;
      }
    }
    
    // Validate merged results
    if (mergedWords.length === 0 && !mergedText) {
      throw new Error('No se pudo extraer contenido de ningún chunk. El audio puede estar corrupto o vacío.');
    }
    
    console.log(`📝 Transcript unificado completado (${mergedWords.length} palabras)`);
    
    // Clean up chunk files
    for (const chunkFile of chunkFiles) {
      try {
        await fs.unlink(chunkFile);
      } catch (e) {}
    }
    
    // Process with Gemini (same as regular flow)
    const words = mergedWords.map(word => ({
      text: word.word.trim(),
      start: word.start,
      end: word.end,
      speaker: null
    }));
    
    console.log('📝 Enviando transcript unificado a Gemini para análisis...');
    
    let finalWords = words;
    let speakerInfo = {};
    
    if (geminiApiKey && geminiPrompt && mergedText) {
      try {
        const { GoogleGenerativeAI } = require('@google/generative-ai');
        const genAI = new GoogleGenerativeAI(geminiApiKey);
        const model = genAI.getGenerativeModel({ model: 'gemini-2.5-pro' });
        
        console.log(`🤖 Procesando transcript con Gemini (${words.length} palabras)...`);
        
        // ESTRATEGIA PDF: Generar PDF del transcript completo para Gemini
        try {
          console.log('🎯 Analizando transcript para identificar speakers...');
          
          // Paso 1: Intentar estrategia PDF primero
          const pdfSuccess = await tryPDFSpeakerAnalysis(model, words, finalWords);
          
          if (pdfSuccess) {
            console.log('✅ PDF strategy completada exitosamente');
          } else {
            console.log('⚠️ PDF strategy falló, usando análisis distribuido como fallback...');
            
            // Fallback: Análisis distribuido
            // Paso 1: Identificar nombres de speakers con muestra inicial
            const initialSample = words.slice(0, 2000).map(w => w.text).join(' ');
          
          const namePrompt = `You are an expert at identifying speakers in interview transcripts.

TRANSCRIPT START:
${initialSample}

TASK: Carefully identify all speakers mentioned or implied in this conversation.

Look for:
- Direct introductions ("I'm John Smith", "Welcome to the show, I'm...")
- Third person references ("as Dr. Peterson mentioned", "thank you Jordan")
- Show/podcast names that might indicate the host
- Any other speaker identification clues

Return ONLY valid JSON (no extra text):
{
  "interviewer_name": "John Smith",
  "guest_name": "Jane Doe", 
  "show_name": "Example Podcast",
  "other_speakers": [],
  "context_clues": ["mentioned at minute 2", "introduced as Dr."]
}`;
          
          let speakerNames = { interviewer_name: null, guest_name: null };
          try {
            const nameResult = await processGeminiChunk(model, namePrompt, 1, 1);
            if (nameResult && typeof nameResult === 'object') {
              speakerNames = { ...speakerNames, ...nameResult };
            }
            console.log('✅ Nombres identificados:', speakerNames);
          } catch (e) {
            console.log('ℹ️ No se pudieron identificar nombres específicos:', e.message);
          }
          
          // Paso 2: Analizar múltiples secciones del transcript
          const SECTIONS = Math.min(8, Math.ceil(words.length / 2000)); // Más secciones para videos largos
          const sectionSize = Math.floor(words.length / SECTIONS);
          const segments = [];
          
          console.log(`📊 Analizando ${SECTIONS} secciones distribuidas del transcript...`);
          
          for (let section = 0; section < SECTIONS; section++) {
            const startIdx = section * sectionSize;
            const endIdx = Math.min(startIdx + 2000, words.length); // 2000 palabras por sección para más contexto
            
            if (startIdx >= words.length) break;
            
            const sectionText = words.slice(startIdx, endIdx).map(w => w.text).join(' ');
            
            const sectionPrompt = `You are an expert at speaker diarization. Analyze this conversation section carefully.

SECTION ${section + 1} of ${SECTIONS} (words ${startIdx}-${endIdx} of ${words.length} total):
${sectionText}

INSTRUCTIONS:
1. Identify ALL speaker changes in this section
2. Look for conversational cues: questions, acknowledgments, topic shifts, speaking style
3. Consider context: interviews typically have back-and-forth exchanges
4. Be as granular as needed - capture short interjections too
5. Use your best judgment for ambiguous cases

Known speakers so far:
- Interviewer: ${speakerNames.interviewer_name || "Unknown"}
- Guest: ${speakerNames.guest_name || "Unknown"}

IMPORTANT: Return ONLY valid JSON, no explanations or extra text:
{
  "segments": [
    {"start": ${startIdx}, "end": ${startIdx + 50}, "speaker": "interviewer"},
    {"start": ${startIdx + 51}, "end": ${startIdx + 300}, "speaker": "guest"},
    {"start": ${startIdx + 301}, "end": ${startIdx + 310}, "speaker": "interviewer"}
  ]
}`;
            
            try {
              const sectionAnalysis = await processGeminiChunk(model, sectionPrompt, section + 1, SECTIONS);
              if (sectionAnalysis && sectionAnalysis.segments) {
                segments.push(...sectionAnalysis.segments);
              }
            } catch (e) {
              console.log(`⚠️ Fallo análisis de sección ${section + 1}`);
            }
            
            // Rate limiting entre secciones
            if (section < SECTIONS - 1) {
              await new Promise(resolve => setTimeout(resolve, 500));
            }
          }
          
          // Paso 3: Aplicar los segmentos identificados
          console.log(`🔧 Aplicando ${segments.length} segmentos identificados...`);
          
          // Ordenar segmentos por posición
          segments.sort((a, b) => a.start - b.start);
          
          // Aplicar segmentos con interpolación
          let lastEnd = 0;
          let lastSpeaker = "Interviewer";
          
          for (const segment of segments) {
            const startIdx = Math.max(0, Math.min(segment.start, words.length - 1));
            const endIdx = Math.max(startIdx, Math.min(segment.end, words.length - 1));
            
            // Llenar gap entre segmentos
            if (lastEnd < startIdx) {
              for (let i = lastEnd; i < startIdx; i++) {
                if (finalWords[i]) {
                  finalWords[i].speaker = lastSpeaker;
                }
              }
            }
            
            // Aplicar speaker del segmento con validación
            const speakerType = segment.speaker || "guest";
            const speakerName = speakerType.toLowerCase().includes('interview') 
              ? (speakerNames.interviewer_name || "Interviewer")
              : (speakerNames.guest_name || "Guest");
              
            for (let i = startIdx; i <= endIdx; i++) {
              if (finalWords[i]) {
                finalWords[i].speaker = speakerName;
                lastSpeaker = speakerName;
              }
            }
            
            lastEnd = endIdx + 1;
          }
          
          // Llenar cualquier palabra restante
          for (let i = lastEnd; i < finalWords.length; i++) {
            if (finalWords[i]) {
              finalWords[i].speaker = lastSpeaker;
            }
          }
          
          console.log('✅ Identificación de speakers completada con análisis distribuido');
          
          // Verificar distribución
          const speakerStats = {};
          finalWords.forEach(word => {
            if (word.speaker) {
              speakerStats[word.speaker] = (speakerStats[word.speaker] || 0) + 1;
            }
          });
          console.log('📊 Distribución final de speakers:', speakerStats);
            }
          
        } catch (error) {
          console.error('❌ Error en procesamiento de Gemini:', error.message);
          console.log('ℹ️ Continuando sin análisis de speakers');
        }
        
        // Collect speaker info
        const uniqueSpeakers = [...new Set(finalWords.map(w => w.speaker).filter(Boolean))];
        console.log(`🎤 Speakers únicos encontrados: [${uniqueSpeakers.join(', ')}]`);
        
        uniqueSpeakers.forEach((speaker, index) => {
          speakerInfo[`speaker_${index}`] = speaker;
        });
        
        console.log('📤 SpeakerInfo final:', speakerInfo);
        
        // Verificar asignación de speakers
        const speakerStats = {};
        finalWords.forEach(word => {
          if (word.speaker) {
            speakerStats[word.speaker] = (speakerStats[word.speaker] || 0) + 1;
          }
        });
        console.log('📊 Estadísticas de palabras por speaker:', speakerStats);
        
        console.log('✅ Análisis de Gemini aplicado correctamente al transcript unificado');
        
      } catch (geminiError) {
        console.error('⚠️ Error en análisis de Gemini para chunks:', geminiError.message);
      }
    }
    
    return {
      words: finalWords,
      full_text: mergedText,
      speakers: speakerInfo
    };
    
  } catch (error) {
    console.error('❌ Error en transcripción por chunks:', error.message);
    
    // Clean up any remaining chunk files
    try {
      // Clean up with session ID pattern
      const files = await fs.readdir(tempDir);
      const chunkPattern = /^quotify_chunk_\d+_\d+\.ogg$/;
      
      for (const file of files) {
        if (chunkPattern.test(file)) {
          try {
            await fs.unlink(path.join(tempDir, file));
            console.log(`🧹 Limpiando chunk residual: ${file}`);
          } catch (e) {}
        }
      }
    } catch (e) {
      console.warn('⚠️ No se pudo limpiar archivos temporales:', e.message);
    }
    
    throw error;
  }
}

// IPC handlers
ipcMain.handle('scrape-metadata', async (event, url) => {
  try {
    console.log('Scraping metadata for:', url);
    
    // Validate URL format
    if (!url || typeof url !== 'string') {
      throw new Error('Invalid URL provided');
    }
    
    // Validate YouTube URL
    const youtubeRegex = /^(https?\:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+/;
    if (!youtubeRegex.test(url)) {
      throw new Error('Please provide a valid YouTube URL');
    }
    
    let rawInfo;
    let info;
    
    try {
      console.log('=== USING YTDL-CORE (NATIVE NODE.JS) ===');
      console.log('URL:', url);
      
      // Use ytdl-core for metadata (pure Node.js, no binaries)
      const basicInfo = await ytdlCore.getBasicInfo(url);
      console.log('Basic info keys:', Object.keys(basicInfo));
      console.log('Video details keys:', Object.keys(basicInfo.videoDetails || {}));
      
      rawInfo = basicInfo.videoDetails;
      
      console.log('Raw info sample:', {
        title: rawInfo?.title,
        author: rawInfo?.author?.name,
        videoId: rawInfo?.videoId,
        lengthSeconds: rawInfo?.lengthSeconds
      });
      
      console.log('Native extraction successful!');
      
      console.log('=== RAW RESPONSE ANALYSIS ===');
      console.log('Type:', typeof rawInfo);
      console.log('Is null/undefined:', rawInfo == null);
      console.log('Has expected fields:', !!(rawInfo?.title && rawInfo?.videoId));
      
      // ytdl-core returns videoDetails object directly
      if (rawInfo && typeof rawInfo === 'object' && (rawInfo.title || rawInfo.videoId)) {
        info = rawInfo;
        console.log('✅ ytdl-core data structure validated');
      } else {
        throw new Error('ytdl-core returned unexpected structure');
      }
      
    } catch (primaryError) {
      console.log('❌ ytdl-core failed, trying youtube-dl-exec fallback...');
      console.error('ytdl-core error:', primaryError.message);
      
      // Fallback: Try youtube-dl-exec
      try {
        rawInfo = await ytdl(url, {
          dumpSingleJson: true,
          skipDownload: true,
          quiet: true
        });
        
        console.log('Fallback attempt - Raw info type:', typeof rawInfo);
        
        if (typeof rawInfo === 'string') {
          info = JSON.parse(rawInfo);
        } else {
          info = rawInfo;
        }
        
        console.log('✅ youtube-dl-exec fallback successful');
        
      } catch (fallbackError) {
        console.error('❌ All extraction methods failed');
        console.error('ytdl-core error:', primaryError.message);
        console.error('youtube-dl-exec error:', fallbackError.message);
        throw new Error(`Metadata extraction failed. Primary (ytdl-core): ${primaryError.message}. Fallback (youtube-dl-exec): ${fallbackError.message}`);
      }
    }
    
    // Validate and normalize response
    if (!info || typeof info !== 'object') {
      console.error('Invalid info object:', info);
      console.error('Type:', typeof info);
      throw new Error('ytdl-core returned invalid data structure');
    }
    
    console.log('Available info keys:', Object.keys(info).slice(0, 15));
    
    // Check for essential fields with multiple fallbacks
    const hasTitle = info.title || info._title || info.fulltitle;
    const hasId = info.videoId || info.id || info.video_id || info.display_id;
    
    if (!hasTitle && !hasId) {
      console.error('Missing essential fields. Available keys:', Object.keys(info));
      console.error('Sample info object:', JSON.stringify(info, null, 2).substring(0, 1000));
      throw new Error('Video metadata incomplete - video may be private, unavailable, or restricted');
    }
    
    // Extract metadata with comprehensive fallbacks
    const metadata = {
      title: info.title || info._title || info.fulltitle || info.alt_title || 'Unknown Title',
      channel: info.author?.name || info.ownerChannelName || info.uploader || info.channel || info.uploader_id || info.creator || 'Unknown Channel',
      duration: parseInt(info.lengthSeconds) || parseInt(info.duration) || parseInt(info.duration_string) || 0,
      publish_date: info.publishDate || info.uploadDate || info.upload_date || info.release_date || info.timestamp || '',
      views: parseInt(info.viewCount) || parseInt(info.view_count) || parseInt(info.views) || 0,
      thumbnail: (info.thumbnails && info.thumbnails.length > 0 ? info.thumbnails[0].url : '') ||
                 info.thumbnail || 
                 (info.thumbnail_url) || '',
      url: info.video_url || info.webpage_url || info.original_url || info.url || url,
      id: info.videoId || info.id || info.video_id || info.display_id || ''
    };
    
    // Ensure we have at least a title
    if (!metadata.title || metadata.title === 'Unknown Title') {
      metadata.title = `Video ${metadata.id || 'from ' + url.substring(url.lastIndexOf('/') + 1)}`;
    }
    
    console.log('Extracted metadata:', metadata);
    return metadata;
    
  } catch (error) {
    console.error('Metadata scraping error:', {
      message: error.message,
      stack: error.stack,
      url: url
    });
    
    // Provide more specific error messages
    if (error.message.includes('Private video')) {
      throw new Error('This video is private and cannot be accessed');
    } else if (error.message.includes('Video unavailable')) {
      throw new Error('This video is unavailable or has been removed');
    } else if (error.message.includes('Sign in to confirm')) {
      throw new Error('This video requires sign-in verification');
    } else if (error.message.includes('network')) {
      throw new Error('Network error - please check your internet connection');
    } else {
      throw new Error(`Failed to scrape metadata: ${error.message}`);
    }
  }
});

ipcMain.handle('transcribe-audio', async (event, { url, apiKey, geminiApiKey, geminiPrompt }) => {
  let audioFile;
  
  try {
    console.log('=== TRANSCRIPCIÓN SIMPLIFICADA ===');
    console.log('URL:', url);
    
    const tempDir = require('os').tmpdir();
    const videoId = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/)?.[1];
    audioFile = path.join(tempDir, `quotify_${videoId || Date.now()}.ogg`);
    
    console.log('Archivo temporal:', audioFile);
    
    // Usar yt-dlp directamente (método más confiable)
    console.log('🎵 Descargando audio con yt-dlp...');
    
    // Configurar PATH para yt-dlp
    const originalPath = process.env.PATH;
    process.env.PATH = `/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:${originalPath}`;
    
    // Descargar y comprimir en un solo paso con yt-dlp
    console.log('🎵 Descargando y optimizando audio...');
    
    await ytdl(url, {
      extractAudio: true,
      audioFormat: 'opus', // Opus directamente
      output: audioFile,
      noPlaylist: true,
      // Seleccionar audio de calidad media-baja (balance velocidad/calidad)
      format: 'bestaudio[abr<=96]/bestaudio[abr<=128]/bestaudio',
      postprocessorArgs: [
        '-c:a', 'libopus', // Códec Opus
        '-b:a', '16k', // 16 kbps - máxima compresión para videos largos
        '-ac', '1', // Mono
        '-ar', '16000', // 16 kHz sample rate
        '-vbr', 'on', // Variable bitrate para mejor calidad
        '-compression_level', '10', // Máxima compresión
        '-frame_duration', '60', // Frame largo para voz
        '-application', 'voip', // Optimizado para voz
        '-threads', '0' // Usar todos los cores disponibles
      ],
      // Opciones adicionales para velocidad
      externalDownloader: 'native', // Downloader nativo más rápido
      preferFreeFormats: false,
      noCheckCertificate: true,
      keepVideo: false
    });
    
    console.log('✅ Audio descargado correctamente');
    
    // Verificar que el archivo existe
    if (!existsSync(audioFile)) {
      throw new Error('Archivo de audio no fue creado');
    }
    
    const stats = await fs.stat(audioFile);
    const fileSizeMB = stats.size / 1024 / 1024;
    console.log(`📁 Tamaño del archivo: ${fileSizeMB.toFixed(2)}MB`);
    
    // Si es muy grande, dividir en chunks
    if (fileSizeMB > 25) {
      console.log(`📁 Archivo grande (${fileSizeMB.toFixed(2)}MB), dividiendo en chunks...`);
      return await transcribeInChunks(audioFile, apiKey, geminiApiKey, geminiPrompt);
    }
    
    // Estimar duración del video basado en el tamaño
    const estimatedDurationMinutes = Math.round((fileSizeMB / 16) * 60 * 2); // 16kbps
    console.log(`⏱️ Duración estimada: ~${estimatedDurationMinutes} minutos`);
    
    // Leer archivo para OpenAI
    console.log('📤 Enviando a OpenAI Whisper...');
    console.log('⏳ Esto puede tomar varios minutos para videos largos...');
    const audioBuffer = await fs.readFile(audioFile);
    
    // Transcribir con OpenAI usando form-data
    const FormData = require('form-data');
    const axios = require('axios');
    
    const formData = new FormData();
    formData.append('file', audioBuffer, {
      filename: 'audio.ogg',
      contentType: 'audio/ogg'
    });
    formData.append('model', 'whisper-1');
    formData.append('response_format', 'verbose_json');
    formData.append('timestamp_granularities[]', 'word');
    
    const response = await axios.post(
      'https://api.openai.com/v1/audio/transcriptions',
      formData,
      {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          ...formData.getHeaders()
        },
        maxBodyLength: Infinity,
        maxContentLength: Infinity,
        timeout: 600000, // 10 minutos para videos largos
        // Optimizaciones para velocidad
        decompress: true,
        responseType: 'json'
      }
    );
    
    console.log('✅ Transcripción completada');
    
    // Limpiar archivo temporal
    try {
      await fs.unlink(audioFile);
      console.log('🧹 Archivo temporal eliminado');
    } catch (e) {
      console.log('⚠️ No se pudo eliminar archivo temporal');
    }
    
    // Procesar respuesta
    const result = response.data;
    const words = result.words?.map(word => ({
      text: word.word.trim(),
      start: word.start,
      end: word.end,
      speaker: null // Will be assigned by Gemini
    })) || [];
    
    console.log('📝 Transcript básico completado, enviando a Gemini para análisis...');
    
    // Procesar con Gemini para speaker identification y correcciones
    let finalWords = words;
    let speakerInfo = {};
    
    if (geminiApiKey && geminiPrompt && result.text) {
      try {
        const { GoogleGenerativeAI } = require('@google/generative-ai');
        const genAI = new GoogleGenerativeAI(geminiApiKey);
        const model = genAI.getGenerativeModel({ model: 'gemini-2.5-pro' });
        
        console.log(`🤖 Procesando transcript con Gemini (${words.length} palabras)...`);
        
        // ESTRATEGIA PDF: Generar PDF del transcript completo para Gemini
        try {
          console.log('🎯 Analizando transcript para identificar speakers...');
          
          // Paso 1: Intentar estrategia PDF primero
          const pdfSuccess = await tryPDFSpeakerAnalysis(model, words, finalWords);
          
          if (pdfSuccess) {
            console.log('✅ PDF strategy completada exitosamente');
          } else {
            console.log('⚠️ PDF strategy falló, usando análisis distribuido como fallback...');
            
            // Fallback: Análisis distribuido
            // Paso 1: Identificar nombres de speakers con muestra inicial
            const initialSample = words.slice(0, 2000).map(w => w.text).join(' ');
          
          const namePrompt = `You are an expert at identifying speakers in interview transcripts.

TRANSCRIPT START:
${initialSample}

TASK: Carefully identify all speakers mentioned or implied in this conversation.

Look for:
- Direct introductions ("I'm John Smith", "Welcome to the show, I'm...")
- Third person references ("as Dr. Peterson mentioned", "thank you Jordan")
- Show/podcast names that might indicate the host
- Any other speaker identification clues

Return ONLY valid JSON (no extra text):
{
  "interviewer_name": "John Smith",
  "guest_name": "Jane Doe", 
  "show_name": "Example Podcast",
  "other_speakers": [],
  "context_clues": ["mentioned at minute 2", "introduced as Dr."]
}`;
          
          let speakerNames = { interviewer_name: null, guest_name: null };
          try {
            const nameResult = await processGeminiChunk(model, namePrompt, 1, 1);
            if (nameResult && typeof nameResult === 'object') {
              speakerNames = { ...speakerNames, ...nameResult };
            }
            console.log('✅ Nombres identificados:', speakerNames);
          } catch (e) {
            console.log('ℹ️ No se pudieron identificar nombres específicos:', e.message);
          }
          
          // Paso 2: Analizar múltiples secciones del transcript
          const SECTIONS = Math.min(8, Math.ceil(words.length / 2000)); // Más secciones para videos largos
          const sectionSize = Math.floor(words.length / SECTIONS);
          const segments = [];
          
          console.log(`📊 Analizando ${SECTIONS} secciones distribuidas del transcript...`);
          
          for (let section = 0; section < SECTIONS; section++) {
            const startIdx = section * sectionSize;
            const endIdx = Math.min(startIdx + 2000, words.length); // 2000 palabras por sección para más contexto
            
            if (startIdx >= words.length) break;
            
            const sectionText = words.slice(startIdx, endIdx).map(w => w.text).join(' ');
            
            const sectionPrompt = `You are an expert at speaker diarization. Analyze this conversation section carefully.

SECTION ${section + 1} of ${SECTIONS} (words ${startIdx}-${endIdx} of ${words.length} total):
${sectionText}

INSTRUCTIONS:
1. Identify ALL speaker changes in this section
2. Look for conversational cues: questions, acknowledgments, topic shifts, speaking style
3. Consider context: interviews typically have back-and-forth exchanges
4. Be as granular as needed - capture short interjections too
5. Use your best judgment for ambiguous cases

Known speakers so far:
- Interviewer: ${speakerNames.interviewer_name || "Unknown"}
- Guest: ${speakerNames.guest_name || "Unknown"}

IMPORTANT: Return ONLY valid JSON, no explanations or extra text:
{
  "segments": [
    {"start": ${startIdx}, "end": ${startIdx + 50}, "speaker": "interviewer"},
    {"start": ${startIdx + 51}, "end": ${startIdx + 300}, "speaker": "guest"},
    {"start": ${startIdx + 301}, "end": ${startIdx + 310}, "speaker": "interviewer"}
  ]
}`;
            
            try {
              const sectionAnalysis = await processGeminiChunk(model, sectionPrompt, section + 1, SECTIONS);
              if (sectionAnalysis && sectionAnalysis.segments) {
                segments.push(...sectionAnalysis.segments);
              }
            } catch (e) {
              console.log(`⚠️ Fallo análisis de sección ${section + 1}`);
            }
            
            // Rate limiting entre secciones
            if (section < SECTIONS - 1) {
              await new Promise(resolve => setTimeout(resolve, 500));
            }
          }
          
          // Paso 3: Aplicar los segmentos identificados
          console.log(`🔧 Aplicando ${segments.length} segmentos identificados...`);
          
          // Ordenar segmentos por posición
          segments.sort((a, b) => a.start - b.start);
          
          // Aplicar segmentos con interpolación
          let lastEnd = 0;
          let lastSpeaker = "Interviewer";
          
          for (const segment of segments) {
            const startIdx = Math.max(0, Math.min(segment.start, words.length - 1));
            const endIdx = Math.max(startIdx, Math.min(segment.end, words.length - 1));
            
            // Llenar gap entre segmentos
            if (lastEnd < startIdx) {
              for (let i = lastEnd; i < startIdx; i++) {
                if (finalWords[i]) {
                  finalWords[i].speaker = lastSpeaker;
                }
              }
            }
            
            // Aplicar speaker del segmento con validación
            const speakerType = segment.speaker || "guest";
            const speakerName = speakerType.toLowerCase().includes('interview') 
              ? (speakerNames.interviewer_name || "Interviewer")
              : (speakerNames.guest_name || "Guest");
              
            for (let i = startIdx; i <= endIdx; i++) {
              if (finalWords[i]) {
                finalWords[i].speaker = speakerName;
                lastSpeaker = speakerName;
              }
            }
            
            lastEnd = endIdx + 1;
          }
          
          // Llenar cualquier palabra restante
          for (let i = lastEnd; i < finalWords.length; i++) {
            if (finalWords[i]) {
              finalWords[i].speaker = lastSpeaker;
            }
          }
          
          console.log('✅ Identificación de speakers completada con análisis distribuido');
          
          // Verificar distribución
          const speakerStats = {};
          finalWords.forEach(word => {
            if (word.speaker) {
              speakerStats[word.speaker] = (speakerStats[word.speaker] || 0) + 1;
            }
          });
          console.log('📊 Distribución final de speakers:', speakerStats);
            }
          
        } catch (error) {
          console.error('❌ Error en procesamiento de Gemini:', error.message);
          console.log('ℹ️ Continuando sin análisis de speakers');
        }
        
        // Collect speaker info
        const uniqueSpeakers = [...new Set(finalWords.map(w => w.speaker).filter(Boolean))];
        console.log(`🎤 Speakers únicos encontrados: [${uniqueSpeakers.join(', ')}]`);
        
        uniqueSpeakers.forEach((speaker, index) => {
          speakerInfo[`speaker_${index}`] = speaker;
        });
        
        console.log('📤 SpeakerInfo final:', speakerInfo);
        
      } catch (geminiError) {
        console.error('⚠️ Error en análisis de Gemini, usando transcript original:', geminiError.message);
      }
    } else {
      console.log('ℹ️ Gemini no configurado, usando transcript básico');
    }
    
    return {
      words: finalWords,
      full_text: result.text,
      speakers: speakerInfo
    };
    
  } catch (error) {
    console.error('❌ Error en transcripción:', error.message);
    
    // Limpiar archivo temporal en caso de error
    if (audioFile && existsSync(audioFile)) {
      try {
        await fs.unlink(audioFile);
      } catch (e) {}
    }
    
    // Mensajes de error más claros
    if (error.message.includes('demasiado grande')) {
      throw new Error(`El archivo de audio es demasiado grande (${fileSizeMB?.toFixed(2) || 'unknown'}MB). Intenta con un video más corto.`);
    } else if (error.message.includes('yt-dlp')) {
      throw new Error('Error descargando audio. Verifica que yt-dlp esté instalado.');
    } else if (error.message.includes('OpenAI') || error.message.includes('401')) {
      throw new Error('Error con API key de OpenAI. Verifica que sea correcta.');
    } else if (error.message.includes('timeout')) {
      throw new Error('Transcripción tomó demasiado tiempo. Intenta con un video más corto.');
    } else {
      throw new Error(`Transcripción falló: ${error.message}`);
    }
  }
});

ipcMain.handle('generate-deep-link', async (event, { url, timestamp }) => {
  const videoIdMatch = url.match(/(?:v=|youtu\.be\/)([^&\s]+)/);
  const videoId = videoIdMatch ? videoIdMatch[1] : '';
  return `https://youtu.be/${videoId}?t=${Math.floor(timestamp)}`;
});

ipcMain.handle('open-external', async (event, url) => {
  shell.openExternal(url);
});

// API Key storage handlers
const getConfigPath = () => {
  const userDataPath = app.getPath('userData');
  return path.join(userDataPath, 'config.json');
};

ipcMain.handle('save-api-key', async (event, apiKey) => {
  try {
    const configPath = getConfigPath();
    const config = { openai_api_key: apiKey };
    await fs.writeFile(configPath, JSON.stringify(config, null, 2));
    return true;
  } catch (error) {
    console.error('Failed to save API key:', error);
    return false;
  }
});

ipcMain.handle('load-api-key', async () => {
  try {
    const configPath = getConfigPath();
    if (existsSync(configPath)) {
      const configData = await fs.readFile(configPath, 'utf8');
      const config = JSON.parse(configData);
      return config.openai_api_key || '';
    }
    return '';
  } catch (error) {
    console.error('Failed to load API key:', error);
    return '';
  }
});

// Gemini API configuration handlers
ipcMain.handle('save-gemini-config', async (event, { apiKey, prompt }) => {
  try {
    const configPath = getConfigPath();
    let config = {};
    
    // Load existing config
    if (existsSync(configPath)) {
      const configData = await fs.readFile(configPath, 'utf8');
      config = JSON.parse(configData);
    }
    
    // Update with Gemini config
    config.gemini_api_key = apiKey;
    config.gemini_prompt = prompt;
    
    await fs.writeFile(configPath, JSON.stringify(config, null, 2));
    return true;
  } catch (error) {
    console.error('Failed to save Gemini config:', error);
    return false;
  }
});

ipcMain.handle('load-gemini-config', async () => {
  try {
    const configPath = getConfigPath();
    if (existsSync(configPath)) {
      const configData = await fs.readFile(configPath, 'utf8');
      const config = JSON.parse(configData);
      
      const defaultPrompt = `You are an expert conversation analyst. Analyze this transcript and identify speakers using advanced contextual understanding.

YOUR TASK:
1. Detect the EXACT number of unique speakers in this conversation
2. Identify speaker changes by analyzing:
   - Conversational flow and turn-taking patterns
   - Questions vs answers (interviewers ask, interviewees respond)
   - Topic transitions and speaking styles
   - First-person vs second-person references
   - Names mentioned in context ("I'm Alex", "Thanks Rajiv")
   - Conversational cues ("So tell us", "Well", "You know")

3. Use real names when clearly mentioned, otherwise use descriptive labels like "Interviewer", "Guest", "Host"

CRITICAL RULES:
- Preserve original timestamps - you're only identifying speakers, not modifying timing
- Fix grammatical errors and add proper punctuation (periods, commas, question marks)
- Remove filler words like "umm", "uhh", "uh", "um", "hmm", "ah", "eh" completely
- Fix obvious transcription errors (misspelled company names, technical terms)
- Analyze the ENTIRE conversation context before assigning speakers
- If unsure between speakers, choose the most contextually appropriate one
- Pay attention to conversational patterns: who asks questions vs who answers

CORRECTIONS TO MAKE:
- Remove filler words: "um", "umm", "uh", "uhh", "ah", "eh", "hmm", "like" (when used as filler)
- Add proper punctuation: periods at sentence ends, commas for pauses, question marks for questions
- Fix grammar: verb tenses, subject-verb agreement, proper capitalization
- Correct technical terms and company names
- Clean up false starts and repetitions ("I I think" → "I think")

CONTEXT ANALYSIS HINTS:
- Interviewers often say: "tell us", "how do you", "can you explain", "what's your"
- Guests often say: "well", "so", "I think", "my experience", "when I was"
- Names are often introduced: "I'm [Name]", "Thanks [Name]", "[Name] at [Company]"
- Speaking style consistency within each speaker

OUTPUT FORMAT - Return ONLY this JSON structure:
{
  "speakers_detected": number,
  "segments": [
    {
      "start_word_index": number,
      "end_word_index": number, 
      "speaker_id": "Speaker name or identifier",
      "corrected_words": [
        {"index": number, "corrected_text": "corrected_word"}
      ]
    }
  ]
}

Word indices refer to the numbered position [0], [1], [2]... in the transcript.`;
      
      return {
        apiKey: config.gemini_api_key || '',
        prompt: config.gemini_prompt || defaultPrompt
      };
    }
    return { apiKey: '', prompt: '' };
  } catch (error) {
    console.error('Failed to load Gemini config:', error);
    return { apiKey: '', prompt: '' };
  }
});

// PDF Generation for complete transcript analysis (TEXT-BASED)
async function generateTranscriptPDF(words) {
  const PDFDocument = require('pdfkit');
  const tempDir = require('os').tmpdir();
  const pdfPath = path.join(tempDir, `transcript_${Date.now()}.pdf`);
  
  console.log('📄 Generando PDF con transcript completo (texto continuo)...');
  
  const doc = new PDFDocument();
  const stream = createWriteStream(pdfPath);
  doc.pipe(stream);
  
  // Título
  doc.fontSize(16).text('INTERVIEW TRANSCRIPT FOR SPEAKER ANALYSIS', { align: 'center' });
  doc.moveDown();
  
  // Información del documento
  doc.fontSize(10).text(`Total words: ${words.length}`, { align: 'left' });
  doc.text(`Generated: ${new Date().toISOString()}`, { align: 'left' });
  doc.moveDown();
  
  // Transcript con índices para referencia precisa
  doc.fontSize(11);
  
  // Crear texto con referencias de índices cada pocas palabras
  let textWithIndices = '';
  for (let i = 0; i < words.length; i++) {
    // Añadir referencia de índice cada 50 palabras
    if (i % 50 === 0) {
      textWithIndices += `[WORD_${i}] `;
    }
    textWithIndices += words[i].text + ' ';
  }
  
  // Dividir en párrafos cada 1000 caracteres para mejor lectura
  const paragraphs = [];
  let currentParagraph = '';
  
  const sentences = textWithIndices.split(/([.!?]+\s+)/);
  
  for (const sentence of sentences) {
    if (currentParagraph.length + sentence.length > 1000) {
      if (currentParagraph.trim()) {
        paragraphs.push(currentParagraph.trim());
      }
      currentParagraph = sentence;
    } else {
      currentParagraph += sentence;
    }
  }
  
  if (currentParagraph.trim()) {
    paragraphs.push(currentParagraph.trim());
  }
  
  // Escribir párrafos
  for (let i = 0; i < paragraphs.length; i++) {
    doc.text(paragraphs[i], { align: 'justify' });
    doc.moveDown();
    
    // Nueva página cada 15 párrafos (reducido porque ahora hay más texto)
    if (i > 0 && i % 15 === 0 && i < paragraphs.length - 1) {
      doc.addPage();
    }
  }
  
  doc.end();
  
  return new Promise((resolve, reject) => {
    stream.on('finish', () => {
      console.log('✅ PDF generado correctamente');
      resolve(pdfPath);
    });
    stream.on('error', reject);
  });
}

// Process Gemini with PDF file
async function processGeminiWithPDF(model, prompt, pdfPath) {
  const maxRetries = 3;
  let lastError;
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`🔄 Enviando PDF a Gemini - Intento ${attempt}/${maxRetries}...`);
      
      // Timeout wrapper - más tiempo para PDFs
      const timeoutPromise = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Timeout de Gemini con PDF (10 minutos)')), 600000)
      );
      
      // Leer archivo PDF
      const pdfBuffer = await fs.readFile(pdfPath);
      
      // Enviar PDF a Gemini
      const geminiPromise = model.generateContent([
        prompt,
        {
          inlineData: {
            mimeType: 'application/pdf',
            data: pdfBuffer.toString('base64')
          }
        }
      ]);
      
      const geminiResult = await Promise.race([geminiPromise, timeoutPromise]);
      const geminiText = geminiResult.response.text();
      
      if (!geminiText || geminiText.trim().length === 0) {
        throw new Error('Respuesta vacía de Gemini para PDF');
      }
      
      console.log('📝 Respuesta de Gemini PDF (primeros 300 chars):', geminiText.substring(0, 300));
      
      // Parse JSON response
      let cleanedResponse = geminiText.trim();
      cleanedResponse = cleanedResponse.replace(/```json\s*/gi, '');
      cleanedResponse = cleanedResponse.replace(/```\s*/g, '');
      
      let analysis;
      try {
        analysis = JSON.parse(cleanedResponse);
      } catch (parseError) {
        console.log('⚠️ Error parseando JSON del PDF, intentando extraer...');
        const jsonMatch = cleanedResponse.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          analysis = JSON.parse(jsonMatch[0]);
          console.log('✅ JSON extraído exitosamente del PDF');
        } else {
          throw new Error('No se pudo extraer JSON válido del PDF');
        }
      }
      
      if (!analysis || typeof analysis !== 'object') {
        throw new Error('Estructura de análisis PDF inválida');
      }
      
      console.log(`✅ PDF procesado exitosamente por Gemini`);
      return analysis;
      
    } catch (error) {
      lastError = error;
      console.warn(`⚠️ PDF intento ${attempt} falló:`, error.message);
      
      if (error.message.includes('API key') ||
          error.message.includes('401') ||
          error.message.includes('403')) {
        break;
      }
      
      if (attempt < maxRetries) {
        const waitTime = Math.pow(2, attempt) * 2000; // 4s, 8s
        console.log(`⏳ Esperando ${waitTime/1000}s antes del siguiente intento...`);
        await new Promise(resolve => setTimeout(resolve, waitTime));
      }
    }
  }
  
  console.error(`❌ PDF falló después de todos los intentos:`, lastError.message);
  throw lastError;
}

// Map text segments to word indices - improved tolerance
function mapTextToWordIndices(words, textSegment, startSearchIndex = 0) {
  const cleanText = textSegment.toLowerCase().replace(/[^\w\s]/g, ' ').replace(/\s+/g, ' ').trim();
  const searchWords = cleanText.split(' ').filter(w => w.length > 2); // Ignore very short words
  
  if (searchWords.length === 0) return null;
  
  // Try exact match first
  for (let i = startSearchIndex; i < words.length - searchWords.length + 1; i++) {
    let exactMatch = true;
    
    for (let j = 0; j < searchWords.length; j++) {
      const wordText = words[i + j].text.toLowerCase().replace(/[^\w]/g, '');
      const searchWord = searchWords[j];
      
      if (wordText !== searchWord) {
        exactMatch = false;
        break;
      }
    }
    
    if (exactMatch) {
      return {
        startIndex: i,
        endIndex: i + searchWords.length - 1,
        matchedText: words.slice(i, i + searchWords.length).map(w => w.text).join(' ')
      };
    }
  }
  
  // Try fuzzy match - allow missing words
  for (let i = startSearchIndex; i < words.length; i++) {
    let matchedWords = 0;
    let lastMatchIndex = i - 1;
    
    for (let j = 0; j < searchWords.length; j++) {
      const searchWord = searchWords[j];
      
      // Look for this word in the next 10 positions
      for (let k = lastMatchIndex + 1; k < Math.min(lastMatchIndex + 11, words.length); k++) {
        const wordText = words[k].text.toLowerCase().replace(/[^\w]/g, '');
        
        if (wordText === searchWord) {
          matchedWords++;
          lastMatchIndex = k;
          break;
        }
      }
    }
    
    // If we matched most of the words, consider it a match
    if (matchedWords >= Math.ceil(searchWords.length * 0.7)) {
      return {
        startIndex: i,
        endIndex: Math.min(lastMatchIndex + 5, words.length - 1),
        matchedText: words.slice(i, lastMatchIndex + 1).map(w => w.text).join(' ')
      };
    }
  }
  
  return null;
}

// Apply range-based PDF speaker analysis
async function applyRangePDFAnalysis(words, pdfAnalysis, finalWords) {
  console.log(`🔍 Aplicando ${pdfAnalysis.word_ranges?.length || 0} rangos de speakers...`);
  
  if (!pdfAnalysis.word_ranges || !Array.isArray(pdfAnalysis.word_ranges)) {
    console.warn('⚠️ No se encontraron rangos de palabras válidos en el análisis PDF');
    return;
  }
  
  // Crear mapa de nombres de speakers dinámico
  const speakerNames = {};
  if (pdfAnalysis.speakers) {
    Object.keys(pdfAnalysis.speakers).forEach(key => {
      speakerNames[key] = pdfAnalysis.speakers[key];
    });
  }
  
  console.log(`🎤 Detected ${pdfAnalysis.total_speakers || 'unknown'} speakers:`, speakerNames);
  
  let successfulRanges = 0;
  let totalWordsAssigned = 0;
  
  // Ordenar rangos por posición
  pdfAnalysis.word_ranges.sort((a, b) => a.start_word - b.start_word);
  
  // Aplicar cada rango
  for (const range of pdfAnalysis.word_ranges) {
    const startWord = Math.max(0, range.start_word);
    const endWord = Math.min(range.end_word, words.length - 1);
    const speakerType = range.speaker;
    
    if (startWord <= endWord && startWord < words.length) {
      // Convertir tipo a nombre
      const speakerName = speakerNames[speakerType] || speakerType || 'Unknown Speaker';
      
      // Asignar speaker a todo el rango
      for (let i = startWord; i <= endWord; i++) {
        if (finalWords[i]) {
          finalWords[i].speaker = speakerName;
          totalWordsAssigned++;
        }
      }
      
      console.log(`✅ Assigned "${speakerName}" to words ${startWord}-${endWord} (${endWord - startWord + 1} words)`);
      successfulRanges++;
    } else {
      console.warn(`⚠️ Invalid range: ${startWord}-${endWord} (total words: ${words.length})`);
    }
  }
  
  console.log(`✅ Successfully applied ${successfulRanges}/${pdfAnalysis.word_ranges.length} ranges`);
  
  // Llenar palabras sin asignar con interpolación
  const firstSpeaker = Object.values(speakerNames)[0] || 'Speaker 1';
  let lastSpeaker = firstSpeaker;
  
  for (let i = 0; i < finalWords.length; i++) {
    if (!finalWords[i].speaker) {
      finalWords[i].speaker = lastSpeaker;
    } else {
      lastSpeaker = finalWords[i].speaker;
    }
  }
  
  // Estadísticas finales
  const speakerStats = {};
  let assignedWords = 0;
  
  finalWords.forEach(word => {
    if (word.speaker) {
      speakerStats[word.speaker] = (speakerStats[word.speaker] || 0) + 1;
      assignedWords++;
    }
  });
  
  console.log(`📊 Coverage: ${assignedWords}/${words.length} words (${(assignedWords/words.length*100).toFixed(1)}%)`);
  console.log('📊 Distribution:', speakerStats);
  console.log(`📋 Speaker names: ${JSON.stringify(speakerNames)}`);
}

// PDF-based speaker analysis strategy
async function tryPDFSpeakerAnalysis(model, words, finalWords) {
  try {
    console.log('📄 Intentando análisis PDF completo...');
    
    // Crear PDF temporal con el transcript
    const pdfPath = await generateTranscriptPDF(words);
    
    // Prompt mejorado para detección precisa de speakers
    const pdfPrompt = `You are an expert at speaker identification in interview/podcast transcripts. Analyze this complete transcript carefully.

TASK: Identify ALL speakers and assign precise word ranges for each speaker change.

You'll see [WORD_X] markers every 50 words for precise positioning.

SPEAKER IDENTIFICATION RULES:
1. Detect HOW MANY speakers are in this conversation (usually 2-4 in podcasts/interviews)
2. If names are mentioned, use real names. If not, use "Speaker 1", "Speaker 2", etc.
3. Look for conversation patterns:
   - Host asking questions vs guest answering
   - Different speaking styles and topics
   - Introductions, greetings, transitions
   - Short interjections like "Yeah", "Right", "Exactly", "Mm-hmm"
4. VERY IMPORTANT: Analyze long blocks carefully - they might contain multiple speakers
5. Pay attention to context clues and conversational flow

ACCURACY REQUIREMENTS:
- Cover EVERY word from 0 to ${words.length - 1}
- Use [WORD_X] markers for precise positioning
- Include ALL speaker changes, even 1-word interjections
- Fix only obvious mispronunciations of company names, proper nouns
- Preserve ALL original words and meaning
- Maintain exact same order and content

Return this JSON format:
{
  "total_speakers": 2,
  "speakers": {
    "speaker1": "Actual Name or Speaker 1",
    "speaker2": "Actual Name or Speaker 2"
  },
  "word_ranges": [
    {"start_word": 0, "end_word": 75, "speaker": "speaker1"},
    {"start_word": 76, "end_word": 350, "speaker": "speaker2"},
    {"start_word": 351, "end_word": 355, "speaker": "speaker1"}
  ]
}

Be extremely careful with speaker transitions and short responses. This is a professional transcript analysis.`;
    
    // Enviar PDF a Gemini
    const pdfAnalysis = await processGeminiWithPDF(model, pdfPrompt, pdfPath);
    
    if (pdfAnalysis && pdfAnalysis.word_ranges) {
      console.log(`✅ Análisis PDF exitoso: ${pdfAnalysis.word_ranges.length} rangos de palabras`);
      
      // Aplicar análisis PDF por rangos
      await applyRangePDFAnalysis(words, pdfAnalysis, finalWords);
      
      // Limpiar PDF temporal
      try {
        await fs.unlink(pdfPath);
      } catch (e) {}
      
      console.log('✅ Estrategia PDF completada exitosamente');
      return true;
    }
    
    // Limpiar PDF temporal
    try {
      await fs.unlink(pdfPath);
    } catch (e) {}
    
    return false;
    
  } catch (pdfError) {
    console.log('⚠️ Estrategia PDF falló:', pdfError.message);
    return false;
  }
}

// Fallback analysis function
async function fallbackAnalysis(model, words, finalWords) {
  console.log('🔄 Ejecutando análisis fallback simplificado...');
  
  // Análisis básico solo con muestra inicial
  const sample = words.slice(0, 3000).map(w => w.text).join(' ');
  
  const fallbackPrompt = `Analyze this interview transcript sample and provide basic speaker identification.

SAMPLE: ${sample}

Return simple JSON:
{
  "segments": [
    {"start_word": 0, "end_word": 1000, "speaker": "interviewer"},
    {"start_word": 1001, "end_word": 3000, "speaker": "guest"}
  ]
}`;

  try {
    const result = await processGeminiChunk(model, fallbackPrompt, 1, 1);
    
    if (result && result.segments) {
      // Aplicar resultado básico
      for (const segment of result.segments) {
        const startIdx = Math.max(0, segment.start_word || 0);
        const endIdx = Math.min(segment.end_word || words.length - 1, words.length - 1);
        
        for (let i = startIdx; i <= endIdx; i++) {
          if (finalWords[i]) {
            finalWords[i].speaker = segment.speaker || "Unknown";
          }
        }
      }
      
      console.log('✅ Análisis fallback aplicado');
    }
  } catch (e) {
    console.error('❌ Fallback también falló:', e.message);
  }
}

// ENTERPRISE-LEVEL: Helper functions for Gemini processing
async function processGeminiChunk(model, prompt, chunkNumber, totalChunks) {
  const maxRetries = 3;
  let lastError;
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`🔄 Chunk ${chunkNumber}/${totalChunks} - Intento ${attempt}/${maxRetries}...`);
      
      // Timeout wrapper for Gemini request - 5 minutos para chunks grandes
      const timeoutPromise = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Timeout de Gemini (5 minutos)')), 300000)
      );
      
      const geminiPromise = model.generateContent(prompt);
      
      const geminiResult = await Promise.race([geminiPromise, timeoutPromise]);
      const geminiText = geminiResult.response.text();
      
      if (!geminiText || geminiText.trim().length === 0) {
        throw new Error('Respuesta vacía de Gemini');
      }
      
      // Debug: mostrar parte de la respuesta
      console.log('📝 Respuesta de Gemini (primeros 200 chars):', geminiText.substring(0, 200));
      
      // Clean and parse JSON - más robusto
      let cleanedResponse = geminiText.trim();
      
      // Remover markdown code blocks
      cleanedResponse = cleanedResponse.replace(/```json\s*/gi, '');
      cleanedResponse = cleanedResponse.replace(/```\s*/g, '');
      
      // Buscar JSON en la respuesta
      let analysis;
      try {
        // Intentar parsear directamente
        analysis = JSON.parse(cleanedResponse);
      } catch (parseError) {
        console.log('⚠️ Error parseando JSON, intentando extraer...');
        
        // Buscar el JSON - corregir regex
        const jsonMatch = cleanedResponse.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          try {
            analysis = JSON.parse(jsonMatch[0]);
            console.log('✅ JSON extraído exitosamente');
          } catch (e) {
            console.log('❌ JSON malformado:', jsonMatch[0].substring(0, 200));
            throw new Error('JSON extraído pero malformado');
          }
        } else {
          console.log('❌ No se encontró JSON en la respuesta:', cleanedResponse.substring(0, 500));
          throw new Error('Respuesta no contiene JSON');
        }
      }
      
      if (!analysis || typeof analysis !== 'object') {
        throw new Error('Estructura de análisis inválida');
      }
      
      console.log(`✅ Chunk ${chunkNumber}/${totalChunks} procesado exitosamente`);
      return analysis;
      
    } catch (error) {
      lastError = error;
      console.warn(`⚠️ Chunk ${chunkNumber} intento ${attempt} falló:`, error.message);
      
      // Don't retry for non-recoverable errors
      if (error.message.includes('API key') ||
          error.message.includes('401') ||
          error.message.includes('403')) {
        break;
      }
      
      if (attempt < maxRetries) {
        const waitTime = Math.pow(2, attempt) * 1000;
        console.log(`⏳ Esperando ${waitTime/1000}s antes del siguiente intento...`);
        await new Promise(resolve => setTimeout(resolve, waitTime));
      }
    }
  }
  
  console.error(`❌ Chunk ${chunkNumber} falló después de todos los intentos:`, lastError.message);
  return null;
}

async function applyGeminiAnalysisToWords(words, analysis, baseIndex = 0) {
  if (!analysis.segments || !Array.isArray(analysis.segments)) {
    return;
  }
  
  console.log(`🎭 Aplicando ${analysis.segments.length} segmentos (base index: ${baseIndex})...`);
  
  for (const segment of analysis.segments) {
    // Soporte para ambos formatos de nombres de campos
    const startIndex = parseInt(segment.start_word_index || segment.start);
    const endIndex = parseInt(segment.end_word_index || segment.end);
    const speaker = segment.speaker_id || segment.speaker;
    
    if (!isNaN(startIndex) && !isNaN(endIndex) && startIndex >= 0 && endIndex < words.length) {
      // Assign speaker to words in range
      for (let i = startIndex; i <= endIndex && i < words.length; i++) {
        if (words[i] && speaker) {
          words[i].speaker = speaker;
        }
      }
      
      // Apply text corrections (solo si existen)
      if (segment.corrected_words && Array.isArray(segment.corrected_words)) {
        for (const correction of segment.corrected_words) {
          const correctionIndex = parseInt(correction.index);
          if (!isNaN(correctionIndex) && words[correctionIndex] && correction.corrected_text) {
            console.log(`🔧 Corrigiendo palabra ${correctionIndex}: "${words[correctionIndex].text}" -> "${correction.corrected_text}"`);
            words[correctionIndex].text = correction.corrected_text;
          }
        }
      }
    }
  }
}

// Data persistence handlers
const getDataPath = () => {
  const userDataPath = app.getPath('userData');
  return path.join(userDataPath, 'quotify-data.json');
};

ipcMain.handle('save-app-data', async (event, data) => {
  try {
    const dataPath = getDataPath();
    await fs.writeFile(dataPath, JSON.stringify(data, null, 2));
    return true;
  } catch (error) {
    console.error('Failed to save app data:', error);
    return false;
  }
});

ipcMain.handle('load-app-data', async () => {
  try {
    const dataPath = getDataPath();
    if (existsSync(dataPath)) {
      const data = await fs.readFile(dataPath, 'utf8');
      return JSON.parse(data);
    }
    return { sources: [], quotes: [], speakers: {} };
  } catch (error) {
    console.error('Failed to load app data:', error);
    return { sources: [], quotes: [], speakers: {} };
  }
});

// IPC handler for reprocessing transcript with Gemini
ipcMain.handle('reprocess-with-gemini', async (event, { words, fullText }) => {
  try {
    console.log('🔄 Reprocesando transcript con Gemini...');
    
    // Load Gemini configuration
    const configPath = getConfigPath();
    if (!existsSync(configPath)) {
      throw new Error('Configuración de Gemini no encontrada');
    }
    
    const configData = await fs.readFile(configPath, 'utf8');
    const config = JSON.parse(configData);
    
    const geminiApiKey = config.gemini_api_key;
    const geminiPrompt = config.gemini_prompt;
    
    if (!geminiApiKey || !geminiPrompt) {
      throw new Error('API key o prompt de Gemini no configurados');
    }
    
    const { GoogleGenerativeAI } = require('@google/generative-ai');
    const genAI = new GoogleGenerativeAI(geminiApiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-pro' });
    
    // Prepare text for Gemini analysis
    const textForAnalysis = words.map((word, index) => `[${index}] ${word.text}`).join(' ');
    
    const fullPrompt = `${geminiPrompt}\n\nTRANSCRIPT TO ANALYZE:\n${textForAnalysis}\n\nIMPORTANT: Return ONLY a valid JSON object with this exact structure:\n{\n  "speakers_detected": number,\n  "segments": [\n    {\n      "start_word_index": number,\n      "end_word_index": number, \n      "speaker_id": "Speaker 1" or actual name,\n      "corrected_words": [\n        {"index": number, "corrected_text": "word"}\n      ]\n    }\n  ]\n}`;
    
    console.log('🤖 Enviando a Gemini 2.5 Pro para reprocesamiento...');
    
    // Retry logic for Gemini
    const maxRetries = 3;
    let lastError;
    let analysis;
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        console.log(`🔄 Intento ${attempt}/${maxRetries} con Gemini...`);
        
        const geminiResult = await model.generateContent(fullPrompt);
        const geminiText = geminiResult.response.text();
        
        if (!geminiText || geminiText.trim().length === 0) {
          throw new Error('Respuesta vacía de Gemini');
        }
        
        const cleanedResponse = geminiText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
        analysis = JSON.parse(cleanedResponse);
        
        if (!analysis || typeof analysis !== 'object') {
          throw new Error('Estructura de análisis inválida');
        }
        
        console.log('✅ Gemini respondió correctamente en reprocesamiento');
        break;
        
      } catch (geminiError) {
        lastError = geminiError;
        console.warn(`⚠️ Intento ${attempt} falló:`, geminiError.message);
        
        if (geminiError.message.includes('API key') ||
            geminiError.message.includes('401') ||
            geminiError.message.includes('403') ||
            geminiError.name === 'SyntaxError') {
          console.error('❌ Error no recuperable en reprocesamiento');
          break;
        }
        
        if (attempt < maxRetries) {
          const waitTime = Math.pow(2, attempt) * 1000;
          console.log(`⏳ Esperando ${waitTime/1000}s antes del siguiente intento...`);
          await new Promise(resolve => setTimeout(resolve, waitTime));
        }
      }
    }
    
    if (!analysis) {
      throw new Error(`Error en reprocesamiento con Gemini: ${lastError.message}`);
    }
    
    // Apply Gemini analysis to words
    let finalWords = [...words]; // Create a copy
    let speakerInfo = {};
    
    if (analysis.segments && Array.isArray(analysis.segments)) {
      console.log(`🎭 Aplicando ${analysis.segments.length} segmentos de Gemini...`);
      
      for (const segment of analysis.segments) {
        const startIndex = parseInt(segment.start_word_index);
        const endIndex = parseInt(segment.end_word_index);
        
        if (!isNaN(startIndex) && !isNaN(endIndex) && startIndex >= 0 && endIndex < finalWords.length) {
          // Assign speaker to words in range
          for (let i = startIndex; i <= endIndex && i < finalWords.length; i++) {
            if (finalWords[i] && segment.speaker_id) {
              finalWords[i].speaker = segment.speaker_id;
            }
          }
          
          // Apply text corrections
          if (segment.corrected_words && Array.isArray(segment.corrected_words)) {
            for (const correction of segment.corrected_words) {
              const correctionIndex = parseInt(correction.index);
              if (!isNaN(correctionIndex) && finalWords[correctionIndex] && correction.corrected_text) {
                finalWords[correctionIndex].text = correction.corrected_text;
              }
            }
          }
        }
      }
    }
    
    // Collect unique speakers
    const uniqueSpeakers = [...new Set(finalWords.map(w => w.speaker).filter(Boolean))];
    uniqueSpeakers.forEach((speaker, index) => {
      speakerInfo[`speaker_${index}`] = speaker;
    });
    
    console.log(`✅ Reprocesamiento completado: ${uniqueSpeakers.length} speakers detectados`);
    
    return {
      words: finalWords,
      full_text: fullText,
      speakers: speakerInfo
    };
    
  } catch (error) {
    console.error('❌ Error en reprocesamiento con Gemini:', error.message);
    throw new Error(`Error reprocesando con Gemini: ${error.message}`);
  }
});

// Helper function for speaker identification - REMOVED
// Now using manual speaker assignment in frontend