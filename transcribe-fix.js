// Función simplificada de transcripción que funciona
ipcMain.handle('transcribe-audio', async (event, { url, apiKey }) => {
  let audioFile;
  
  try {
    console.log('=== TRANSCRIPCIÓN SIMPLE ===');
    console.log('URL:', url);
    
    const tempDir = require('os').tmpdir();
    const videoId = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/)?.[1];
    audioFile = path.join(tempDir, `quotify_${videoId || Date.now()}.m4a`);
    
    console.log('Archivo de audio temporal:', audioFile);
    
    // Usar yt-dlp directamente (método más confiable)
    console.log('🎵 Descargando audio con yt-dlp...');
    
    await ytdl(url, {
      extractAudio: true,
      audioFormat: 'm4a',
      audioQuality: 0,
      output: audioFile,
      noPlaylist: true,
      format: 'bestaudio[ext=m4a]/bestaudio'
    });
    
    console.log('✅ Audio descargado correctamente');
    
    // Verificar que el archivo existe
    if (!existsSync(audioFile)) {
      throw new Error('Archivo de audio no fue creado');
    }
    
    const stats = await fs.stat(audioFile);
    console.log(`📁 Archivo de audio: ${(stats.size / 1024 / 1024).toFixed(2)}MB`);
    
    // Leer archivo para OpenAI
    console.log('📤 Enviando a OpenAI...');
    const audioBuffer = await fs.readFile(audioFile);
    
    // Transcribir con OpenAI
    const { OpenAI } = require('openai');
    const openai = new OpenAI({ apiKey });
    
    const transcription = await openai.audio.transcriptions.create({
      file: new File([audioBuffer], `audio.m4a`, { type: 'audio/mp4' }),
      model: 'whisper-1',
      response_format: 'verbose_json',
      timestamp_granularities: ['word']
    });
    
    console.log('✅ Transcripción completada');
    
    // Limpiar archivo temporal
    try {
      await fs.unlink(audioFile);
      console.log('🧹 Archivo temporal eliminado');
    } catch (e) {
      console.log('⚠️ No se pudo eliminar archivo temporal:', e.message);
    }
    
    return transcription;
    
  } catch (error) {
    console.error('❌ Error en transcripción:', error);
    
    // Limpiar archivo temporal en caso de error
    if (audioFile && existsSync(audioFile)) {
      try {
        await fs.unlink(audioFile);
      } catch (e) {}
    }
    
    throw new Error(`Transcripción falló: ${error.message}`);
  }
});