#!/bin/bash

echo "✨ Quotify v2.1 - VERSIÓN AUTOCONTENIDA (Con Node.js incluido)"
echo "============================================================="

PACKAGE_NAME="Quotify-v2.1-AUTOCONTENIDO"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión que NO requiere Node.js del usuario..."

# Limpiar
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "📋 Copiando proyecto..."
cp -r "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp" "$DIST_DIR/"

cd "$DIST_DIR"

echo "🔧 Aplicando cambios..."

# Quitar consola DevTools
sed -i '' 's/mainWindow.webContents.openDevTools();/\/\/ mainWindow.webContents.openDevTools();/' "QuotifyApp/src/main/index.js"

# Agregar icono
sed -i '' '/minHeight: 700,/a\
    icon: path.join(__dirname, "../../public/icon.png"),
' "QuotifyApp/src/main/index.js"

# Copiar icono
cp "/Users/darwinborges/Desktop/Icono Quotify.png" "QuotifyApp/public/icon.png"

echo "🛠️ Descargando yt-dlp..."
mkdir -p "QuotifyApp/bin"
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos -o "QuotifyApp/bin/yt-dlp" -s
chmod +x "QuotifyApp/bin/yt-dlp"

echo "🔨 Corrigiendo rutas de yt-dlp..."
sed -i '' "s|/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp|path.join(__dirname, '../../bin/yt-dlp')|g" "QuotifyApp/src/main/index.js"

echo "📦 Descargando Node.js portable para macOS..."

# Crear directorio para Node.js
mkdir -p "runtime"

# Descargar Node.js LTS para macOS ARM64
NODE_VERSION="v20.11.1"
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    NODE_ARCH="arm64"
else
    NODE_ARCH="x64"
fi

NODE_URL="https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-darwin-$NODE_ARCH.tar.gz"
echo "Descargando Node.js $NODE_VERSION para $NODE_ARCH..."

curl -L "$NODE_URL" -o "runtime/node.tar.gz" --progress-bar
cd runtime
tar -xzf node.tar.gz
mv "node-$NODE_VERSION-darwin-$NODE_ARCH" nodejs
rm node.tar.gz
cd ..

echo "📦 Instalando dependencias con Node.js incluido..."
cd QuotifyApp

# Usar el Node.js incluido para instalar
../runtime/nodejs/bin/npm install --no-audit --no-fund

cd ..

echo "🎯 Creando aplicación única..."

# UNA SOLA APP QUE HACE TODO
APP_DIR="$DIST_DIR/Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Icono
ICONSET_DIR="/tmp/quotify_autocontenido.iconset"
mkdir -p "$ICONSET_DIR"
for size in 16 32 64 128 256 512 1024; do
    sips -z $size $size "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_${size}x${size}.png" 2>/dev/null
done
# Versiones @2x
cp "$ICONSET_DIR/icon_32x32.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "$ICONSET_DIR/icon_64x64.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "$ICONSET_DIR/icon_256x256.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$ICONSET_DIR/icon_512x512.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$ICONSET_DIR/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/app.icns" 2>/dev/null
rm -rf "$ICONSET_DIR"

# Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Quotify</string>
    <key>CFBundleIdentifier</key>
    <string>com.quotify.standalone</string>
    <key>CFBundleName</key>
    <string>Quotify</string>
    <key>CFBundleDisplayName</key>
    <string>Quotify</string>
    <key>CFBundleVersion</key>
    <string>2.1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>2.1</string>
    <key>CFBundleIconFile</key>
    <string>app</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.10</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

# Launcher AUTOCONTENIDO
cat > "$APP_DIR/Contents/MacOS/Quotify" << 'LAUNCHER_EOF'
#!/bin/bash

# Variables
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$APP_DIR/../../.."
QUOTIFY_DIR="$BASE_DIR/QuotifyApp"
NODE_DIR="$BASE_DIR/runtime/nodejs"

# Verificar estructura
if [ ! -d "$QUOTIFY_DIR" ] || [ ! -d "$NODE_DIR" ]; then
    osascript -e 'display dialog "Error: Estructura de aplicación dañada\n\nPor favor descarga Quotify nuevamente." buttons {"OK"} with icon stop'
    exit 1
fi

# Cambiar al directorio de Quotify
cd "$QUOTIFY_DIR"

# Configurar variables de entorno
export NODE_PATH="$NODE_DIR/lib/node_modules"
export PATH="$QUOTIFY_DIR/bin:$NODE_DIR/bin:/usr/bin:/bin"

# Verificar que Node.js esté disponible
NODE_BIN="$NODE_DIR/bin/node"
NPM_BIN="$NODE_DIR/bin/npm"

if [ ! -x "$NODE_BIN" ] || [ ! -x "$NPM_BIN" ]; then
    osascript -e 'display dialog "Error: Node.js incluido no es ejecutable\n\nPor favor descarga Quotify nuevamente." buttons {"OK"} with icon stop'
    exit 1
fi

# Verificar node_modules
if [ ! -d "node_modules" ]; then
    osascript << 'EOF'
display dialog "Primera ejecución: Instalando dependencias...

Esto puede tomar 1-2 minutos.
Por favor espera." buttons {"OK"} with icon note
EOF
    
    "$NPM_BIN" install > /tmp/quotify_install.log 2>&1
    
    if [ $? -ne 0 ]; then
        osascript -e 'display dialog "Error instalando dependencias\n\nRevisa: /tmp/quotify_install.log" buttons {"OK"} with icon stop'
        exit 1
    fi
fi

# Limpiar procesos anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true

# Breve pausa
sleep 1

# Ejecutar Quotify usando Node.js incluido
exec "$NPM_BIN" run dev > /tmp/quotify_standalone.log 2>&1
LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/Quotify"

echo "📄 Creando instrucciones ultra simples..."

cat > "$DIST_DIR/INSTRUCCIONES.txt" << 'INSTRUCTIONS'
QUOTIFY - VERSIÓN AUTOCONTENIDA
===============================

🚀 SÚPER FÁCIL:

1. Doble clic en Quotify.app
2. ¡LISTO!

✨ TODO INCLUIDO:
- Node.js incorporado
- Todas las dependencias
- yt-dlp integrado
- Sin instalaciones adicionales

🔧 SI NO ABRE:
- Clic derecho en Quotify.app
- Seleccionar "Abrir"
- Confirmar en el diálogo de seguridad

¡No necesitas instalar NADA más!
INSTRUCTIONS

echo "🔓 Removiendo restricciones..."
xattr -cr "$DIST_DIR" 2>/dev/null || true

echo ""
echo "✨ QUOTIFY AUTOCONTENIDO CREADO!"
echo ""
echo "📦 CONTENIDO:"
echo "   📱 Quotify.app (TODO incluido)"
echo "   📄 INSTRUCCIONES.txt"
echo ""
echo "✅ INCLUYE:"
echo "   • Node.js $NODE_VERSION portable"
echo "   • Todas las dependencias"
echo "   • yt-dlp universal"
echo "   • Sin necesidad de instalaciones"
echo ""

# Crear ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -x "*.DS_Store" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🎯 100% AUTOCONTENIDO"
echo "🚀 El usuario NO necesita instalar Node.js!"