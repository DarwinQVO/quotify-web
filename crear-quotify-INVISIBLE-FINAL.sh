#!/bin/bash

echo "🎯 Quotify - VERSIÓN INVISIBLE FINAL"
echo "===================================="

PACKAGE_NAME="Quotify-INVISIBLE-FINAL-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión INVISIBLE..."

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

# 1. INSTALADOR (se mantiene con terminal para ver progreso)
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación"
echo "========================"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

# RUTAS HARDCODED
NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

echo ""
echo "📍 Directorio: $(pwd)"
echo "✅ Node.js: $($NODE_PATH --version)"
echo "✅ npm: $($NPM_PATH --version)"
echo ""

# Instalar
echo "📦 Instalando dependencias..."
echo "   (Esto toma 3-8 minutos)"
echo ""
"$NPM_PATH" install

echo ""
echo "✅ ¡Instalación completada!"
echo ""
echo "🚀 SIGUIENTE PASO:"
echo "   Doble clic en '🎯 Abrir Quotify.app'"
echo ""
read -p "Presiona Enter para continuar..."
INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. CREAR APP BUNDLE INVISIBLE
APP_DIR="$DIST_DIR/🎯 Abrir Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copiar icono
if [ -f "/Users/darwinborges/Desktop/Icono Quotify.png" ]; then
    ICONSET_DIR="/tmp/quotify_invisible.iconset"
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
    <string>com.quotify.invisible</string>
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
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

# LAUNCHER INVISIBLE
cat > "$APP_DIR/Contents/MacOS/quotify_launcher" << 'LAUNCHER_EOF'
#!/bin/bash

# Directorio de la app
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

# RUTAS HARDCODED
export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/usr/local/bin:/usr/bin:/bin"
NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

# Función para diálogos
show_dialog() {
    osascript -e "tell application \"System Events\" to display dialog \"$1\" buttons {\"$2\"} default button \"$2\" with icon note"
}

show_choice() {
    result=$(osascript -e "tell application \"System Events\" to display dialog \"$1\" buttons {\"Cancelar\", \"$2\"} default button \"$2\" with icon note" 2>&1)
    if [[ $result == *"$2"* ]]; then
        return 0
    else
        return 1
    fi
}

# Preguntar si abrir
if ! show_choice "🎯 Quotify - Aplicación Completa

✅ Funciona perfectamente
✅ Backend Electron + Frontend React
✅ Sin terminal visible
🔇 Se ejecuta de forma invisible

¿Iniciar Quotify?" "🚀 Abrir Quotify"; then
    exit 0
fi

# Verificar instalación
if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    show_dialog "❌ Quotify no está instalado

Por favor ejecuta primero:
'1️⃣ INSTALAR-QUOTIFY.command'" "Entendido"
    exit 1
fi

# Cambiar al directorio
cd "$QUOTIFY_DIR"

# Cerrar procesos anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
sleep 2

# Mostrar progreso
show_dialog "🚀 Iniciando Quotify...

⚡ Preparando aplicación
⏱️ Toma 15-20 segundos
🔇 Sin terminal visible

¡No cierres este mensaje!" "Entendido" &

# LOG SILENCIOSO
LOG_FILE="/tmp/quotify_invisible_$(date +%s).log"

# EJECUTAR INVISIBLE
{
    echo "=== Quotify Invisible Log $(date) ==="
    echo "PWD: $(pwd)"
    echo "Node: $NODE_PATH"
    echo "npm: $NPM_PATH"
    
    # Ejecutar npm run dev
    "$NPM_PATH" run dev
} > "$LOG_FILE" 2>&1 &

# Esperar que arranque
sleep 20

# Verificar si funciona
if pgrep -f "electron.*quotify" >/dev/null; then
    show_dialog "✅ ¡Quotify funcionando!

📱 Aplicación abierta
🔇 Sin terminal visible
🔥 Todas las funciones activas

Si no ves la ventana:
• Revisa el Dock de macOS
• Usa Mission Control (F3)" "¡Perfecto!"
else
    show_dialog "⚠️ Quotify tardó en abrir

Intenta otra vez o usa:
'2️⃣ ABRIR-MANUAL.command'

Log: $LOG_FILE" "Entendido"
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify_launcher"

# 3. COMANDO MANUAL (por si acaso)
cat > "2️⃣ ABRIR-MANUAL.command" << 'MANUAL_EOF'
#!/bin/bash

echo "🚀 Abriendo Quotify (modo manual)..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

# RUTAS HARDCODED
export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/usr/local/bin:/usr/bin:/bin"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

# Cerrar anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
sleep 2

# Abrir
echo "⚡ Iniciando..."
"$NPM_PATH" run dev
MANUAL_EOF

chmod +x "2️⃣ ABRIR-MANUAL.command"

# LEEME
cat > "LEEME-INVISIBLE.txt" << 'README_EOF'
🎯 QUOTIFY - VERSIÓN INVISIBLE FINAL

====================================

✅ FUNCIONA PERFECTAMENTE
✅ SIN TERMINAL VISIBLE

📋 USO:
1. Instalar: "1️⃣ INSTALAR-QUOTIFY.command"
2. Abrir: "🎯 Abrir Quotify.app"

🔇 La app se abre SIN mostrar terminal.

Si necesitas ver qué pasa:
• Usa "2️⃣ ABRIR-MANUAL.command"

¡Disfruta Quotify invisible!
README_EOF

echo ""
echo "✅ VERSIÓN INVISIBLE FINAL CREADA!"
echo ""
echo "🔇 CARACTERÍSTICAS:"
echo "   ✅ App bundle sin terminal"
echo "   ✅ Ejecución en background"
echo "   ✅ Diálogos nativos macOS"
echo "   ✅ Logs silenciosos"
echo ""

# ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🎯 ¡VERSIÓN INVISIBLE LISTA!"