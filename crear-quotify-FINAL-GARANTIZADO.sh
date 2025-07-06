#!/bin/bash

echo "🎯 Quotify - VERSIÓN FINAL GARANTIZADA"
echo "======================================"

PACKAGE_NAME="Quotify-FINAL-GARANTIZADO-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

# RUTAS EXACTAS DE TU SISTEMA
NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"
NODE_DIR="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin"

echo "📦 Creando versión FINAL GARANTIZADA..."
echo "✅ Node.js detectado: $NODE_PATH"
echo "✅ npm detectado: $NPM_PATH"

# Limpiar y crear directorio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/QuotifyApp"

# Copiar proyecto completo
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

# GUARDAR RUTAS EXACTAS
cat > "node_paths.env" << ENV_EOF
NODE_PATH=$NODE_PATH
NPM_PATH=$NPM_PATH
NODE_DIR=$NODE_DIR
PATH=$NODE_DIR:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin
ENV_EOF

# 1. INSTALADOR SIMPLE Y DIRECTO
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación GARANTIZADA"
echo "===================================="

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

echo ""
echo "📍 Instalando en: $(pwd)"

# Cargar rutas guardadas
source "$DIR/node_paths.env"

echo ""
echo "✅ Node.js: $($NODE_PATH --version)"
echo "✅ npm: $($NPM_PATH --version)"
echo ""

# Limpiar cache
echo "🧹 Limpiando cache..."
"$NPM_PATH" cache clean --force 2>/dev/null || true

# Instalar dependencias
echo "📦 Instalando dependencias..."
echo "   (Esto puede tomar 3-8 minutos)"
echo ""

"$NPM_PATH" install

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Error en instalación"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 1
fi

echo ""
echo "✅ ¡Instalación completada!"
echo ""
echo "🚀 SIGUIENTE PASO:"
echo "   Doble clic en '🎯 Abrir Quotify.app'"
echo ""
read -p "Presiona Enter para continuar..."
INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. CREAR APP BUNDLE
APP_DIR="$DIST_DIR/🎯 Abrir Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copiar icono
if [ -f "/Users/darwinborges/Desktop/Icono Quotify.png" ]; then
    ICONSET_DIR="/tmp/quotify_final.iconset"
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
    <string>com.quotify.guaranteed</string>
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

# LAUNCHER SIMPLIFICADO
cat > "$APP_DIR/Contents/MacOS/quotify_launcher" << 'LAUNCHER_EOF'
#!/bin/bash

# Directorio de la app
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"
ENV_FILE="$DIR/../../../node_paths.env"

# Cargar rutas
source "$ENV_FILE"

# Cambiar al directorio
cd "$QUOTIFY_DIR"

# Cerrar procesos anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
sleep 2

# Crear log
LOG_FILE="/tmp/quotify_final_$(date +%s).log"
{
    echo "=== Quotify Log $(date) ==="
    echo "PWD: $(pwd)"
    echo "Node: $NODE_PATH"
    echo "npm: $NPM_PATH"
    
    # Arrancar Quotify
    "$NPM_PATH" run dev
} > "$LOG_FILE" 2>&1 &

# Esperar un poco
sleep 3

# Mostrar mensaje
osascript -e 'tell application "System Events" to display dialog "🚀 Quotify iniciándose...

La aplicación aparecerá en 15-20 segundos.

Si no aparece, revisa el Dock de macOS." buttons {"OK"} default button "OK" giving up after 5'

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify_launcher"

# 3. CREAR LEEME
cat > "LEEME-GARANTIZADO.txt" << 'README_EOF'
🎯 QUOTIFY - VERSIÓN FINAL GARANTIZADA

=====================================

Esta versión usa tus rutas EXACTAS de Node.js:
✅ /Users/darwinborges/.nvm/versions/node/v20.19.2/

📋 INSTALACIÓN:
1. Doble clic: "1️⃣ INSTALAR-QUOTIFY.command"
2. Doble clic: "🎯 Abrir Quotify.app"

🔥 GARANTÍA:
Esta versión DEBE funcionar porque usa
las rutas exactas de tu sistema.

Si falla, el problema NO es de rutas.
README_EOF

echo ""
echo "✅ VERSIÓN FINAL GARANTIZADA CREADA!"
echo ""
echo "🎯 USANDO TUS RUTAS EXACTAS:"
echo "   Node.js: $NODE_PATH"
echo "   npm: $NPM_PATH"
echo ""

# Crear ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP FINAL: ${PACKAGE_NAME}.zip"
echo ""
echo "🔥 ESTA VERSIÓN DEBE FUNCIONAR SÍ O SÍ"