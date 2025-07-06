#!/bin/bash

echo "🔥 Quotify - VERSIÓN CON YT-DLP DIRECTO"
echo "======================================"

PACKAGE_NAME="Quotify-YTDLP-DIRECTO-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión con yt-dlp directo..."

# Limpiar y crear directorio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/QuotifyApp"

# Copiar proyecto
cp -r src "$DIST_DIR/QuotifyApp/"
cp -r public "$DIST_DIR/QuotifyApp/"
cp package.json "$DIST_DIR/QuotifyApp/"
cp package-lock.json "$DIST_DIR/QuotifyApp/"
cp vite.config.ts "$DIST_DIR/QuotifyApp/"
cp tsconfig.json "$DIST_DIR/QuotifyApp/"
cp tsconfig.node.json "$DIST_DIR/QuotifyApp/"
cp tailwind.config.js "$DIST_DIR/QuotifyApp/"
cp postcss.config.js "$DIST_DIR/QuotifyApp/"
cp index.html "$DIST_DIR/QuotifyApp/"

cd "$DIST_DIR"

echo "🔧 Reemplazando transcripción con yt-dlp directo..."

# CREAR INDEX.JS CON YT-DLP DIRECTO (SIN youtube-dl-exec)
cat > "QuotifyApp/src/main/index.js" << 'MAIN_EOF'
const { app, BrowserWindow, ipcMain, shell } = require('electron');
const { autoUpdater } = require('electron-updater');
const path = require('path');
const ytdlCore = require('ytdl-core');
const fs = require('fs').promises;
const { existsSync, createWriteStream } = require('fs');
const os = require('os');
const { execSync, spawn } = require('child_process');

let mainWindow;
const isDev = process.argv.includes('--dev');

// Fix PATH for production environment
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
    console.log('=== TRANSCRIPCIÓN CON YT-DLP DIRECTO ===');
    console.log('URL:', url);
    
    const tempDir = os.tmpdir();
    const videoId = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/)?.[1];
    audioFile = path.join(tempDir, `quotify_${videoId || Date.now()}.m4a`);
    
    console.log('Archivo temporal:', audioFile);
    
    // Configurar PATH
    const originalPath = process.env.PATH;
    process.env.PATH = `/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${originalPath}`;
    
    console.log('🎵 Descargando audio con yt-dlp DIRECTO...');
    
    // Verificar yt-dlp
    const ytdlpPath = '/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp';
    if (!existsSync(ytdlpPath)) {
      throw new Error('yt-dlp no encontrado en la ruta esperada');
    }
    
    console.log('yt-dlp encontrado:', ytdlpPath);
    
    // USAR YT-DLP DIRECTAMENTE CON execSync
    const command = `"${ytdlpPath}" --extract-audio --audio-format m4a --audio-quality 0 --output "${audioFile}" --no-playlist "${url}"`;
    
    console.log('Ejecutando comando:', command);
    
    try {
      execSync(command, { 
        stdio: ['ignore', 'pipe', 'pipe'],
        timeout: 180000, // 3 minutos
        env: { ...process.env, PATH: process.env.PATH }
      });
    } catch (execError) {
      console.error('Error ejecutando yt-dlp:', execError.message);
      throw new Error(`Error descargando audio: ${execError.message}`);
    }
    
    console.log('✅ Comando yt-dlp completado');
    
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
      speaker: 'Speaker 1'
    })) || [];
    
    return {
      words,
      full_text: result.text
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
    if (error.message.includes('yt-dlp')) {
      throw new Error('Error con yt-dlp. Verifica que esté instalado correctamente.');
    } else if (error.message.includes('descargando audio')) {
      throw new Error('Error descargando audio de YouTube. Intenta con otro video.');
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
MAIN_EOF

# CREAR PRELOAD.JS
cat > "QuotifyApp/src/main/preload.js" << 'PRELOAD_EOF'
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  scrapeMetadata: (url) => ipcRenderer.invoke('scrape-metadata', url),
  transcribeAudio: (data) => ipcRenderer.invoke('transcribe-audio', data),
  generateDeepLink: (data) => ipcRenderer.invoke('generate-deep-link', data),
  openExternal: (url) => ipcRenderer.invoke('open-external', url),
  saveApiKey: (apiKey) => ipcRenderer.invoke('save-api-key', apiKey),
  getApiKey: () => ipcRenderer.invoke('get-api-key'),
  checkForUpdates: () => ipcRenderer.invoke('check-for-updates'),
  installUpdate: () => ipcRenderer.invoke('install-update'),
  onUpdateAvailable: (callback) => {
    ipcRenderer.on('update-available', callback);
    return () => ipcRenderer.removeListener('update-available', callback);
  },
  onUpdateDownloaded: (callback) => {
    ipcRenderer.on('update-downloaded', callback);
    return () => ipcRenderer.removeListener('update-downloaded', callback);
  }
});

console.log('✅ Preload script loaded successfully');
PRELOAD_EOF

# 1. INSTALADOR (MISMO QUE FUNCIONABA)
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación (yt-dlp directo)"
echo "========================================"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

echo ""
echo "📍 Directorio: $(pwd)"
echo "✅ Node.js: $($NODE_PATH --version)"
echo "✅ npm: $($NPM_PATH --version)"

# Verificar yt-dlp
if [ -x "/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp" ]; then
    echo "✅ yt-dlp: $(/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp --version)"
else
    echo "❌ yt-dlp NO encontrado en ruta esperada"
fi

echo ""
echo "📦 Instalando..."
"$NPM_PATH" install

echo ""
echo "✅ ¡Listo!"
read -p "Presiona Enter..."
INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. ABRIR (MISMO QUE FUNCIONABA)
cat > "2️⃣ ABRIR-QUOTIFY.command" << 'OPEN_EOF'
#!/bin/bash

echo "🚀 Abriendo Quotify (yt-dlp directo)..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
sleep 2

echo "⚡ Iniciando con yt-dlp directo..."
"$NPM_PATH" run dev
OPEN_EOF

chmod +x "2️⃣ ABRIR-QUOTIFY.command"

# 3. ELECTRON DIRECTO (MISMO QUE FUNCIONABA)
cat > "3️⃣ ELECTRON-DIRECTO.command" << 'ELECTRON_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

pkill -f "electron" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true
sleep 2

"$NPM_PATH" run dev:vite &
echo "⏳ Esperando Vite..."
sleep 10

echo "🚀 Abriendo Electron..."
"$NPM_PATH" run dev:electron
ELECTRON_EOF

chmod +x "3️⃣ ELECTRON-DIRECTO.command"

cat > "LEEME-YTDLP-DIRECTO.txt" << 'README_EOF'
🔥 QUOTIFY - YT-DLP DIRECTO

============================

Esta versión usa yt-dlp DIRECTAMENTE
sin bibliotecas intermedias.

MISMOS COMANDOS:
1️⃣ INSTALAR (una vez)
2️⃣ ABRIR normal
3️⃣ ELECTRON directo

🔧 DIFERENCIA:
• Usa execSync() para llamar yt-dlp
• Sin youtube-dl-exec
• Más confiable

✅ TRANSCRIPCIÓN DEBE FUNCIONAR
README_EOF

echo ""
echo "✅ VERSIÓN YT-DLP DIRECTO!"
echo "   🔧 Sin youtube-dl-exec"
echo "   🔧 Usa execSync directo"
echo "   🔧 Más confiable"

cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🔥 TRANSCRIPCIÓN DEBE FUNCIONAR AHORA"