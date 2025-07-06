#!/bin/bash

echo "✨ Quotify v2.1 - VERSIÓN MEJORADA (Detección robusta de Node.js)"
echo "================================================================="

PACKAGE_NAME="Quotify-v2.1-MEJORADO"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión con detección robusta de Node.js..."

# Limpiar
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "📋 Copiando proyecto base..."
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

echo "📱 Creando instalador mejorado..."

# INSTALADOR MEJORADO
INSTALLER_DIR="$DIST_DIR/Instalar Quotify.app"
mkdir -p "$INSTALLER_DIR/Contents/MacOS"
mkdir -p "$INSTALLER_DIR/Contents/Resources"

# Icono
ICONSET_DIR="/tmp/quotify_mejorado.iconset"
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

# Instalador con detección robusta
cat > "$INSTALLER_DIR/Contents/MacOS/installer" << 'INSTALLER_SCRIPT'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

# Función de detección EXHAUSTIVA de Node.js
find_node_exhaustive() {
    echo "Buscando Node.js..." > /tmp/quotify_node_search.log
    
    # Lista completa de ubicaciones posibles
    local node_locations=(
        "/usr/local/bin/node"
        "/opt/homebrew/bin/node"
        "/opt/homebrew/opt/node/bin/node"
        "/opt/homebrew/opt/node@20/bin/node"
        "/opt/homebrew/opt/node@18/bin/node"
        "/opt/homebrew/opt/node@16/bin/node"
        "/usr/bin/node"
        "/opt/local/bin/node"
        "/opt/node/bin/node"
        "$HOME/.nvm/versions/node/*/bin/node"
        "$HOME/.volta/bin/node"
        "$HOME/.fnm/node-versions/*/installation/bin/node"
        "$HOME/n/bin/node"
        "$HOME/.local/bin/node"
        "$HOME/bin/node"
        "/Applications/Node.app/Contents/MacOS/node"
    )
    
    # Primero intentar which con PATH completo
    export PATH="/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/opt/node/bin:/usr/bin:/bin:$HOME/.nvm/versions/node/*/bin:$PATH"
    
    if command -v node >/dev/null 2>&1; then
        local found_node=$(command -v node)
        echo "Node encontrado con which: $found_node" >> /tmp/quotify_node_search.log
        echo "$found_node"
        return 0
    fi
    
    # Buscar en cada ubicación específica
    for pattern in "${node_locations[@]}"; do
        echo "Probando: $pattern" >> /tmp/quotify_node_search.log
        for node_path in $pattern; do
            if [ -x "$node_path" ]; then
                echo "Node encontrado en: $node_path" >> /tmp/quotify_node_search.log
                echo "$node_path"
                return 0
            fi
        done
    done
    
    # Búsqueda con find como último recurso
    echo "Búsqueda con find..." >> /tmp/quotify_node_search.log
    local found=$(find /usr/local /opt /Applications "$HOME" -name "node" -type f -perm +111 2>/dev/null | grep -v node_modules | grep -v ".Trash" | head -1)
    if [ -n "$found" ] && [ -x "$found" ]; then
        echo "Node encontrado con find: $found" >> /tmp/quotify_node_search.log
        echo "$found"
        return 0
    fi
    
    echo "Node NO encontrado" >> /tmp/quotify_node_search.log
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
    
    # Buscar npm independientemente
    export PATH="/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/opt/node/bin:/usr/bin:/bin:$HOME/.nvm/versions/node/*/bin:$PATH"
    
    if command -v npm >/dev/null 2>&1; then
        echo "$(command -v npm)"
        return 0
    fi
    
    return 1
}

# Diálogo de bienvenida
osascript << 'WELCOME'
display dialog "🎯 Quotify - Instalador Mejorado

✨ Detección robusta de Node.js
🛠️ yt-dlp incluido
🎵 Transcripción funcionando

¿Continuar?" buttons {"Cancelar", "Instalar"} default button "Instalar" with icon note
if button returned of result is "Cancelar" then
    error number -128
end if
WELCOME

if [ $? -ne 0 ]; then
    exit 0
fi

# Buscar Node.js exhaustivamente
echo "Iniciando búsqueda exhaustiva de Node.js..." > /tmp/quotify_install.log

NODE_BIN=$(find_node_exhaustive)
NPM_BIN=$(find_npm_exhaustive "$NODE_BIN")

if [ -z "$NODE_BIN" ] || [ -z "$NPM_BIN" ]; then
    # Mostrar información de diagnóstico
    cat /tmp/quotify_node_search.log >> /tmp/quotify_install.log
    
    osascript << 'NODE_ERROR'
display dialog "❌ Node.js no encontrado

Quotify requiere Node.js para funcionar.

Opciones:
1. Instalar desde: nodejs.org
2. Instalar con Homebrew: brew install node

Logs en: /tmp/quotify_node_search.log" buttons {"Abrir nodejs.org", "Ver logs", "OK"} default button "OK" with icon stop
set result to button returned of result
if result is "Abrir nodejs.org" then
    do shell script "open https://nodejs.org"
else if result is "Ver logs" then
    do shell script "open -e /tmp/quotify_node_search.log"
end if
NODE_ERROR
    exit 1
fi

echo "Node encontrado: $NODE_BIN" >> /tmp/quotify_install.log
echo "npm encontrado: $NPM_BIN" >> /tmp/quotify_install.log

cd "$QUOTIFY_DIR"

# Verificar versiones
NODE_VERSION=$("$NODE_BIN" --version 2>&1)
NPM_VERSION=$("$NPM_BIN" --version 2>&1)

echo "Node version: $NODE_VERSION" >> /tmp/quotify_install.log
echo "npm version: $NPM_VERSION" >> /tmp/quotify_install.log

# Mostrar progreso
osascript << 'PROGRESS' &
display dialog "📦 Instalando Quotify...

✅ Node.js encontrado
✅ yt-dlp incluido
⏳ Instalando dependencias...

Versión Node: '"$NODE_VERSION"'
Esto puede tomar 1-3 minutos." buttons {} with icon note giving up after 300
PROGRESS
PROGRESS_PID=$!

# Configurar PATH para la instalación
export PATH="$(dirname "$NODE_BIN"):$(dirname "$NPM_BIN"):/usr/local/bin:/usr/bin:/bin"

# Instalar con el Node.js encontrado
echo "Ejecutando: $NPM_BIN install" >> /tmp/quotify_install.log
"$NPM_BIN" install >> /tmp/quotify_install.log 2>&1
INSTALL_RESULT=$?

# Cerrar diálogo
kill $PROGRESS_PID 2>/dev/null

echo "Resultado instalación: $INSTALL_RESULT" >> /tmp/quotify_install.log

if [ $INSTALL_RESULT -eq 0 ]; then
    osascript << 'SUCCESS'
display dialog "✅ ¡Quotify instalado exitosamente!

🎯 Ahora puedes usar:
'Quotify.app'

✨ Sin consola molesta
🎨 Logo propio incluido
🛠️ yt-dlp funcionando
🎵 Transcripción lista

¡Disfruta Quotify!" buttons {"¡Perfecto!"} default button "¡Perfecto!" with icon note
SUCCESS
else
    osascript << 'ERROR'
display dialog "❌ Error en la instalación

Revisa los logs en:
/tmp/quotify_install.log

Información de Node.js:
'"$NODE_BIN"'
'"$NODE_VERSION"'" buttons {"Ver logs", "OK"} default button "OK" with icon stop
if button returned of result is "Ver logs" then
    do shell script "open -e /tmp/quotify_install.log"
end if
ERROR
fi
INSTALLER_SCRIPT

chmod +x "$INSTALLER_DIR/Contents/MacOS/installer"

echo "📱 Creando aplicación principal..."

# APP PRINCIPAL
APP_DIR="$DIST_DIR/Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Icono
ICONSET_DIR="/tmp/quotify_app_mejorado.iconset"
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
    <string>com.quotify.mejorado</string>
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

# Launcher con misma detección robusta
cat > "$APP_DIR/Contents/MacOS/quotify" << 'LAUNCHER'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

# Misma función de detección exhaustiva
find_node_exhaustive() {
    local node_locations=(
        "/usr/local/bin/node"
        "/opt/homebrew/bin/node"
        "/opt/homebrew/opt/node/bin/node"
        "/usr/bin/node"
        "$HOME/.nvm/versions/node/*/bin/node"
        "$HOME/.volta/bin/node"
        "$HOME/.fnm/node-versions/*/installation/bin/node"
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
    
    export PATH="/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/opt/node/bin:/usr/bin:/bin:$HOME/.nvm/versions/node/*/bin:$PATH"
    
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

Ejecuta primero:
'Instalar Quotify.app'" buttons {"OK"} default button "OK" with icon stop
NODE_ERROR
    exit 1
fi

cd "$QUOTIFY_DIR"

if [ ! -d "node_modules" ]; then
    osascript << 'INSTALL_ERROR'
display dialog "❌ Quotify no está instalado

Ejecuta primero:
'Instalar Quotify.app'" buttons {"OK"} default button "OK" with icon stop
INSTALL_ERROR
    exit 1
fi

# Configurar PATH completo
export PATH="$QUOTIFY_DIR/bin:$(dirname "$NODE_BIN"):$(dirname "$NPM_BIN"):/usr/local/bin:/usr/bin:/bin"

# Limpiar procesos
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 1

# Ejecutar
exec "$NPM_BIN" run dev > /tmp/quotify_run.log 2>&1
LAUNCHER

chmod +x "$APP_DIR/Contents/MacOS/quotify"

echo "📄 Creando instrucciones..."
cat > "$DIST_DIR/INSTRUCCIONES.txt" << 'INSTRUCTIONS'
QUOTIFY v2.1 - VERSIÓN MEJORADA
===============================

📋 PASOS:

1. Doble clic en "Instalar Quotify.app"
   (Solo la primera vez)

2. Doble clic en "Quotify.app"
   (Para usar Quotify)

✅ MEJORADO:
• Detección robusta de Node.js
• Mejores mensajes de error
• Logs detallados
• yt-dlp incluido

🔧 REQUISITO:
Node.js desde nodejs.org
o: brew install node

📝 LOGS:
/tmp/quotify_*.log
INSTRUCTIONS

echo "🔓 Removiendo restricciones..."
xattr -cr "$DIST_DIR" 2>/dev/null || true

echo ""
echo "✨ QUOTIFY MEJORADO CREADO!"
echo ""
echo "🔧 MEJORAS:"
echo "   • Detección exhaustiva de Node.js"
echo "   • Logs detallados para diagnóstico"
echo "   • Mejor manejo de errores"
echo "   • PATH configurado correctamente"
echo ""

# ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -x "*.DS_Store" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🚀 ¡CON DETECCIÓN ROBUSTA DE NODE.JS!"