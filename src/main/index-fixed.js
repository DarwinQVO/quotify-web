const { app, BrowserWindow, ipcMain, shell } = require('electron');
const { autoUpdater } = require('electron-updater');
const path = require('path');
const ytdl = require('youtube-dl-exec');
const ytdlCore = require('ytdl-core');
const fs = require('fs').promises;
const { existsSync, createWriteStream } = require('fs');
const os = require('os');

let mainWindow;
const isDev = process.argv.includes('--dev');

// Fix PATH for production environment - ACTUALIZADO CON RUTAS CORRECTAS
if (!isDev) {
  process.env.PATH = `/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${process.env.PATH}`;
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
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    }
  });

  if (isDev) {
    mainWindow.loadURL('http://localhost:5173');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(createWindow);

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

// Auto-updater events
autoUpdater.on('update-available', () => {
  mainWindow?.webContents.send('update-available');
});

autoUpdater.on('update-downloaded', () => {
  mainWindow?.webContents.send('update-downloaded');
});

ipcMain.handle('install-update', () => {
  autoUpdater.quitAndInstall();
});

ipcMain.handle('check-for-updates', async () => {
  try {
    const result = await autoUpdater.checkForUpdates();
    return result;
  } catch (error) {
    console.error('Error checking for updates:', error);
    return null;
  }
});

// IPC Handlers
ipcMain.handle('scrape-metadata', async (event, url) => {
  try {
    console.log('=== METADATA SCRAPING ===');
    console.log('URL:', url);
    console.log('Using ytdl-core for metadata...');
    
    // Validate URL
    if (!ytdlCore.validateURL(url)) {
      throw new Error('Invalid YouTube URL');
    }
    
    // Get info using ytdl-core
    const info = await ytdlCore.getBasicInfo(url);
    const details = info.videoDetails;
    
    // Format duration
    const durationInSeconds = parseInt(details.lengthSeconds);
    const hours = Math.floor(durationInSeconds / 3600);
    const minutes = Math.floor((durationInSeconds % 3600) / 60);
    const seconds = durationInSeconds % 60;
    
    let duration;
    if (hours > 0) {
      duration = `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    } else {
      duration = `${minutes}:${seconds.toString().padStart(2, '0')}`;
    }
    
    // Get best thumbnail
    const thumbnail = details.thumbnails && details.thumbnails.length > 0
      ? details.thumbnails[details.thumbnails.length - 1].url
      : null;
    
    const metadata = {
      title: details.title || 'Unknown Title',
      channel: details.author?.name || details.ownerChannelName || 'Unknown Channel',
      duration: duration,
      thumbnail: thumbnail,
      channelId: details.channelId || '',
      channelUrl: details.author?.channel_url || (details.channelId ? `https://www.youtube.com/channel/${details.channelId}` : ''),
      uploadDate: details.uploadDate || details.publishDate || null,
      viewCount: details.viewCount || '0',
      description: details.description || '',
      isLive: details.isLiveContent || false,
      isPrivate: details.isPrivate || false
    };
    
    console.log('✅ Metadata scraped successfully');
    return metadata;
    
  } catch (error) {
    console.error('❌ Metadata scraping error:', error);
    console.error('Error details:', {
      message: error.message,
      code: error.code,
      statusCode: error.statusCode,
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

ipcMain.handle('transcribe-audio', async (event, { url, apiKey }) => {
  let audioFile;
  
  try {
    console.log('=== TRANSCRIPCIÓN MEJORADA ===');
    console.log('URL:', url);
    
    const tempDir = os.tmpdir();
    const videoId = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/)?.[1];
    audioFile = path.join(tempDir, `quotify_${videoId || Date.now()}.m4a`);
    
    console.log('Archivo temporal:', audioFile);
    
    // Configurar PATH para incluir yt-dlp
    const originalPath = process.env.PATH;
    process.env.PATH = `/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${originalPath}`;
    
    console.log('🎵 Descargando audio con yt-dlp...');
    console.log('PATH:', process.env.PATH);
    
    // Verificar que yt-dlp esté disponible
    const { execSync } = require('child_process');
    try {
      const ytdlpPath = execSync('which yt-dlp', { encoding: 'utf8' }).trim();
      console.log('yt-dlp encontrado en:', ytdlpPath);
    } catch (e) {
      console.error('yt-dlp no encontrado en PATH');
      throw new Error('yt-dlp no está instalado. Por favor instálalo primero.');
    }
    
    // Usar youtube-dl-exec con la ruta correcta
    await ytdl(url, {
      extractAudio: true,
      audioFormat: 'm4a',
      audioQuality: 0,
      output: audioFile,
      noPlaylist: true,
      format: 'bestaudio[ext=m4a]/bestaudio',
      // Especificar la ruta de yt-dlp explícitamente
      youtubeDlPath: '/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp'
    });
    
    console.log('✅ Audio descargado correctamente');
    
    // Verificar que el archivo existe
    if (!existsSync(audioFile)) {
      throw new Error('Archivo de audio no fue creado');
    }
    
    const stats = await fs.stat(audioFile);
    console.log(`📁 Tamaño del archivo: ${(stats.size / 1024 / 1024).toFixed(2)}MB`);
    
    // Leer archivo para OpenAI
    console.log('📤 Enviando a OpenAI...');
    const audioBuffer = await fs.readFile(audioFile);
    
    // Transcribir con OpenAI usando form-data
    const FormData = require('form-data');
    const axios = require('axios');
    
    const formData = new FormData();
    formData.append('file', audioBuffer, {
      filename: 'audio.m4a',
      contentType: 'audio/mp4'
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
        timeout: 300000 // 5 minutos
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
      speaker: identifySpeaker(word, result.words)
    })) || [];
    
    return {
      words,
      full_text: result.text
    };
    
  } catch (error) {
    console.error('❌ Error en transcripción:', error.message);
    console.error('Error completo:', error);
    
    // Limpiar archivo temporal en caso de error
    if (audioFile && existsSync(audioFile)) {
      try {
        await fs.unlink(audioFile);
      } catch (e) {}
    }
    
    // Mensajes de error más claros
    if (error.message.includes('yt-dlp')) {
      throw new Error('Error con yt-dlp. Verifica que esté instalado correctamente.');
    } else if (error.message.includes('command not found')) {
      throw new Error('yt-dlp no encontrado. Instálalo ejecutando el instalador incluido.');
    } else if (error.message.includes('OpenAI') || error.message.includes('401')) {
      throw new Error('Error con API key de OpenAI. Verifica que sea correcta.');
    } else if (error.message.includes('timeout')) {
      throw new Error('Transcripción tomó demasiado tiempo. Intenta con un video más corto.');
    } else {
      throw new Error(`Transcripción falló: ${error.message}`);
    }
  }
});

// Función helper para identificar speakers (básica)
function identifySpeaker(word, allWords) {
  // Implementación básica - podrías mejorarla
  return 'Speaker 1';
}

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
    const config = { apiKey };
    await fs.writeFile(configPath, JSON.stringify(config, null, 2));
    return true;
  } catch (error) {
    console.error('Error saving API key:', error);
    return false;
  }
});

ipcMain.handle('get-api-key', async () => {
  try {
    const configPath = getConfigPath();
    if (existsSync(configPath)) {
      const data = await fs.readFile(configPath, 'utf8');
      const config = JSON.parse(data);
      return config.apiKey || null;
    }
    return null;
  } catch (error) {
    console.error('Error loading API key:', error);
    return null;
  }
});