#!/bin/bash

echo "🎯 Quotify - VERSIÓN CON TRANSCRIPCIÓN CORREGIDA"
echo "================================================"

PACKAGE_NAME="Quotify-TRANSCRIPCION-CORREGIDA-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión con transcripción corregida..."

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

# CORREGIR EL ARCHIVO index.js
echo "🔧 Aplicando corrección de transcripción..."
cp src/main/index-fixed.js "$DIST_DIR/QuotifyApp/src/main/index.js"

cd "$DIST_DIR"

# 0. VERIFICADOR DE YT-DLP
cat > "0️⃣ VERIFICAR-YT-DLP.command" << 'CHECK_EOF'
#!/bin/bash

echo "🔍 Verificación de yt-dlp"
echo "========================"
echo ""

# Buscar yt-dlp en todas las ubicaciones posibles
echo "Buscando yt-dlp..."
echo ""

LOCATIONS=(
    "/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp"
    "/opt/homebrew/bin/yt-dlp"
    "/usr/local/bin/yt-dlp"
    "/usr/bin/yt-dlp"
)

FOUND=false
for loc in "${LOCATIONS[@]}"; do
    if [ -x "$loc" ]; then
        echo "✅ Encontrado: $loc"
        echo "   Versión: $($loc --version)"
        FOUND=true
    fi
done

if [ "$FOUND" = false ]; then
    echo "❌ yt-dlp NO encontrado"
    echo ""
    echo "📥 INSTALACIÓN NECESARIA:"
    echo "1. Opción fácil (con Homebrew):"
    echo "   brew install yt-dlp"
    echo ""
    echo "2. Descarga directa:"
    echo "   curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos -o yt-dlp"
    echo "   chmod +x yt-dlp"
    echo "   sudo mv yt-dlp /usr/local/bin/"
fi

echo ""
read -p "Presiona Enter para salir..."
CHECK_EOF

chmod +x "0️⃣ VERIFICAR-YT-DLP.command"

# 1. INSTALADOR
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación (Transcripción Corregida)"
echo "================================================="

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
echo ""
echo "🔍 Verificando yt-dlp..."
if [ -x "/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp" ]; then
    echo "✅ yt-dlp: $(/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp --version)"
elif command -v yt-dlp &> /dev/null; then
    echo "✅ yt-dlp: $(yt-dlp --version)"
else
    echo "⚠️ yt-dlp NO encontrado"
    echo "   Las transcripciones no funcionarán"
    echo "   Ejecuta: '0️⃣ VERIFICAR-YT-DLP.command'"
fi

echo ""
echo "📦 Instalando dependencias..."
"$NPM_PATH" install

echo ""
echo "✅ ¡Instalación completada!"
echo ""
read -p "Presiona Enter para continuar..."
INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. CERRAR QUOTIFY
cat > "2️⃣ CERRAR-QUOTIFY.command" << 'CLOSE_EOF'
#!/bin/bash

echo "🛑 Cerrando Quotify..."
echo "====================="

# Cerrar todos los procesos
pkill -f "electron.*quotify" 2>/dev/null
pkill -f "vite" 2>/dev/null
lsof -ti:5173 | xargs kill -9 2>/dev/null

echo "✅ Procesos cerrados"
echo ""
read -p "Presiona Enter..."
CLOSE_EOF

chmod +x "2️⃣ CERRAR-QUOTIFY.command"

# 3. APP BUNDLE
APP_DIR="$DIST_DIR/🎯 Abrir Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copiar icono
if [ -f "/Users/darwinborges/Desktop/Icono Quotify.png" ]; then
    ICONSET_DIR="/tmp/quotify_trans.iconset"
    mkdir -p "$ICONSET_DIR"
    
    sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
    sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
    sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
    sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
    
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
    <string>com.quotify.transcription.fixed</string>
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

# RUTAS COMPLETAS
export PATH="/Library/Frameworks/Python.framework/Versions/3.13/bin:/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

# Verificar instalación
if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    osascript -e 'tell application "System Events" to display dialog "❌ Ejecuta primero INSTALAR-QUOTIFY.command" buttons {"OK"} default button "OK"'
    exit 1
fi

cd "$QUOTIFY_DIR"

# Cerrar anteriores
pkill -f "electron.*quotify" 2>/dev/null
pkill -f "vite" 2>/dev/null
lsof -ti:5173 | xargs kill -9 2>/dev/null
sleep 2

# Mostrar inicio
osascript -e 'tell application "System Events" to display dialog "🚀 Iniciando Quotify...

✅ Transcripción corregida
✅ yt-dlp configurado
⏱️ Espera 20 segundos" buttons {"OK"} default button "OK" giving up after 5' &

# Ejecutar
LOG="/tmp/quotify_trans_$(date +%s).log"
{
    echo "=== Quotify Transcription Fixed $(date) ==="
    echo "PATH: $PATH"
    echo "yt-dlp: $(which yt-dlp || echo 'not found')"
    "$NPM_PATH" run dev
} > "$LOG" 2>&1 &

sleep 25

if pgrep -f "electron.*quotify" >/dev/null; then
    osascript -e 'tell application "System Events" to display dialog "✅ ¡Quotify funcionando!

🎵 Transcripción lista
📱 App abierta" buttons {"OK"} default button "OK"'
else
    osascript -e "tell application \"System Events\" to display dialog \"⚠️ Revisa: $LOG\" buttons {\"OK\"} default button \"OK\""
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify_launcher"

# LEEME
cat > "LEEME-TRANSCRIPCION.txt" << 'README_EOF'
🎯 QUOTIFY - TRANSCRIPCIÓN CORREGIDA

====================================

✅ CORRECCIONES APLICADAS:
• PATH actualizado para yt-dlp
• Detección mejorada de yt-dlp
• Manejo de errores robusto
• Logs detallados

📋 USO:
1. Verificar: "0️⃣ VERIFICAR-YT-DLP.command"
2. Instalar: "1️⃣ INSTALAR-QUOTIFY.command"
3. Abrir: "🎯 Abrir Quotify.app"

🎵 TRANSCRIPCIÓN:
• Requiere yt-dlp instalado
• Requiere API key de OpenAI
• Ahora detecta yt-dlp correctamente

Si falla, ejecuta primero:
"2️⃣ CERRAR-QUOTIFY.command"
README_EOF

echo ""
echo "✅ VERSIÓN CON TRANSCRIPCIÓN CORREGIDA!"
echo ""
echo "🔧 CORRECCIONES:"
echo "   ✅ PATH para yt-dlp corregido"
echo "   ✅ Detección de yt-dlp mejorada"
echo "   ✅ Manejo de errores actualizado"
echo ""

# ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🎯 ¡TRANSCRIPCIÓN DEBE FUNCIONAR AHORA!"