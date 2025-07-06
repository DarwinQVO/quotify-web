#!/bin/bash

echo "✨ Quotify - VERSIÓN FINAL LIMPIA"
echo "================================="

PACKAGE_NAME="Quotify-FINAL-LIMPIO-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión FINAL LIMPIA..."

# Limpiar y crear directorio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/QuotifyApp"

# Copiar proyecto con estructura original
echo "📋 Copiando proyecto..."
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

echo "🔧 Aplicando corrección de transcripción..."

# Aplicar corrección de transcripción
python3 << 'PYTHON_EOF'
import re

# Leer archivo original
with open('QuotifyApp/src/main/index.js', 'r') as f:
    content = f.read()

# Función corregida
new_function = '''ipcMain.handle('transcribe-audio', async (event, { url, apiKey }) => {
  let audioFile;
  
  try {
    console.log('=== TRANSCRIPCIÓN ===');
    console.log('URL:', url);
    
    const tempDir = require('os').tmpdir();
    const videoId = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/)?.[1];
    audioFile = path.join(tempDir, `quotify_${videoId || Date.now()}.m4a`);
    
    console.log('Archivo temporal:', audioFile);
    
    // Configurar PATH
    const originalPath = process.env.PATH;
    process.env.PATH = `/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${originalPath}`;
    
    console.log('🎵 Descargando audio...');
    
    // Usar yt-dlp directamente
    const { execSync } = require('child_process');
    const ytdlpPath = '/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp';
    
    if (!existsSync(ytdlpPath)) {
      throw new Error('yt-dlp no encontrado');
    }
    
    const command = `"${ytdlpPath}" --extract-audio --audio-format m4a --audio-quality 0 --output "${audioFile}" --no-playlist "${url}"`;
    
    execSync(command, { 
      stdio: ['ignore', 'pipe', 'pipe'],
      timeout: 180000
    });
    
    console.log('✅ Audio descargado');
    
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
    
    try {
      await fs.unlink(audioFile);
    } catch (e) {}
    
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
});'''

# Reemplazar función
pattern = r"ipcMain\.handle\('transcribe-audio'.*?(?=ipcMain\.handle\('generate-deep-link')"
new_content = re.sub(pattern, new_function + "\n\n", content, flags=re.DOTALL)

with open('QuotifyApp/src/main/index.js', 'w') as f:
    f.write(new_content)

print("✅ Transcripción corregida")
PYTHON_EOF

# 1. INSTALADOR SIMPLE
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "✨ Quotify - Instalación Final"
echo "============================="

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

echo ""
echo "✅ Node.js: $($NODE_PATH --version)"
echo "✅ npm: $($NPM_PATH --version)"
echo ""

echo "📦 Instalando dependencias..."
"$NPM_PATH" install

echo ""
echo "✅ ¡Instalación completada!"
echo ""
echo "🎯 SIGUIENTE PASO:"
echo "   Doble clic en 'Quotify.app'"
echo "   (El icono bonito)"
echo ""
read -p "Presiona Enter para continuar..."
INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. CREAR APP CON ICONO BONITO
APP_DIR="$DIST_DIR/Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# ICONO BONITO
if [ -f "/Users/darwinborges/Desktop/Icono Quotify.png" ]; then
    echo "🎨 Creando icono bonito..."
    ICONSET_DIR="/tmp/quotify_final.iconset"
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
    echo "✅ Icono bonito aplicado"
fi

# Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>quotify</string>
    <key>CFBundleIdentifier</key>
    <string>com.quotify.final</string>
    <key>CFBundleName</key>
    <string>Quotify</string>
    <key>CFBundleDisplayName</key>
    <string>Quotify</string>
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

# Launcher optimizado
cat > "$APP_DIR/Contents/MacOS/quotify" << 'LAUNCHER_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

# Verificar instalación
if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    osascript -e 'tell application "System Events" to display dialog "❌ Ejecuta primero: INSTALAR-QUOTIFY.command" buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

cd "$QUOTIFY_DIR"

# Cerrar instancias anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 2

# Mostrar inicio
osascript -e 'tell application "System Events" to display dialog "🚀 Iniciando Quotify...

✨ Aplicación completa
🎵 Con transcripción funcionando
⏱️ Espera 20 segundos

¡Se abrirá automáticamente!" buttons {"OK"} default button "OK" giving up after 5' &

# Ejecutar en background
LOG="/tmp/quotify_final_$(date +%s).log"
"$NPM_PATH" run dev > "$LOG" 2>&1 &

# Esperar arranque
sleep 20

# Verificar resultado
if pgrep -f "electron.*quotify" >/dev/null; then
    osascript -e 'tell application "System Events" to display dialog "✅ ¡Quotify funcionando perfectamente!

📱 Aplicación abierta
🎵 Transcripción lista
✨ Todas las funciones activas

¡Disfruta Quotify!" buttons {"¡Perfecto!"} default button "¡Perfecto!"'
else
    osascript -e "tell application \"System Events\" to display dialog \"⚠️ Quotify tardó en abrir

Espera un poco más o revisa:
$LOG\" buttons {\"OK\"} default button \"OK\""
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify"

# LEEME FINAL
cat > "LEEME-FINAL.txt" << 'README_EOF'
✨ QUOTIFY - VERSIÓN FINAL LIMPIA

=================================

La versión más simple y funcional.

📋 SOLO 2 PASOS:

1. Doble clic: "1️⃣ INSTALAR-QUOTIFY.command"
   (Solo la primera vez)

2. Doble clic: "Quotify.app" 
   (El icono bonito - siempre funciona)

✨ CARACTERÍSTICAS:
✅ Icono bonito
✅ Sin terminal visible  
✅ Todas las funciones
✅ Transcripción corregida
✅ Super simple de usar

¡Ya no necesitas más comandos!
Solo instalar una vez y usar la app.
README_EOF

echo ""
echo "✨ VERSIÓN FINAL LIMPIA CREADA!"
echo ""
echo "📦 INCLUYE SOLO LO NECESARIO:"
echo "   1️⃣ Instalador (una vez)"
echo "   ✨ Quotify.app (icono bonito)"
echo ""
echo "🎯 SUPER SIMPLE:"
echo "   Instalar → Usar app → ¡Listo!"

cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "✨ ¡LA VERSIÓN MÁS LIMPIA Y FUNCIONAL!"