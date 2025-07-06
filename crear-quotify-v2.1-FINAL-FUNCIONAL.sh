#!/bin/bash

echo "✨ Quotify v2.1 - VERSIÓN FINAL FUNCIONAL"
echo "========================================"

PACKAGE_NAME="Quotify-v2.1-FINAL-FUNCIONAL"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión final que limpia puertos correctamente..."

# Limpiar
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "📋 Copiando proyecto..."
cp -r "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp" "$DIST_DIR/"

# Eliminar node_modules para instalación fresca
rm -rf "$DIST_DIR/QuotifyApp/node_modules"
rm -f "$DIST_DIR/QuotifyApp/package-lock.json"

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

echo "🛠️ Agregando yt-dlp..."
mkdir -p "QuotifyApp/bin"
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos -o "QuotifyApp/bin/yt-dlp" --progress-bar
chmod +x "QuotifyApp/bin/yt-dlp"

echo "🔨 Corrigiendo yt-dlp..."
sed -i '' "s|const ytdlpPath = '/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp';|const ytdlpPath = path.join(__dirname, '../../bin/yt-dlp');|g" "QuotifyApp/src/main/index.js"

echo "📱 Creando instalador..."

# INSTALADOR
INSTALLER_DIR="$DIST_DIR/Instalar Quotify.app"
mkdir -p "$INSTALLER_DIR/Contents/MacOS"
mkdir -p "$INSTALLER_DIR/Contents/Resources"

# Icono
ICONSET_DIR="/tmp/quotify_final_installer.iconset"
mkdir -p "$ICONSET_DIR"
sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$INSTALLER_DIR/Contents/Resources/installer.icns" 2>/dev/null
rm -rf "$ICONSET_DIR"

# Info.plist
cat > "$INSTALLER_DIR/Contents/Info.plist" << 'INSTALLER_PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>installer</string>
    <key>CFBundleIdentifier</key>
    <string>com.quotify.installer.final</string>
    <key>CFBundleName</key>
    <string>Instalar Quotify</string>
    <key>CFBundleVersion</key>
    <string>2.1</string>
    <key>CFBundleIconFile</key>
    <string>installer</string>
</dict>
</plist>
INSTALLER_PLIST

# Script instalador (igual que antes, funciona bien)
cat > "$INSTALLER_DIR/Contents/MacOS/installer" << 'INSTALLER_SCRIPT'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

find_node_exhaustive() {
    local node_locations=(
        "/usr/local/bin/node"
        "/opt/homebrew/bin/node"
        "/opt/homebrew/opt/node/bin/node"
        "/usr/bin/node"
        "$HOME/.nvm/versions/node/*/bin/node"
        "$HOME/.volta/bin/node"
    )
    
    export PATH="/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/opt/node/bin:/usr/bin:/bin:$HOME/.nvm/versions/node/*/bin:$PATH"
    
    if command -v node >/dev/null 2>&1; then
        echo "$(command -v node)"
        return 0
    fi
    
    for pattern in "${node_locations[@]}"; do
        for node_path in $pattern; do
            if [ -x "$node_path" ]; then
                echo "$node_path"
                return 0
            fi
        done
    done
    
    return 1
}

find_npm_exhaustive() {
    local node_path="$1"
    
    if [ -n "$node_path" ]; then
        local npm_path="${node_path%/node}/npm"
        if [ -x "$npm_path" ]; then
            echo "$npm_path"
            return 0
        fi
    fi
    
    export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$HOME/.nvm/versions/node/*/bin:$PATH"
    
    if command -v npm >/dev/null 2>&1; then
        echo "$(command -v npm)"
        return 0
    fi
    
    return 1
}

osascript << 'WELCOME'
display dialog "🎯 Quotify - Instalador

✨ Sin consola molesta
🎨 Logo propio incluido
🛠️ yt-dlp incluido

¿Instalar?" buttons {"Cancelar", "Instalar"} default button "Instalar" with icon note
if button returned of result is "Cancelar" then
    error number -128
end if
WELCOME

if [ $? -ne 0 ]; then
    exit 0
fi

NODE_BIN=$(find_node_exhaustive)
NPM_BIN=$(find_npm_exhaustive "$NODE_BIN")

if [ -z "$NODE_BIN" ] || [ -z "$NPM_BIN" ]; then
    osascript << 'NODE_ERROR'
display dialog "❌ Node.js no encontrado

Instala desde: nodejs.org" buttons {"Abrir nodejs.org", "OK"} default button "OK" with icon stop
if button returned of result is "Abrir nodejs.org" then
    do shell script "open https://nodejs.org"
end if
NODE_ERROR
    exit 1
fi

cd "$QUOTIFY_DIR"

osascript << 'PROGRESS' &
display dialog "📦 Instalando Quotify...

⏳ Instalando dependencias...
Esto puede tomar 1-2 minutos." buttons {} with icon note giving up after 180
PROGRESS
PROGRESS_PID=$!

export PATH="$(dirname "$NODE_BIN"):$(dirname "$NPM_BIN"):/usr/local/bin:/usr/bin:/bin"

"$NPM_BIN" install > /tmp/quotify_install_final.log 2>&1
INSTALL_RESULT=$?

kill $PROGRESS_PID 2>/dev/null

if [ $INSTALL_RESULT -eq 0 ]; then
    osascript << 'SUCCESS'
display dialog "✅ ¡Quotify instalado exitosamente!

🎯 Ahora usa: Quotify.app

✨ Todo listo para funcionar!" buttons {"¡Perfecto!"} default button "¡Perfecto!" with icon note
SUCCESS
else
    osascript << 'ERROR'
display dialog "❌ Error en la instalación

Revisa: /tmp/quotify_install_final.log" buttons {"OK"} default button "OK" with icon stop
ERROR
fi
INSTALLER_SCRIPT

chmod +x "$INSTALLER_DIR/Contents/MacOS/installer"

echo "📱 Creando aplicación principal con limpieza ROBUSTA..."

APP_DIR="$DIST_DIR/Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Icono
ICONSET_DIR="/tmp/quotify_final_app.iconset"
mkdir -p "$ICONSET_DIR"
sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/quotify.icns" 2>/dev/null
rm -rf "$ICONSET_DIR"

# Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'APP_PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>quotify</string>
    <key>CFBundleIdentifier</key>
    <string>com.quotify.final</string>
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

# Launcher con LIMPIEZA AGRESIVA
cat > "$APP_DIR/Contents/MacOS/quotify" << 'LAUNCHER'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

find_node_exhaustive() {
    local node_locations=(
        "/usr/local/bin/node"
        "/opt/homebrew/bin/node"
        "/opt/homebrew/opt/node/bin/node"
        "/usr/bin/node"
        "$HOME/.nvm/versions/node/*/bin/node"
        "$HOME/.volta/bin/node"
    )
    
    export PATH="/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/opt/node/bin:/usr/bin:/bin:$HOME/.nvm/versions/node/*/bin:$PATH"
    
    if command -v node >/dev/null 2>&1; then
        echo "$(command -v node)"
        return 0
    fi
    
    for pattern in "${node_locations[@]}"; do
        for node_path in $pattern; do
            if [ -x "$node_path" ]; then
                echo "$node_path"
                return 0
            fi
        done
    done
    
    return 1
}

find_npm_exhaustive() {
    local node_path="$1"
    
    if [ -n "$node_path" ]; then
        local npm_path="${node_path%/node}/npm"
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

NODE_BIN=$(find_node_exhaustive)
NPM_BIN=$(find_npm_exhaustive "$NODE_BIN")

if [ -z "$NODE_BIN" ] || [ -z "$NPM_BIN" ]; then
    osascript << 'NODE_ERROR'
display dialog "❌ Node.js no encontrado

Ejecuta primero: Instalar Quotify.app" buttons {"OK"} default button "OK" with icon stop
NODE_ERROR
    exit 1
fi

cd "$QUOTIFY_DIR"

if [ ! -d "node_modules" ]; then
    osascript << 'INSTALL_ERROR'
display dialog "❌ Quotify no está instalado

Ejecuta primero: Instalar Quotify.app" buttons {"OK"} default button "OK" with icon stop
INSTALL_ERROR
    exit 1
fi

export PATH="$QUOTIFY_DIR/bin:$(dirname "$NODE_BIN"):$(dirname "$NPM_BIN"):/usr/local/bin:/usr/bin:/bin"

echo "=== Limpieza agresiva $(date) ===" > /tmp/quotify_cleanup.log

# LIMPIEZA AGRESIVA DE PROCESOS Y PUERTOS
echo "Matando procesos Electron..." >> /tmp/quotify_cleanup.log
pkill -f "electron" >> /tmp/quotify_cleanup.log 2>&1

echo "Matando procesos npm..." >> /tmp/quotify_cleanup.log  
pkill -f "npm.*dev" >> /tmp/quotify_cleanup.log 2>&1

echo "Matando procesos vite..." >> /tmp/quotify_cleanup.log
pkill -f "vite" >> /tmp/quotify_cleanup.log 2>&1

echo "Matando procesos concurrently..." >> /tmp/quotify_cleanup.log
pkill -f "concurrently" >> /tmp/quotify_cleanup.log 2>&1

echo "Matando procesos quotify..." >> /tmp/quotify_cleanup.log
pkill -f "quotify" >> /tmp/quotify_cleanup.log 2>&1

echo "Liberando puerto 5173..." >> /tmp/quotify_cleanup.log
lsof -ti:5173 | xargs kill -9 >> /tmp/quotify_cleanup.log 2>&1

echo "Esperando limpieza..." >> /tmp/quotify_cleanup.log
sleep 3

echo "Verificando puerto 5173..." >> /tmp/quotify_cleanup.log
if lsof -i:5173 >> /tmp/quotify_cleanup.log 2>&1; then
    echo "Puerto 5173 AÚN ocupado, forzando..." >> /tmp/quotify_cleanup.log
    lsof -ti:5173 | xargs kill -9 >> /tmp/quotify_cleanup.log 2>&1
    sleep 2
fi

echo "Puerto liberado, iniciando..." >> /tmp/quotify_cleanup.log

# Mostrar inicio
osascript << 'START' &
display dialog "🚀 Iniciando Quotify...

✨ Sin consola molesta
🎨 Logo propio incluido
🛠️ yt-dlp funcionando

Se abrirá automáticamente." buttons {} with icon note giving up after 5
START

# Ejecutar con logging detallado
echo "Ejecutando: $NPM_BIN run dev" >> /tmp/quotify_cleanup.log
exec "$NPM_BIN" run dev > /tmp/quotify_final_run.log 2>&1
LAUNCHER

chmod +x "$APP_DIR/Contents/MacOS/quotify"

echo "📄 Creando instrucciones..."
cat > "$DIST_DIR/COMO-USAR.txt" << 'INSTRUCTIONS'
QUOTIFY v2.1 - VERSIÓN FINAL
============================

📋 PASOS:

1. Doble clic en "Instalar Quotify.app"
   (Solo la primera vez)

2. Doble clic en "Quotify.app"
   (Para usar Quotify)

✅ ARREGLADO:
• Limpieza agresiva de puertos
• Detección robusta de Node.js
• yt-dlp incluido
• Sin consola molesta

🔧 REQUISITO:
Node.js desde nodejs.org

📝 LOGS:
/tmp/quotify_*.log
INSTRUCTIONS

echo "🔓 Removiendo restricciones..."
xattr -cr "$DIST_DIR" 2>/dev/null || true

echo ""
echo "✨ QUOTIFY FINAL FUNCIONAL CREADO!"
echo ""
echo "🔧 ARREGLADO:"
echo "   • Limpieza agresiva de puertos"
echo "   • Puerto 5173 siempre libre"
echo "   • Detección robusta de Node.js"
echo "   • Logs detallados"
echo ""

# ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -x "*.DS_Store" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🚀 ¡VERSIÓN FINAL QUE DEBERÍA FUNCIONAR!"