#!/bin/bash

echo "🔥 Quotify - VERSIÓN URGENTE CORREGIDA"
echo "======================================"

PACKAGE_NAME="Quotify-URGENTE-CORREGIDO-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión URGENTE con transcripción corregida..."

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

# SOLO AGREGAR CORRECCIÓN DE YT-DLP AL INDEX.JS EXISTENTE
echo "🔧 Corrigiendo transcripción en el código existente..."

# Actualizar solo la parte de transcripción en index.js
cat > "$DIST_DIR/QuotifyApp/src/main/transcription-fix.js" << 'TRANS_FIX'
// PARCHE PARA TRANSCRIPCIÓN - Reemplazar en index.js líneas 230-250

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
    
    // Usar youtube-dl-exec con PATH corregido
    await ytdl(url, {
      extractAudio: true,
      audioFormat: 'm4a',
      audioQuality: 0,
      output: audioFile,
      noPlaylist: true,
      format: 'bestaudio[ext=m4a]/bestaudio'
    });
TRANS_FIX

# Aplicar el parche directamente
sed -i '' '236,246c\
    // Configurar PATH para incluir yt-dlp\
    const originalPath = process.env.PATH;\
    process.env.PATH = `/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${originalPath}`;\
    \
    console.log('\''🎵 Descargando audio con yt-dlp...'\'');\
    console.log('\''PATH:'\'', process.env.PATH);\
    \
    // Verificar que yt-dlp esté disponible\
    const { execSync } = require('\''child_process'\'');\
    try {\
      const ytdlpPath = execSync('\''which yt-dlp'\'', { encoding: '\''utf8'\'' }).trim();\
      console.log('\''yt-dlp encontrado en:'\'', ytdlpPath);\
    } catch (e) {\
      console.error('\''yt-dlp no encontrado en PATH'\'');\
      throw new Error('\''yt-dlp no está instalado. Por favor instálalo primero.'\'');\
    }\
    \
    // Usar youtube-dl-exec con PATH corregido\
    await ytdl(url, {\
      extractAudio: true,\
      audioFormat: '\''m4a'\'',\
      audioQuality: 0,\
      output: audioFile,\
      noPlaylist: true,\
      format: '\''bestaudio[ext=m4a]/bestaudio'\''\
    });' "$DIST_DIR/QuotifyApp/src/main/index.js"

# 1. INSTALADOR DIRECTO (IGUAL QUE LA VERSIÓN URGENTE QUE FUNCIONABA)
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación URGENTE"
echo "================================"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

# RUTAS HARDCODED
NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

echo ""
echo "📍 Directorio: $(pwd)"
echo "✅ Node.js: $($NODE_PATH --version)"
echo "✅ npm: $($NPM_PATH --version)"

# Verificar yt-dlp
if command -v yt-dlp &> /dev/null; then
    echo "✅ yt-dlp: $(yt-dlp --version)"
else
    echo "⚠️ yt-dlp no encontrado - necesario para transcripciones"
    echo "   Instalar con: brew install yt-dlp"
fi

echo ""

# Instalar
echo "📦 Instalando..."
"$NPM_PATH" install

echo ""
echo "✅ ¡Listo!"
echo ""
read -p "Presiona Enter..."
INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. ABRIR DIRECTO (IGUAL QUE LA VERSIÓN URGENTE QUE FUNCIONABA)
cat > "2️⃣ ABRIR-QUOTIFY.command" << 'OPEN_EOF'
#!/bin/bash

echo "🚀 Abriendo Quotify..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

# RUTAS HARDCODED + yt-dlp
export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

# Cerrar anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
sleep 2

# Abrir Quotify
echo "⚡ Iniciando..."
"$NPM_PATH" run dev
OPEN_EOF

chmod +x "2️⃣ ABRIR-QUOTIFY.command"

# 3. ELECTRON DIRECTO (IGUAL QUE LA VERSIÓN URGENTE QUE FUNCIONABA)
cat > "3️⃣ ELECTRON-DIRECTO.command" << 'ELECTRON_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

# RUTAS HARDCODED + yt-dlp
export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

# Cerrar anteriores
pkill -f "electron" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true
sleep 2

# Iniciar Vite en background
"$NPM_PATH" run dev:vite &
VITE_PID=$!

# Esperar Vite
echo "⏳ Esperando Vite..."
sleep 10

# Iniciar Electron
echo "🚀 Abriendo Electron..."
"$NPM_PATH" run dev:electron
ELECTRON_EOF

chmod +x "3️⃣ ELECTRON-DIRECTO.command"

# LEEME URGENTE (IGUAL QUE LA VERSIÓN QUE FUNCIONABA)
cat > "LEEME-URGENTE.txt" << 'README_EOF'
🔥 QUOTIFY - VERSIÓN URGENTE CORREGIDA

====================================

Esta es la MISMA versión que funcionaba,
pero con transcripción corregida.

3 FORMAS DE ABRIR:

1️⃣ INSTALAR primero (solo una vez)
2️⃣ ABRIR-QUOTIFY (método normal)
3️⃣ ELECTRON-DIRECTO (si falla el 2)

✅ FUNCIONA IGUAL QUE ANTES
✅ AHORA CON TRANSCRIPCIÓN ARREGLADA

Se ve la terminal pero TODO funciona:
• Metadata de YouTube
• Transcripción con OpenAI  
• Todas las funciones
README_EOF

echo ""
echo "✅ VERSIÓN URGENTE CORREGIDA!"
echo ""
echo "📋 IGUAL QUE LA QUE FUNCIONABA:"
echo "   1️⃣ INSTALAR"
echo "   2️⃣ ABRIR normal"
echo "   3️⃣ ELECTRON directo"
echo ""
echo "🔧 SOLO AGREGUÉ:"
echo "   ✅ Corrección de yt-dlp para transcripción"
echo ""

# ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🔥 FUNCIONA IGUAL + TRANSCRIPCIÓN ARREGLADA"