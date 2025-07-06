#!/bin/bash

echo "🎯 Quotify - VERSIÓN FUNCIONANDO COMPLETO"
echo "========================================="

PACKAGE_NAME="Quotify-FUNCIONANDO-COMPLETO-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión FUNCIONANDO COMPLETO..."

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

echo "🔧 Creando archivos faltantes..."

# CREAR PRELOAD.JS COMPLETO
cat > "QuotifyApp/src/main/preload.js" << 'PRELOAD_EOF'
const { contextBridge, ipcRenderer } = require('electron');

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
  // Metadata
  scrapeMetadata: (url) => ipcRenderer.invoke('scrape-metadata', url),
  
  // Transcription
  transcribeAudio: (data) => ipcRenderer.invoke('transcribe-audio', data),
  
  // Deep links
  generateDeepLink: (data) => ipcRenderer.invoke('generate-deep-link', data),
  
  // External links
  openExternal: (url) => ipcRenderer.invoke('open-external', url),
  
  // API Key management
  saveApiKey: (apiKey) => ipcRenderer.invoke('save-api-key', apiKey),
  getApiKey: () => ipcRenderer.invoke('get-api-key'),
  
  // Updates
  checkForUpdates: () => ipcRenderer.invoke('check-for-updates'),
  installUpdate: () => ipcRenderer.invoke('install-update'),
  
  // Update listeners
  onUpdateAvailable: (callback) => {
    ipcRenderer.on('update-available', callback);
    return () => ipcRenderer.removeListener('update-available', callback);
  },
  
  onUpdateDownloaded: (callback) => {
    ipcRenderer.on('update-downloaded', callback);
    return () => ipcRenderer.removeListener('update-downloaded', callback);
  }
});

// Log that preload script loaded
console.log('✅ Preload script loaded successfully');
PRELOAD_EOF

# ACTUALIZAR INDEX.JS PRINCIPAL
cat > "QuotifyApp/src/main/index.js" << 'MAIN_EOF'
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
    console.log('=== TRANSCRIPCIÓN ===');
    console.log('URL:', url);
    
    const tempDir = os.tmpdir();
    const videoId = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/)?.[1];
    audioFile = path.join(tempDir, `quotify_${videoId || Date.now()}.m4a`);
    
    console.log('Archivo temporal:', audioFile);
    
    // Configurar PATH
    const originalPath = process.env.PATH;
    process.env.PATH = `/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${originalPath}`;
    
    console.log('🎵 Descargando audio...');
    
    // Verificar yt-dlp
    const { execSync } = require('child_process');
    try {
      const ytdlpPath = execSync('which yt-dlp', { encoding: 'utf8' }).trim();
      console.log('yt-dlp encontrado:', ytdlpPath);
    } catch (e) {
      throw new Error('yt-dlp no está instalado');
    }
    
    // Descargar audio
    await ytdl(url, {
      extractAudio: true,
      audioFormat: 'm4a',
      audioQuality: 0,
      output: audioFile,
      noPlaylist: true,
      format: 'bestaudio[ext=m4a]/bestaudio'
    });
    
    console.log('✅ Audio descargado');
    
    // Verificar archivo
    if (!existsSync(audioFile)) {
      throw new Error('Archivo de audio no fue creado');
    }
    
    const stats = await fs.stat(audioFile);
    console.log(`📁 Tamaño: ${(stats.size / 1024 / 1024).toFixed(2)}MB`);
    
    // OpenAI
    console.log('📤 Enviando a OpenAI...');
    const audioBuffer = await fs.readFile(audioFile);
    
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
        timeout: 300000
      }
    );
    
    console.log('✅ Transcripción completada');
    
    // Limpiar
    try {
      await fs.unlink(audioFile);
    } catch (e) {}
    
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
    console.error('❌ Error transcripción:', error);
    
    // Limpiar archivo
    if (audioFile && existsSync(audioFile)) {
      try {
        await fs.unlink(audioFile);
      } catch (e) {}
    }
    
    if (error.message.includes('yt-dlp')) {
      throw new Error('yt-dlp no encontrado. Instálalo primero.');
    } else if (error.message.includes('401')) {
      throw new Error('API key de OpenAI inválida');
    } else if (error.message.includes('timeout')) {
      throw new Error('Timeout - video muy largo');
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

// API Key storage
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

# 1. INSTALADOR
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación COMPLETA"
echo "================================="

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

echo ""
echo "✅ Node.js: $($NODE_PATH --version)"
echo "✅ npm: $($NPM_PATH --version)"

if command -v yt-dlp &> /dev/null; then
    echo "✅ yt-dlp: $(yt-dlp --version)"
else
    echo "⚠️ yt-dlp no instalado"
fi

echo ""
echo "📦 Instalando..."
"$NPM_PATH" install

echo ""
echo "✅ ¡Listo!"
read -p "Presiona Enter..."
INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. CERRAR
cat > "2️⃣ CERRAR-QUOTIFY.command" << 'CLOSE_EOF'
#!/bin/bash
pkill -f "electron.*quotify" 2>/dev/null
pkill -f "vite" 2>/dev/null
lsof -ti:5173 | xargs kill -9 2>/dev/null
echo "✅ Cerrado"
read -p "Enter..."
CLOSE_EOF

chmod +x "2️⃣ CERRAR-QUOTIFY.command"

# 3. APP BUNDLE
APP_DIR="$DIST_DIR/🎯 Abrir Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Icono
if [ -f "/Users/darwinborges/Desktop/Icono Quotify.png" ]; then
    ICONSET_DIR="/tmp/quotify_completo.iconset"
    mkdir -p "$ICONSET_DIR"
    sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
    sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
    iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/quotify.icns" 2>/dev/null
    rm -rf "$ICONSET_DIR"
fi

# Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>quotify_launcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.quotify.completo</string>
    <key>CFBundleName</key>
    <string>Quotify</string>
    <key>CFBundleDisplayName</key>
    <string>🎯 Abrir Quotify</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>quotify</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST_EOF

# LAUNCHER
cat > "$APP_DIR/Contents/MacOS/quotify_launcher" << 'LAUNCHER_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

export PATH="/Library/Frameworks/Python.framework/Versions/3.13/bin:/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    osascript -e 'tell application "System Events" to display dialog "❌ Ejecuta INSTALAR primero" buttons {"OK"}'
    exit 1
fi

cd "$QUOTIFY_DIR"

# Cerrar anteriores
pkill -f "electron.*quotify" 2>/dev/null
pkill -f "vite" 2>/dev/null
lsof -ti:5173 | xargs kill -9 2>/dev/null
sleep 2

osascript -e 'tell application "System Events" to display dialog "🚀 Iniciando Quotify completo..." buttons {"OK"} giving up after 3' &

LOG="/tmp/quotify_completo_$(date +%s).log"
"$NPM_PATH" run dev > "$LOG" 2>&1 &

sleep 20

if pgrep -f "electron.*quotify" >/dev/null; then
    osascript -e 'tell application "System Events" to display dialog "✅ ¡Quotify funcionando!" buttons {"OK"}'
else
    osascript -e "tell application \"System Events\" to display dialog \"⚠️ Revisa: $LOG\" buttons {\"OK\"}"
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify_launcher"

cat > "LEEME-COMPLETO.txt" << 'README_EOF'
🎯 QUOTIFY - VERSIÓN FUNCIONANDO COMPLETO

========================================

✅ INCLUYE PRELOAD.JS CORREGIDO
✅ TODAS LAS FUNCIONES ACTIVAS
✅ TRANSCRIPCIÓN CORREGIDA

📋 USO:
1. "1️⃣ INSTALAR-QUOTIFY.command"
2. "🎯 Abrir Quotify.app"

Esta versión tiene TODOS los archivos
necesarios para funcionar correctamente.
README_EOF

echo ""
echo "✅ VERSIÓN FUNCIONANDO COMPLETO!"
echo "   ✅ Preload.js creado"
echo "   ✅ Index.js corregido" 
echo "   ✅ Todas las funciones"

cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🎯 ¡DEBE FUNCIONAR COMPLETAMENTE!"