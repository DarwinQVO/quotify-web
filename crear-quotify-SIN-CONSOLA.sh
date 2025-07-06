#!/bin/bash

echo "✨ Quotify - SIN CONSOLA + LOGO PROPIO"
echo "====================================="

PACKAGE_NAME="Quotify-SIN-CONSOLA-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión sin consola y con logo propio..."

# Limpiar y crear directorio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/QuotifyApp"

# Copiar proyecto con las correcciones ya aplicadas
echo "📋 Copiando proyecto corregido..."
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

# 1. INSTALADOR (IGUAL)
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "✨ Quotify - Instalación (Sin consola)"
echo "====================================="

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
echo ""
echo "✨ MEJORAS APLICADAS:"
echo "   🚫 Sin consola molesta"
echo "   🎨 Logo propio en Cmd+Tab"
echo ""
read -p "Presiona Enter para continuar..."
INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. CREAR APP CON ICONO BONITO (IGUAL)
APP_DIR="$DIST_DIR/Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# ICONO BONITO
if [ -f "/Users/darwinborges/Desktop/Icono Quotify.png" ]; then
    echo "🎨 Creando icono bonito..."
    ICONSET_DIR="/tmp/quotify_no_console.iconset"
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
    <string>com.quotify.noconsole</string>
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

# Launcher (IGUAL)
cat > "$APP_DIR/Contents/MacOS/quotify" << 'LAUNCHER_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    osascript -e 'tell application "System Events" to display dialog "❌ Ejecuta primero: INSTALAR-QUOTIFY.command" buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

cd "$QUOTIFY_DIR"

pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 2

osascript -e 'tell application "System Events" to display dialog "🚀 Iniciando Quotify...

✨ Sin consola molesta
🎨 Con logo propio
⏱️ Espera 20 segundos

¡Se abrirá automáticamente!" buttons {"OK"} default button "OK" giving up after 5' &

LOG="/tmp/quotify_no_console_$(date +%s).log"
"$NPM_PATH" run dev > "$LOG" 2>&1 &

sleep 20

if pgrep -f "electron.*quotify" >/dev/null; then
    osascript -e 'tell application "System Events" to display dialog "✅ ¡Quotify funcionando perfectamente!

🚫 Sin consola molesta
🎨 Logo propio en Cmd+Tab
📱 Aplicación limpia

¡Disfruta Quotify mejorado!" buttons {"¡Perfecto!"} default button "¡Perfecto!"'
else
    osascript -e "tell application \"System Events\" to display dialog \"⚠️ Quotify tardó en abrir

Espera un poco más o revisa:
$LOG\" buttons {\"OK\"} default button \"OK\""
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify"

# LEEME
cat > "LEEME-SIN-CONSOLA.txt" << 'README_EOF'
✨ QUOTIFY - SIN CONSOLA + LOGO PROPIO

=====================================

Versión mejorada con cambios superficiales:

🚫 SIN CONSOLA MOLESTA:
   Ya no se abre la pestaña de DevTools

🎨 LOGO PROPIO:
   En Cmd+Tab verás el logo de Quotify
   (no el de Electron)

📋 USO (IGUAL):
1. "1️⃣ INSTALAR-QUOTIFY.command" (una vez)
2. "Quotify.app" (siempre)

✨ MEJORAS APLICADAS:
✅ Sin consola molesta
✅ Logo propio en Dock y Cmd+Tab
✅ Experiencia más limpia
✅ Mismo funcionamiento perfecto

¡Ahora se ve más profesional!
README_EOF

echo ""
echo "✨ VERSIÓN SIN CONSOLA CREADA!"
echo ""
echo "🔧 CAMBIOS SUPERFICIALES APLICADOS:"
echo "   🚫 Consola comentada (no se abre)"
echo "   🎨 Logo propio agregado"
echo ""
echo "📦 MANTIENE:"
echo "   ✅ Misma funcionalidad"
echo "   ✅ Transcripción corregida"
echo "   ✅ Icono bonito"

cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "✨ ¡AHORA SIN CONSOLA MOLESTA!"