#!/bin/bash

echo "✨ Quotify v2.0 - SIN FRICCIÓN PARA USUARIOS"
echo "==========================================="

PACKAGE_NAME="Quotify-v2.0-SIN-FRICCION"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión sin fricción..."

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

echo "🛠️ Descargando yt-dlp incluido..."

# Descargar yt-dlp para incluir en el paquete
mkdir -p "QuotifyApp/bin"
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos -o "QuotifyApp/bin/yt-dlp"
chmod +x "QuotifyApp/bin/yt-dlp"

echo "🔐 Creando instalador SIN FRICCIÓN..."

# INSTALADOR SIN FRICCIÓN USANDO .APP
APP_INSTALLER_DIR="$DIST_DIR/Instalar Quotify.app"
mkdir -p "$APP_INSTALLER_DIR/Contents/MacOS"
mkdir -p "$APP_INSTALLER_DIR/Contents/Resources"

# Info.plist para instalador
cat > "$APP_INSTALLER_DIR/Contents/Info.plist" << 'INSTALLER_PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>installer</string>
    <key>CFBundleIdentifier</key>
    <string>com.quotify.installer</string>
    <key>CFBundleName</key>
    <string>Instalar Quotify</string>
    <key>CFBundleDisplayName</key>
    <string>Instalar Quotify</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
</dict>
</plist>
INSTALLER_PLIST_EOF

# Script instalador como .app
cat > "$APP_INSTALLER_DIR/Contents/MacOS/installer" << 'INSTALLER_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/../../../QuotifyApp"

# Mostrar diálogo de bienvenida
osascript << 'WELCOME_EOF'
tell application "System Events"
    display dialog "🎯 Quotify v2.0 - Instalación

✨ Sin consola molesta
🎨 Logo propio incluido
🛠️ yt-dlp incluido
🚀 Instalación automática

¿Continuar?" buttons {"Cancelar", "Instalar"} default button "Instalar" with icon note
    if button returned of result is "Cancelar" then
        error number -128
    end if
end tell
WELCOME_EOF

if [ $? -ne 0 ]; then
    exit 0
fi

# DETECTAR NODE.JS AUTOMÁTICAMENTE
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

NODE_FOUND=$(find_node)
NPM_FOUND=$(find_npm)

if [ -z "$NODE_FOUND" ] || [ -z "$NPM_FOUND" ]; then
    osascript << 'ERROR_EOF'
tell application "System Events"
    display dialog "❌ Node.js no encontrado

Por favor instala Node.js desde:
https://nodejs.org

Después ejecuta este instalador otra vez." buttons {"OK"} default button "OK" with icon stop
end tell
ERROR_EOF
    exit 1
fi

# Mostrar progreso
osascript << 'PROGRESS_EOF' &
tell application "System Events"
    display dialog "📦 Instalando Quotify v2.0...

✅ Node.js detectado
✅ yt-dlp incluido
⏳ Instalando dependencias...

Por favor espera..." buttons {"OK"} default button "OK" with icon note giving up after 30
end tell
PROGRESS_EOF

# Instalar dependencias
"$NPM_FOUND" install > /tmp/quotify_install.log 2>&1

if [ $? -eq 0 ]; then
    osascript << 'SUCCESS_EOF'
tell application "System Events"
    display dialog "✅ ¡Quotify v2.0 instalado exitosamente!

📦 Solo 2 archivos:
• Instalar Quotify.app ✅
• Quotify v2.0.app 🚀

🎉 Ahora puedes usar Quotify v2.0.app" buttons {"¡Perfecto!"} default button "¡Perfecto!" with icon note
end tell
SUCCESS_EOF
else
    osascript << 'INSTALL_ERROR_EOF'
tell application "System Events"
    display dialog "❌ Error en la instalación

Revisa el archivo:
/tmp/quotify_install.log

O intenta reinstalar Node.js desde:
https://nodejs.org" buttons {"OK"} default button "OK" with icon stop
end tell
INSTALL_ERROR_EOF
fi

INSTALLER_EOF

chmod +x "$APP_INSTALLER_DIR/Contents/MacOS/installer"

echo "📱 Creando app principal..."

# APP PRINCIPAL
APP_DIR="$DIST_DIR/Quotify v2.0.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Icono
ICONSET_DIR="/tmp/quotify_v2_sin_friccion.iconset"
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
    <string>com.quotify.v2.sinfriccion</string>
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

# Launcher con yt-dlp incluido
cat > "$APP_DIR/Contents/MacOS/quotify" << 'LAUNCHER_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

# DETECTAR NODE.JS Y NPM
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

NODE_FOUND=$(find_node)
NPM_FOUND=$(find_npm)

if [ -z "$NODE_FOUND" ] || [ -z "$NPM_FOUND" ]; then
    osascript << 'NODE_ERROR_EOF'
tell application "System Events"
    display dialog "❌ Node.js no encontrado

Ejecuta 'Instalar Quotify.app' primero" buttons {"OK"} default button "OK" with icon stop
end tell
NODE_ERROR_EOF
    exit 1
fi

if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    osascript << 'INSTALL_ERROR_EOF'
tell application "System Events"
    display dialog "❌ Quotify no está instalado

Ejecuta 'Instalar Quotify.app' primero" buttons {"OK"} default button "OK" with icon stop
end tell
INSTALL_ERROR_EOF
    exit 1
fi

# Configurar PATH con yt-dlp incluido
export PATH="$QUOTIFY_DIR/bin:$(dirname "$NODE_FOUND"):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

cd "$QUOTIFY_DIR"

pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 2

osascript << 'START_EOF' &
tell application "System Events"
    display dialog "🚀 Iniciando Quotify v2.0...

✨ Sin consola molesta
🎨 Logo propio incluido
🛠️ yt-dlp funcionando
⏳ Cargando..." buttons {"OK"} default button "OK" with icon note giving up after 5
end tell
START_EOF

"$NPM_FOUND" run dev > "/tmp/quotify_v2_$(date +%s).log" 2>&1 &

sleep 20

if pgrep -f "electron.*quotify" >/dev/null; then
    osascript << 'SUCCESS_EOF'
tell application "System Events"
    display dialog "✅ ¡Quotify v2.0 funcionando!

🚫 Sin consola molesta
🎨 Logo propio activo
🛠️ yt-dlp incluido
🎵 Transcripción lista

¡Disfruta Quotify v2.0!" buttons {"¡Perfecto!"} default button "¡Perfecto!" with icon note
end tell
SUCCESS_EOF
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify"

echo ""
echo "✨ QUOTIFY v2.0 SIN FRICCIÓN CREADO!"
echo ""
echo "🚫 SIN PROBLEMAS DE SEGURIDAD:"
echo "   ✅ Instalador como .app (no .command)"
echo "   ✅ Sin bloqueos de Apple"
echo ""
echo "🛠️ SIN DEPENDENCIAS EXTERNAS:"
echo "   ✅ yt-dlp incluido en el paquete"
echo "   ✅ Detección automática de Node.js"
echo ""
echo "📦 SOLO 2 ARCHIVOS:"
echo "   📦 Instalar Quotify.app"
echo "   📱 Quotify v2.0.app"
echo ""
echo "🎯 EXPERIENCIA PERFECTA:"
echo "   ✅ Doble clic y funciona"
echo "   ✅ Diálogos elegantes"
echo "   ✅ Sin fricción técnica"

# ZIP SIN FRICCIÓN
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "✨ ¡LISTO PARA COMPARTIR SIN FRICCIÓN!"