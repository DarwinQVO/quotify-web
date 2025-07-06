#!/bin/bash

echo "🔥 Quotify - ESTRUCTURA ORIGINAL FUNCIONAL"
echo "==========================================="

PACKAGE_NAME="Quotify-ESTRUCTURA-ORIGINAL-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión con ESTRUCTURA ORIGINAL..."

# Limpiar y crear directorio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/QuotifyApp"

# Copiar proyecto COMPLETO con estructura original
echo "📋 Copiando proyecto con estructura original..."
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

echo "🔧 Solo corrigiendo transcripción sin cambiar estructura..."

# SOLO CORREGIR EL ARCHIVO MAIN INDEX.JS SIN CAMBIAR LA ESTRUCTURA
# Actualizar solo la función de transcripción
cat > "/tmp/transcription_patch.js" << 'PATCH_EOF'
ipcMain.handle('transcribe-audio', async (event, { url, apiKey }) => {
  let audioFile;
  
  try {
    console.log('=== TRANSCRIPCIÓN CORREGIDA ===');
    console.log('URL:', url);
    
    const tempDir = require('os').tmpdir();
    const videoId = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/)?.[1];
    audioFile = path.join(tempDir, `quotify_${videoId || Date.now()}.m4a`);
    
    console.log('Archivo temporal:', audioFile);
    
    // Configurar PATH para yt-dlp
    const originalPath = process.env.PATH;
    process.env.PATH = `/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${originalPath}`;
    
    console.log('🎵 Descargando audio con yt-dlp...');
    
    // Verificar yt-dlp
    const { execSync } = require('child_process');
    const ytdlpPath = '/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp';
    
    if (!existsSync(ytdlpPath)) {
      throw new Error('yt-dlp no encontrado');
    }
    
    // Usar yt-dlp directamente
    const command = `"${ytdlpPath}" --extract-audio --audio-format m4a --audio-quality 0 --output "${audioFile}" --no-playlist "${url}"`;
    
    execSync(command, { 
      stdio: ['ignore', 'pipe', 'pipe'],
      timeout: 180000
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
      speaker: identifySpeaker(word, result.words)
    })) || [];
    
    return {
      words,
      full_text: result.text
    };
    
  } catch (error) {
    console.error('❌ Error transcripción:', error);
    
    if (audioFile && existsSync(audioFile)) {
      try {
        await fs.unlink(audioFile);
      } catch (e) {}
    }
    
    if (error.message.includes('yt-dlp')) {
      throw new Error('yt-dlp no encontrado');
    } else if (error.message.includes('401')) {
      throw new Error('API key OpenAI inválida');
    } else {
      throw new Error(`Transcripción falló: ${error.message}`);
    }
  }
});
PATCH_EOF

# Aplicar parche reemplazando solo la función transcribe-audio
python3 << 'PYTHON_EOF'
import re

# Leer el archivo original
with open('QuotifyApp/src/main/index.js', 'r') as f:
    content = f.read()

# Leer el parche
with open('/tmp/transcription_patch.js', 'r') as f:
    patch_content = f.read()

# Reemplazar la función transcribe-audio completa
pattern = r"ipcMain\.handle\('transcribe-audio'.*?(?=ipcMain\.handle\('generate-deep-link')"
replacement = patch_content + "\n\n"

new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Escribir el archivo actualizado
with open('QuotifyApp/src/main/index.js', 'w') as f:
    f.write(new_content)

print("✅ Parche aplicado")
PYTHON_EOF

# Limpiar archivo temporal
rm -f /tmp/transcription_patch.js

# 1. INSTALADOR SIMPLE (IGUAL QUE FUNCIONABA)
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación (Estructura Original)"
echo "=============================================="

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

echo ""
echo "📍 Directorio: $(pwd)"
echo "✅ Node.js: $($NODE_PATH --version)"
echo "✅ npm: $($NPM_PATH --version)"
echo ""

echo "📦 Instalando..."
"$NPM_PATH" install

echo ""
echo "✅ ¡Listo!"
read -p "Presiona Enter..."
INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. ABRIR SIMPLE (IGUAL QUE FUNCIONABA)
cat > "2️⃣ ABRIR-QUOTIFY.command" << 'OPEN_EOF'
#!/bin/bash

echo "🚀 Abriendo Quotify (Estructura Original)..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
sleep 2

echo "⚡ Iniciando..."
"$NPM_PATH" run dev
OPEN_EOF

chmod +x "2️⃣ ABRIR-QUOTIFY.command"

# 3. ELECTRON DIRECTO (IGUAL QUE FUNCIONABA)
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

# 4. CREAR APP BUNDLE CON ICONO BONITO
APP_DIR="$DIST_DIR/🎯 Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# ICONO BONITO
if [ -f "/Users/darwinborges/Desktop/Icono Quotify.png" ]; then
    echo "🎨 Creando icono bonito..."
    ICONSET_DIR="/tmp/quotify_original.iconset"
    mkdir -p "$ICONSET_DIR"
    
    sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
    sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
    sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
    sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
    sips -z 64 64 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_64x64.png" 2>/dev/null
    sips -z 32 32 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_32x32.png" 2>/dev/null
    sips -z 16 16 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_16x16.png" 2>/dev/null
    
    iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/quotify.icns" 2>/dev/null
    rm -rf "$ICONSET_DIR"
    echo "✅ Icono bonito creado"
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
    <string>com.quotify.original</string>
    <key>CFBundleName</key>
    <string>Quotify</string>
    <key>CFBundleDisplayName</key>
    <string>🎯 Quotify</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>quotify</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

# Launcher simple
cat > "$APP_DIR/Contents/MacOS/quotify_launcher" << 'LAUNCHER_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    osascript -e 'tell application "System Events" to display dialog "❌ Ejecuta INSTALAR primero" buttons {"OK"}'
    exit 1
fi

cd "$QUOTIFY_DIR"

pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
sleep 2

osascript -e 'tell application "System Events" to display dialog "🚀 Iniciando Quotify..." buttons {"OK"} giving up after 3' &

"$NPM_PATH" run dev > "/tmp/quotify_$(date +%s).log" 2>&1 &

sleep 15

if pgrep -f "electron.*quotify" >/dev/null; then
    osascript -e 'tell application "System Events" to display dialog "✅ ¡Quotify funcionando!" buttons {"OK"}'
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify_launcher"

cat > "LEEME-ORIGINAL.txt" << 'README_EOF'
🔥 QUOTIFY - ESTRUCTURA ORIGINAL FUNCIONAL

==========================================

Esta versión mantiene la ESTRUCTURA ORIGINAL
que funcionaba, solo corrige la transcripción.

📋 COMANDOS:
1️⃣ INSTALAR (una vez)
2️⃣ ABRIR normal
3️⃣ ELECTRON directo
🎯 Quotify.app (icono bonito)

✅ ESTRUCTURA ORIGINAL MANTENIDA
✅ SOLO TRANSCRIPCIÓN CORREGIDA
✅ ICONO BONITO INCLUIDO

Esta es exactamente la estructura que
funcionaba antes, sin cambios raros.
README_EOF

echo ""
echo "✅ VERSIÓN ESTRUCTURA ORIGINAL!"
echo "   🔧 Estructura original mantenida"
echo "   🔧 Solo transcripción corregida"
echo "   🎨 Icono bonito incluido"
echo "   📱 App bundle funcional"

cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🔥 DEBE FUNCIONAR COMO LA ORIGINAL"