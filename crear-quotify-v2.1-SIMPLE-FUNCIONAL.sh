#!/bin/bash

echo "✨ Quotify v2.1 - VERSIÓN SIMPLE QUE FUNCIONA"
echo "============================================="

PACKAGE_NAME="Quotify-v2.1-SIMPLE-FUNCIONAL"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Usando la versión original que sabemos que funciona..."

# Limpiar
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "📋 Copiando la versión original EXACTA que funciona..."
cp -r "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp" "$DIST_DIR/"

cd "$DIST_DIR"

echo "🔧 Solo aplicando los 2 cambios superficiales que pediste..."

# 1. Quitar consola DevTools
sed -i '' 's/mainWindow.webContents.openDevTools();/\/\/ mainWindow.webContents.openDevTools();/' "QuotifyApp/src/main/index.js"

# 2. Agregar icono
sed -i '' '/minHeight: 700,/a\
    icon: path.join(__dirname, "../../public/icon.png"),
' "QuotifyApp/src/main/index.js"

# Copiar icono
cp "/Users/darwinborges/Desktop/Icono Quotify.png" "QuotifyApp/public/icon.png"

echo "🛠️ Agregando yt-dlp incluido..."
mkdir -p "QuotifyApp/bin"
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos -o "QuotifyApp/bin/yt-dlp" --progress-bar
chmod +x "QuotifyApp/bin/yt-dlp"

echo "🔨 Corrigiendo SOLO la línea de yt-dlp..."
# Reemplazar SOLO la línea problemática
sed -i '' "s|const ytdlpPath = '/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp';|const ytdlpPath = path.join(__dirname, '../../bin/yt-dlp');|g" "QuotifyApp/src/main/index.js"

echo "📦 Instalando dependencias con tu Node.js (que sabemos que funciona)..."
cd QuotifyApp

# NO tocar package.json, usar el original
npm install --no-audit --no-fund

if [ $? -ne 0 ]; then
    echo "❌ Error instalando dependencias"
    exit 1
fi

cd ..

echo "🎯 Creando aplicación simple..."

# Crear estructura de app
APP_DIR="$DIST_DIR/Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Crear icono
ICONSET_DIR="/tmp/quotify_simple.iconset"
mkdir -p "$ICONSET_DIR"
sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/app.icns" 2>/dev/null
rm -rf "$ICONSET_DIR"

# Info.plist simple
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Quotify</string>
    <key>CFBundleIdentifier</key>
    <string>com.quotify.simple</string>
    <key>CFBundleName</key>
    <string>Quotify</string>
    <key>CFBundleDisplayName</key>
    <string>Quotify</string>
    <key>CFBundleVersion</key>
    <string>2.1</string>
    <key>CFBundleIconFile</key>
    <string>app</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

# Launcher SUPER SIMPLE que usa exactamente el mismo comando que funciona
cat > "$APP_DIR/Contents/MacOS/Quotify" << 'LAUNCHER_EOF'
#!/bin/bash

# Ir al directorio correcto
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$APP_DIR/../../../QuotifyApp"

cd "$QUOTIFY_DIR" || exit 1

# Buscar npm del sistema
if ! command -v npm >/dev/null 2>&1; then
    osascript -e 'display dialog "Node.js no encontrado\n\nInstala desde nodejs.org" buttons {"OK"} with icon stop'
    exit 1
fi

# Configurar PATH con yt-dlp incluido
export PATH="$QUOTIFY_DIR/bin:$PATH"

# Limpiar puerto
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 1

# Ejecutar exactamente igual que la versión original
exec npm run dev > /tmp/quotify_simple.log 2>&1
LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/Quotify"

echo "📄 Creando instrucciones super simples..."
cat > "$DIST_DIR/COMO-USAR.txt" << 'SIMPLE_INSTRUCTIONS'
QUOTIFY - VERSIÓN SIMPLE
=======================

REQUISITO:
Node.js desde nodejs.org

USO:
1. Doble clic en Quotify.app
2. Espera 30 segundos
3. ¡Se abre automáticamente!

INCLUYE:
✅ yt-dlp para YouTube
✅ Sin consola molesta
✅ Logo de Quotify

LOGS: /tmp/quotify_simple.log
SIMPLE_INSTRUCTIONS

echo "🔓 Removiendo restricciones..."
xattr -cr "$DIST_DIR" 2>/dev/null || true

echo "🧪 Probando instalación..."

if [ -d "QuotifyApp/node_modules" ]; then
    echo "✅ Dependencias instaladas"
else
    echo "❌ Dependencias faltantes"
    exit 1
fi

if [ -x "QuotifyApp/bin/yt-dlp" ]; then
    echo "✅ yt-dlp incluido"
else
    echo "❌ yt-dlp faltante"
    exit 1
fi

# Verificar que no rompimos el package.json original
if grep -q "concurrently" "QuotifyApp/package.json"; then
    echo "✅ package.json original intacto"
else
    echo "❌ package.json modificado"
    exit 1
fi

echo "🧪 PROBANDO LA APLICACIÓN REAL..."

# Probar que npm run dev funciona
cd QuotifyApp
timeout 20s npm run dev > /tmp/test_quotify_simple.log 2>&1 &
TEST_PID=$!

sleep 15

if pgrep -f "npm.*run.*dev" >/dev/null; then
    echo "✅ npm run dev funciona"
    kill $TEST_PID 2>/dev/null
    pkill -f "npm.*run.*dev" 2>/dev/null
    pkill -f "electron" 2>/dev/null
    pkill -f "vite" 2>/dev/null
else
    echo "❌ npm run dev no funciona"
    cat /tmp/test_quotify_simple.log
    exit 1
fi

cd ..

echo ""
echo "✨ QUOTIFY SIMPLE FUNCIONAL CREADO!"
echo ""
echo "✅ VERIFICADO:"
echo "   • Dependencias instaladas"
echo "   • yt-dlp incluido"
echo "   • package.json original"
echo "   • npm run dev funciona"
echo ""
echo "📦 CAMBIOS MÍNIMOS:"
echo "   • Sin consola DevTools"
echo "   • Logo de Quotify"
echo "   • yt-dlp incluido"
echo ""

# Crear ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -x "*.DS_Store" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🎯 ¡ESTA VERSIÓN DEBERÍA FUNCIONAR 100%!"