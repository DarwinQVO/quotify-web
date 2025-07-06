#!/bin/bash

echo "✨ Quotify v2.1 - CON INSTALADOR AUTOMÁTICO"
echo "==========================================="

PACKAGE_NAME="Quotify-v2.1-CON-INSTALADOR"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión con instalador para cualquier usuario..."

# Limpiar
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "📋 Copiando proyecto base SIN node_modules..."
cp -r "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp" "$DIST_DIR/"

# Eliminar node_modules para que cada usuario instale el suyo
rm -rf "$DIST_DIR/QuotifyApp/node_modules"
rm -f "$DIST_DIR/QuotifyApp/package-lock.json"

cd "$DIST_DIR"

echo "🔧 Aplicando cambios superficiales..."

# Quitar consola DevTools
sed -i '' 's/mainWindow.webContents.openDevTools();/\/\/ mainWindow.webContents.openDevTools();/' "QuotifyApp/src/main/index.js"

# Agregar icono
sed -i '' '/minHeight: 700,/a\
    icon: path.join(__dirname, "../../public/icon.png"),
' "QuotifyApp/src/main/index.js"

# Copiar icono
cp "/Users/darwinborges/Desktop/Icono Quotify.png" "QuotifyApp/public/icon.png"

echo "🛠️ Agregando yt-dlp incluido..."
mkdir -p "QuotifyApp/bin"
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos -o "QuotifyApp/bin/yt-dlp" --progress-bar
chmod +x "QuotifyApp/bin/yt-dlp"

echo "🔨 Corrigiendo yt-dlp para usar versión incluida..."
sed -i '' "s|const ytdlpPath = '/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp';|const ytdlpPath = path.join(__dirname, '../../bin/yt-dlp');|g" "QuotifyApp/src/main/index.js"

echo "📱 Creando INSTALADOR elegante..."

# INSTALADOR COMO APP
INSTALLER_DIR="$DIST_DIR/1️⃣ Instalar Quotify.app"
mkdir -p "$INSTALLER_DIR/Contents/MacOS"
mkdir -p "$INSTALLER_DIR/Contents/Resources"

# Icono del instalador
ICONSET_DIR="/tmp/quotify_installer.iconset"
mkdir -p "$ICONSET_DIR"
sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$INSTALLER_DIR/Contents/Resources/installer.icns" 2>/dev/null
rm -rf "$ICONSET_DIR"

# Info.plist del instalador
cat > "$INSTALLER_DIR/Contents/Info.plist" << 'INSTALLER_PLIST'
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
    <key>CFBundleVersion</key>
    <string>2.1</string>
    <key>CFBundleIconFile</key>
    <string>installer</string>
</dict>
</plist>
INSTALLER_PLIST

# Script del instalador
cat > "$INSTALLER_DIR/Contents/MacOS/installer" << 'INSTALLER_SCRIPT'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

# Buscar Node.js
find_node() {
    if command -v node >/dev/null 2>&1; then
        echo "$(command -v node)"
        return 0
    fi
    
    for path in "/usr/local/bin/node" "/opt/homebrew/bin/node" "$HOME/.nvm/versions/node/*/bin/node"; do
        for node in $path; do
            if [ -x "$node" ]; then
                echo "$node"
                return 0
            fi
        done
    done
    return 1
}

find_npm() {
    if [ -n "$1" ]; then
        npm_path="${1%/node}/npm"
        if [ -x "$npm_path" ]; then
            echo "$npm_path"
            return 0
        fi
    fi
    if command -v npm >/dev/null 2>&1; then
        echo "$(command -v npm)"
        return 0
    fi
    return 1
}

# Diálogo de bienvenida
osascript << 'WELCOME'
display dialog "🎯 Quotify - Instalador

✨ Sin consola molesta
🎨 Logo propio incluido
🛠️ yt-dlp incluido
🎵 Transcripción funcionando

¿Instalar Quotify?" buttons {"Cancelar", "Instalar"} default button "Instalar" with icon note
if button returned of result is "Cancelar" then
    error number -128
end if
WELCOME

if [ $? -ne 0 ]; then
    exit 0
fi

# Verificar Node.js
NODE_BIN=$(find_node)
NPM_BIN=$(find_npm "$NODE_BIN")

if [ -z "$NODE_BIN" ] || [ -z "$NPM_BIN" ]; then
    osascript << 'NODE_ERROR'
display dialog "❌ Node.js no encontrado

Quotify requiere Node.js para funcionar.

Por favor instálalo desde:
https://nodejs.org

Después ejecuta este instalador otra vez." buttons {"Abrir nodejs.org", "OK"} default button "OK" with icon stop
if button returned of result is "Abrir nodejs.org" then
    do shell script "open https://nodejs.org"
end if
NODE_ERROR
    exit 1
fi

cd "$QUOTIFY_DIR"

# Mostrar progreso
osascript << 'PROGRESS' &
display dialog "📦 Instalando Quotify...

✅ Node.js encontrado
✅ yt-dlp incluido
⏳ Instalando dependencias...

Esto puede tomar 1-2 minutos.
Por favor espera..." buttons {} with icon note giving up after 180
PROGRESS
PROGRESS_PID=$!

# Instalar dependencias
"$NPM_BIN" install > /tmp/quotify_install.log 2>&1
INSTALL_RESULT=$?

# Cerrar diálogo de progreso
kill $PROGRESS_PID 2>/dev/null

if [ $INSTALL_RESULT -eq 0 ]; then
    osascript << 'SUCCESS'
display dialog "✅ ¡Quotify instalado exitosamente!

🎯 Ahora puedes usar:
'2️⃣ Abrir Quotify.app'

✨ Sin consola molesta
🎨 Logo propio incluido
🛠️ yt-dlp funcionando
🎵 Transcripción lista

¡Disfruta Quotify!" buttons {"¡Perfecto!"} default button "¡Perfecto!" with icon note
SUCCESS
else
    osascript << 'ERROR'
display dialog "❌ Error en la instalación

Revisa el archivo de registro:
/tmp/quotify_install.log

Posibles soluciones:
• Verifica tu conexión a internet
• Reinicia e intenta otra vez" buttons {"OK"} default button "OK" with icon stop
ERROR
fi
INSTALLER_SCRIPT

chmod +x "$INSTALLER_DIR/Contents/MacOS/installer"

echo "📱 Creando aplicación principal..."

# APP PRINCIPAL
APP_DIR="$DIST_DIR/2️⃣ Abrir Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Icono principal
ICONSET_DIR="/tmp/quotify_app.iconset"
mkdir -p "$ICONSET_DIR"
sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/quotify.icns" 2>/dev/null
rm -rf "$ICONSET_DIR"

# Info.plist principal
cat > "$APP_DIR/Contents/Info.plist" << 'APP_PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>quotify</string>
    <key>CFBundleIdentifier</key>
    <string>com.quotify.app</string>
    <key>CFBundleName</key>
    <string>Quotify</string>
    <key>CFBundleVersion</key>
    <string>2.1</string>
    <key>CFBundleIconFile</key>
    <string>quotify</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
APP_PLIST

# Launcher principal
cat > "$APP_DIR/Contents/MacOS/quotify" << 'LAUNCHER'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

# Buscar Node.js
find_node() {
    if command -v node >/dev/null 2>&1; then
        echo "$(command -v node)"
        return 0
    fi
    
    for path in "/usr/local/bin/node" "/opt/homebrew/bin/node" "$HOME/.nvm/versions/node/*/bin/node"; do
        for node in $path; do
            if [ -x "$node" ]; then
                echo "$node"
                return 0
            fi
        done
    done
    return 1
}

find_npm() {
    if [ -n "$1" ]; then
        npm_path="${1%/node}/npm"
        if [ -x "$npm_path" ]; then
            echo "$npm_path"
            return 0
        fi
    fi
    if command -v npm >/dev/null 2>&1; then
        echo "$(command -v npm)"
        return 0
    fi
    return 1
}

NODE_BIN=$(find_node)
NPM_BIN=$(find_npm "$NODE_BIN")

if [ -z "$NODE_BIN" ] || [ -z "$NPM_BIN" ]; then
    osascript << 'NODE_ERROR'
display dialog "❌ Node.js no encontrado

Ejecuta primero:
'1️⃣ Instalar Quotify.app'" buttons {"OK"} default button "OK" with icon stop
NODE_ERROR
    exit 1
fi

cd "$QUOTIFY_DIR"

if [ ! -d "node_modules" ]; then
    osascript << 'INSTALL_ERROR'
display dialog "❌ Quotify no está instalado

Ejecuta primero:
'1️⃣ Instalar Quotify.app'" buttons {"OK"} default button "OK" with icon stop
INSTALL_ERROR
    exit 1
fi

# Configurar PATH con yt-dlp incluido
export PATH="$QUOTIFY_DIR/bin:${NODE_BIN%/*}:/usr/local/bin:/usr/bin:/bin"

# Limpiar procesos anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 1

# Mostrar inicio
osascript << 'START' &
display dialog "🚀 Iniciando Quotify...

✨ Sin consola molesta
🎨 Logo propio incluido
🛠️ yt-dlp funcionando
⏳ Cargando aplicación...

Se abrirá automáticamente." buttons {} with icon note giving up after 5
START

# Ejecutar
exec "$NPM_BIN" run dev > /tmp/quotify_run.log 2>&1
LAUNCHER

chmod +x "$APP_DIR/Contents/MacOS/quotify"

echo "📄 Creando instrucciones..."
cat > "$DIST_DIR/INSTRUCCIONES.txt" << 'INSTRUCTIONS'
QUOTIFY v2.1 - CON INSTALADOR
=============================

📋 PASOS:

1. Doble clic en "1️⃣ Instalar Quotify.app"
   (Solo la primera vez)

2. Doble clic en "2️⃣ Abrir Quotify.app"
   (Para usar Quotify)

✅ INCLUYE:
• yt-dlp para YouTube
• Sin consola molesta
• Logo de Quotify
• Transcripción funcionando

🔧 REQUISITO:
Node.js desde nodejs.org

📝 LOGS:
/tmp/quotify_*.log
INSTRUCTIONS

echo "🔓 Removiendo restricciones..."
xattr -cr "$DIST_DIR" 2>/dev/null || true

echo ""
echo "✨ QUOTIFY CON INSTALADOR CREADO!"
echo ""
echo "📦 PARA EL USUARIO:"
echo "   1️⃣ Instalar Quotify.app (una vez)"
echo "   2️⃣ Abrir Quotify.app (siempre)"
echo "   📄 INSTRUCCIONES.txt"
echo ""
echo "✅ CARACTERÍSTICAS:"
echo "   • Instalador automático"
echo "   • Sin node_modules empaquetado"
echo "   • Compatible con cualquier Mac"
echo "   • yt-dlp incluido"
echo ""

# Crear ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -x "*.DS_Store" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🚀 ¡LISTO PARA COMPARTIR!"
echo "El usuario instalará sus propias dependencias compatibles"