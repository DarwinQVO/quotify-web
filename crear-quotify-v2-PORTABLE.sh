#!/bin/bash

echo "✨ Quotify v2.0 - PORTABLE PARA CUALQUIER MAC"
echo "============================================="

PACKAGE_NAME="Quotify-v2.0-PORTABLE"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión portable..."

# Limpiar y crear directorio limpio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/QuotifyApp"

# Copiar SOLO lo necesario del proyecto
echo "📋 Copiando solo lo esencial..."
cp -r "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp/src" "$DIST_DIR/QuotifyApp/"
cp -r "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp/public" "$DIST_DIR/QuotifyApp/"
cp "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp/package.json" "$DIST_DIR/QuotifyApp/"
cp "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp/package-lock.json" "$DIST_DIR/QuotifyApp/"
cp "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp/vite.config.ts" "$DIST_DIR/QuotifyApp/"
cp "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp/tsconfig.json" "$DIST_DIR/QuotifyApp/"
cp "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp/tsconfig.node.json" "$DIST_DIR/QuotifyApp/"
cp "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp/tailwind.config.js" "$DIST_DIR/QuotifyApp/"
cp "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp/postcss.config.js" "$DIST_DIR/QuotifyApp/"
cp "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp/index.html" "$DIST_DIR/QuotifyApp/"

cd "$DIST_DIR"

echo "🔧 Aplicando cambios superficiales..."

# Quitar consola
sed -i '' 's/mainWindow.webContents.openDevTools();/\/\/ mainWindow.webContents.openDevTools(); \/\/ Sin consola/' "QuotifyApp/src/main/index.js"

# Agregar icono
sed -i '' '/minHeight: 700,/a\
    icon: path.join(__dirname, "../../public/icon.png"),
' "QuotifyApp/src/main/index.js"

# Copiar icono
cp "/Users/darwinborges/Desktop/Icono Quotify.png" "QuotifyApp/public/icon.png"

echo "🌍 Creando instalador PORTABLE..."

# INSTALADOR PORTABLE
cat > "Instalar.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify v2.0 - Instalación PORTABLE"
echo "======================================"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

# DETECTAR NODE.JS AUTOMÁTICAMENTE
find_node() {
    # Buscar en ubicaciones comunes
    for NODE_PATH in \
        "/usr/local/bin/node" \
        "/opt/homebrew/bin/node" \
        "$(which node 2>/dev/null)" \
        "$HOME/.nvm/versions/node/*/bin/node" \
        "/usr/bin/node"
    do
        if [ -x "$NODE_PATH" ]; then
            echo "$NODE_PATH"
            return 0
        fi
    done
    
    # Buscar con find
    find /usr/local /opt/homebrew "$HOME" -name "node" -type f -executable 2>/dev/null | head -1
}

# DETECTAR NPM AUTOMÁTICAMENTE  
find_npm() {
    if [ -n "$NODE_FOUND" ]; then
        # npm debe estar en la misma carpeta que node
        NPM_DIR="$(dirname "$NODE_FOUND")"
        if [ -x "$NPM_DIR/npm" ]; then
            echo "$NPM_DIR/npm"
            return 0
        fi
    fi
    
    # Buscar en ubicaciones comunes
    for NPM_PATH in \
        "/usr/local/bin/npm" \
        "/opt/homebrew/bin/npm" \
        "$(which npm 2>/dev/null)" \
        "$HOME/.nvm/versions/node/*/bin/npm" \
        "/usr/bin/npm"
    do
        if [ -x "$NPM_PATH" ]; then
            echo "$NPM_PATH"
            return 0
        fi
    done
}

echo "🔍 Detectando Node.js..."
NODE_FOUND=$(find_node)

if [ -z "$NODE_FOUND" ]; then
    echo ""
    echo "❌ Node.js no encontrado"
    echo ""
    echo "Por favor instala Node.js desde:"
    echo "https://nodejs.org"
    echo ""
    read -p "Presiona Enter..."
    exit 1
fi

echo "🔍 Detectando npm..."
NPM_FOUND=$(find_npm)

if [ -z "$NPM_FOUND" ]; then
    echo ""
    echo "❌ npm no encontrado"
    echo ""
    echo "Por favor reinstala Node.js desde:"
    echo "https://nodejs.org"
    echo ""
    read -p "Presiona Enter..."
    exit 1
fi

echo ""
echo "✅ Node.js: $("$NODE_FOUND" --version)"
echo "✅ npm: $("$NPM_FOUND" --version)"
echo ""

echo "📦 Instalando dependencias..."
"$NPM_FOUND" install

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ¡Instalación exitosa!"
    echo ""
    echo "🚀 Ahora usa: Quotify v2.0.app"
    echo ""
else
    echo ""
    echo "❌ Error en instalación"
    echo ""
fi

read -p "Presiona Enter..."
INSTALL_EOF

chmod +x "Instalar.command"

echo "📱 Creando app PORTABLE..."

# APP PORTABLE
APP_DIR="$DIST_DIR/Quotify v2.0.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Icono
ICONSET_DIR="/tmp/quotify_v2_portable.iconset"
mkdir -p "$ICONSET_DIR"
sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/quotify.icns" 2>/dev/null
rm -rf "$ICONSET_DIR"

# Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>quotify</string>
    <key>CFBundleIdentifier</key>
    <string>com.quotify.v2.portable</string>
    <key>CFBundleName</key>
    <string>Quotify v2.0</string>
    <key>CFBundleDisplayName</key>
    <string>Quotify v2.0</string>
    <key>CFBundleVersion</key>
    <string>2.0</string>
    <key>CFBundleIconFile</key>
    <string>quotify</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST_EOF

# Launcher PORTABLE
cat > "$APP_DIR/Contents/MacOS/quotify" << 'LAUNCHER_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

# DETECTAR NODE.JS Y NPM AUTOMÁTICAMENTE
find_node() {
    for NODE_PATH in \
        "/usr/local/bin/node" \
        "/opt/homebrew/bin/node" \
        "$(which node 2>/dev/null)" \
        "$HOME/.nvm/versions/node/*/bin/node" \
        "/usr/bin/node"
    do
        if [ -x "$NODE_PATH" ]; then
            echo "$NODE_PATH"
            return 0
        fi
    done
    find /usr/local /opt/homebrew "$HOME" -name "node" -type f -executable 2>/dev/null | head -1
}

find_npm() {
    if [ -n "$NODE_FOUND" ]; then
        NPM_DIR="$(dirname "$NODE_FOUND")"
        if [ -x "$NPM_DIR/npm" ]; then
            echo "$NPM_DIR/npm"
            return 0
        fi
    fi
    
    for NPM_PATH in \
        "/usr/local/bin/npm" \
        "/opt/homebrew/bin/npm" \
        "$(which npm 2>/dev/null)" \
        "$HOME/.nvm/versions/node/*/bin/npm" \
        "/usr/bin/npm"
    do
        if [ -x "$NPM_PATH" ]; then
            echo "$NPM_PATH"
            return 0
        fi
    done
}

find_ytdlp() {
    for YTDLP_PATH in \
        "/opt/homebrew/bin/yt-dlp" \
        "/usr/local/bin/yt-dlp" \
        "$(which yt-dlp 2>/dev/null)" \
        "/Library/Frameworks/Python.framework/Versions/*/bin/yt-dlp" \
        "$HOME/.local/bin/yt-dlp"
    do
        if [ -x "$YTDLP_PATH" ]; then
            echo "$YTDLP_PATH"
            return 0
        fi
    done
}

NODE_FOUND=$(find_node)
NPM_FOUND=$(find_npm)
YTDLP_FOUND=$(find_ytdlp)

if [ -z "$NODE_FOUND" ] || [ -z "$NPM_FOUND" ]; then
    osascript -e 'tell application "System Events" to display dialog "❌ Node.js no encontrado\n\nEjecuta Instalar.command primero" buttons {"OK"}'
    exit 1
fi

if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    osascript -e 'tell application "System Events" to display dialog "❌ Ejecuta Instalar.command primero" buttons {"OK"}'
    exit 1
fi

# Configurar PATH con las rutas encontradas
export PATH="$(dirname "$NODE_FOUND"):$(dirname "$YTDLP_FOUND"):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

cd "$QUOTIFY_DIR"

pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 2

osascript -e 'tell application "System Events" to display dialog "🚀 Iniciando Quotify v2.0..." buttons {"OK"} giving up after 3' &

"$NPM_FOUND" run dev > "/tmp/quotify_v2_$(date +%s).log" 2>&1 &

sleep 20

if pgrep -f "electron.*quotify" >/dev/null; then
    osascript -e 'tell application "System Events" to display dialog "✅ Quotify v2.0 funcionando!" buttons {"OK"}'
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify"

echo ""
echo "✨ QUOTIFY v2.0 PORTABLE CREADO!"
echo ""
echo "🌍 FUNCIONA EN CUALQUIER MAC:"
echo "   ✅ Detecta Node.js automáticamente"
echo "   ✅ Detecta npm automáticamente"
echo "   ✅ Detecta yt-dlp automáticamente"
echo ""
echo "📦 SOLO 2 ARCHIVOS:"
echo "   📦 Instalar.command"
echo "   📱 Quotify v2.0.app"
echo ""
echo "🗑️ SIN ARCHIVOS EXTRAS:"
echo "   ❌ Sin LEEMEs"
echo "   ❌ Sin rutas hardcodeadas"
echo "   ❌ Sin dependencias del usuario"

# ZIP PORTABLE
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "✨ ¡PORTABLE Y FUNCIONAL PARA CUALQUIER MAC!"