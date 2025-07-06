#!/bin/bash

echo "✨ Quotify v2.0 - SUPER LIMPIO"
echo "============================="

PACKAGE_NAME="Quotify-v2.0-LIMPIO"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión super limpia..."

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
    icon: path.join(__dirname, "..\/..\/public\/icon.png"),
' "QuotifyApp/src/main/index.js"

# Copiar icono
cp "/Users/darwinborges/Desktop/Icono Quotify.png" "QuotifyApp/public/icon.png"

echo "📦 Creando instalador limpio..."

# INSTALADOR SIMPLE
cat > "Instalar.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify v2.0 - Instalación"
echo "============================="

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

echo ""
echo "✅ Node.js: $($NODE_PATH --version)"
echo "✅ npm: $($NPM_PATH --version)"
echo ""

echo "📦 Instalando..."
"$NPM_PATH" install

echo ""
echo "✅ ¡Listo!"
echo ""
echo "🚀 Ahora usa: Quotify v2.0.app"
echo ""
read -p "Presiona Enter..."
INSTALL_EOF

chmod +x "Instalar.command"

echo "📱 Creando app..."

# APP LIMPIA
APP_DIR="$DIST_DIR/Quotify v2.0.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Icono
ICONSET_DIR="/tmp/quotify_v2_limpio.iconset"
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
    <string>com.quotify.v2</string>
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

# Launcher
cat > "$APP_DIR/Contents/MacOS/quotify" << 'LAUNCHER_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    osascript -e 'tell application "System Events" to display dialog "❌ Ejecuta Instalar.command primero" buttons {"OK"}'
    exit 1
fi

cd "$QUOTIFY_DIR"

pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 2

osascript -e 'tell application "System Events" to display dialog "🚀 Iniciando Quotify v2.0..." buttons {"OK"} giving up after 3' &

"$NPM_PATH" run dev > "/tmp/quotify_v2_$(date +%s).log" 2>&1 &

sleep 20

if pgrep -f "electron.*quotify" >/dev/null; then
    osascript -e 'tell application "System Events" to display dialog "✅ Quotify v2.0 funcionando!" buttons {"OK"}'
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify"

echo ""
echo "✨ QUOTIFY v2.0 LIMPIO CREADO!"
echo ""
echo "📦 SOLO 2 ARCHIVOS:"
echo "   📦 Instalar.command"
echo "   📱 Quotify v2.0.app"
echo ""
echo "🗑️ SIN ARCHIVOS EXTRAS:"
echo "   ❌ Sin LEEMEs"
echo "   ❌ Sin comandos 2️⃣ y 3️⃣"
echo "   ❌ Sin rutas raras"

# ZIP LIMPIO
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "✨ ¡SUPER LIMPIO Y FUNCIONAL!"