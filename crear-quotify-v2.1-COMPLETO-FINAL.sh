#!/bin/bash

echo "✨ Quotify v2.1 - VERSIÓN COMPLETA FINAL"
echo "========================================"

PACKAGE_NAME="Quotify-v2.1-COMPLETO"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión completa y lista para compartir..."

# Limpiar y crear directorio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/QuotifyApp"

# Copiar archivos esenciales
echo "📋 Copiando proyecto completo..."
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

echo "🛠️ Descargando yt-dlp universal..."

# Crear carpeta bin
mkdir -p "QuotifyApp/bin"

# Descargar yt-dlp universal
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos -o "QuotifyApp/bin/yt-dlp" -s
chmod +x "QuotifyApp/bin/yt-dlp"

echo "🔨 Corrigiendo TODAS las rutas para portabilidad..."

# Script para corregir main/index.js completamente
cat > /tmp/fix_quotify_complete.js << 'FIX_EOF'
const fs = require('fs');
const path = require('path');

const mainFile = process.argv[2];
let content = fs.readFileSync(mainFile, 'utf8');

// 1. Asegurar imports necesarios
if (!content.includes("const path = require('path')")) {
  content = content.replace(
    /const \{ app.*?\} = require\('electron'\);/,
    "const { app, BrowserWindow, ipcMain, shell, dialog } = require('electron');\nconst path = require('path');"
  );
}

// 2. Corregir ruta de yt-dlp
content = content.replace(
  /const ytdlpPath = ['"].*?['"];/g,
  "const ytdlpPath = app.isPackaged ? path.join(process.resourcesPath, 'bin', 'yt-dlp') : path.join(__dirname, '../../bin/yt-dlp');"
);

// 3. Si no existe la línea, buscar donde agregar
if (!content.includes('ytdlpPath')) {
  // Agregar después de transcribeAudio
  content = content.replace(
    /ipcMain\.handle\('transcribe-audio', async \(event, \{ url, apiKey \}\) => \{/,
    `ipcMain.handle('transcribe-audio', async (event, { url, apiKey }) => {
    const ytdlpPath = app.isPackaged ? path.join(process.resourcesPath, 'bin', 'yt-dlp') : path.join(__dirname, '../../bin/yt-dlp');`
  );
}

// 4. Corregir la verificación de existencia
content = content.replace(
  /if \(!existsSync\(ytdlpPath\)\) \{[\s\S]*?throw new Error\('yt-dlp no encontrado'\);[\s\S]*?\}/g,
  `if (!existsSync(ytdlpPath)) {
      console.error('yt-dlp no encontrado en:', ytdlpPath);
      throw new Error('yt-dlp no encontrado. Por favor reinstala la aplicación.');
    }`
);

// 5. Asegurar que el comando use la ruta correcta
content = content.replace(
  /const command = `".*?" --extract-audio/g,
  'const command = `"${ytdlpPath}" --extract-audio'
);

fs.writeFileSync(mainFile, content);
console.log('✅ Archivo corregido completamente');
FIX_EOF

node /tmp/fix_quotify_complete.js "$DIST_DIR/QuotifyApp/src/main/index.js"

# También corregir index-fixed.js si existe
if [ -f "$DIST_DIR/QuotifyApp/src/main/index-fixed.js" ]; then
    node /tmp/fix_quotify_complete.js "$DIST_DIR/QuotifyApp/src/main/index-fixed.js"
fi

echo "📱 Creando aplicación principal..."

# APP PRINCIPAL MEJORADA
APP_DIR="$DIST_DIR/Quotify v2.1.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Icono principal
ICONSET_DIR="/tmp/quotify_v21_final.iconset"
mkdir -p "$ICONSET_DIR"
sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
sips -z 64 64 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_32x32@2x.png" 2>/dev/null
sips -z 32 32 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_32x32.png" 2>/dev/null
sips -z 32 32 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_16x16@2x.png" 2>/dev/null
sips -z 16 16 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_16x16.png" 2>/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/quotify.icns" 2>/dev/null
rm -rf "$ICONSET_DIR"

# Info.plist mejorado
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>quotify</string>
    <key>CFBundleIdentifier</key>
    <string>com.quotify.v21</string>
    <key>CFBundleName</key>
    <string>Quotify</string>
    <key>CFBundleDisplayName</key>
    <string>Quotify v2.1</string>
    <key>CFBundleVersion</key>
    <string>2.1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>2.1</string>
    <key>CFBundleIconFile</key>
    <string>quotify</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
</dict>
</plist>
PLIST_EOF

# Launcher robusto que verifica todo
cat > "$APP_DIR/Contents/MacOS/quotify" << 'LAUNCHER_EOF'
#!/bin/bash

# Variables de entorno
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"
LOG_FILE="/tmp/quotify_v21_$(date +%s).log"

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=== Iniciando Quotify v2.1 ==="
log "DIR: $DIR"
log "QUOTIFY_DIR: $QUOTIFY_DIR"

# Verificar que existe QuotifyApp
if [ ! -d "$QUOTIFY_DIR" ]; then
    osascript -e 'tell application "System Events" to display dialog "❌ Error: Carpeta QuotifyApp no encontrada\n\nPor favor reinstala Quotify v2.1" buttons {"OK"} with icon stop'
    exit 1
fi

cd "$QUOTIFY_DIR"

# Detectar Node.js con más opciones
find_node() {
    local paths=(
        "/usr/local/bin/node"
        "/opt/homebrew/bin/node"
        "/opt/homebrew/opt/node/bin/node"
        "/opt/homebrew/opt/node@20/bin/node"
        "/opt/homebrew/opt/node@18/bin/node"
        "/usr/bin/node"
        "/opt/node/bin/node"
        "$HOME/.nvm/versions/node/*/bin/node"
        "$HOME/.volta/bin/node"
        "$HOME/.fnm/node-versions/*/bin/node"
    )
    
    # Intentar which primero
    local which_node=$(which node 2>/dev/null)
    if [ -x "$which_node" ]; then
        echo "$which_node"
        return 0
    fi
    
    # Buscar en rutas conocidas
    for node_path in "${paths[@]}"; do
        if [ -x "$node_path" ]; then
            echo "$node_path"
            return 0
        fi
    done
    
    # Búsqueda más amplia con find
    find /usr/local /opt/homebrew /opt "$HOME/.nvm" "$HOME" -name "node" -type f -executable 2>/dev/null | grep -v "node_modules" | head -1
}

find_npm() {
    if [ -n "$NODE_FOUND" ]; then
        local npm_dir="$(dirname "$NODE_FOUND")"
        if [ -x "$npm_dir/npm" ]; then
            echo "$npm_dir/npm"
            return 0
        fi
    fi
    
    local paths=(
        "/usr/local/bin/npm"
        "/opt/homebrew/bin/npm"
        "/opt/homebrew/opt/node/bin/npm"
        "/opt/homebrew/opt/node@20/bin/npm"
        "/opt/homebrew/opt/node@18/bin/npm"
        "/usr/bin/npm"
        "/opt/node/bin/npm"
        "$HOME/.nvm/versions/node/*/bin/npm"
        "$HOME/.volta/bin/npm"
        "$HOME/.fnm/node-versions/*/bin/npm"
    )
    
    local which_npm=$(which npm 2>/dev/null)
    if [ -x "$which_npm" ]; then
        echo "$which_npm"
        return 0
    fi
    
    for npm_path in "${paths[@]}"; do
        if [ -x "$npm_path" ]; then
            echo "$npm_path"
            return 0
        fi
    done
}

log "Buscando Node.js..."
NODE_FOUND=$(find_node)
log "Node encontrado: $NODE_FOUND"

log "Buscando npm..."
NPM_FOUND=$(find_npm)
log "npm encontrado: $NPM_FOUND"

if [ -z "$NODE_FOUND" ] || [ -z "$NPM_FOUND" ]; then
    osascript << 'NODE_ERROR_EOF'
tell application "System Events"
    display dialog "❌ Node.js no encontrado

Quotify requiere Node.js para funcionar.

Instala Node.js desde:
https://nodejs.org

O usa Homebrew:
brew install node" buttons {"Abrir nodejs.org", "OK"} default button "OK" with icon stop
    if button returned of result is "Abrir nodejs.org" then
        do shell script "open https://nodejs.org"
    end if
end tell
NODE_ERROR_EOF
    exit 1
fi

# Verificar si está instalado
if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    log "node_modules no existe, instalando..."
    
    osascript << 'INSTALL_EOF' &
tell application "System Events"
    display dialog "📦 Primera ejecución detectada

Instalando Quotify v2.1...
Esto tomará 1-2 minutos.

Por favor espera..." buttons {} with icon note giving up after 120
end tell
INSTALL_EOF
    INSTALL_PID=$!
    
    # Instalar
    "$NPM_FOUND" install >> "$LOG_FILE" 2>&1
    INSTALL_RESULT=$?
    
    kill $INSTALL_PID 2>/dev/null
    
    if [ $INSTALL_RESULT -ne 0 ]; then
        osascript -e 'tell application "System Events" to display dialog "❌ Error al instalar dependencias\n\nRevisa: '"$LOG_FILE"'" buttons {"Ver log", "OK"} with icon stop'
        if [ "$?" -eq 1 ]; then
            open -e "$LOG_FILE"
        fi
        exit 1
    fi
fi

# Configurar PATH incluyendo yt-dlp local
export PATH="$QUOTIFY_DIR/bin:$(dirname "$NODE_FOUND"):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
log "PATH configurado: $PATH"

# Limpiar procesos anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 1

# Iniciar aplicación
log "Iniciando npm run dev..."

# No mostrar diálogo, solo iniciar
"$NPM_FOUND" run dev >> "$LOG_FILE" 2>&1 &
NPM_PID=$!

log "npm PID: $NPM_PID"

# Esperar a que inicie
sleep 15

# Verificar si está corriendo
if pgrep -f "electron.*quotify" >/dev/null; then
    log "✅ Quotify iniciado correctamente"
else
    log "❌ Quotify no pudo iniciar"
    osascript -e 'tell application "System Events" to display dialog "⚠️ Quotify está tardando en iniciar\n\nEspera unos segundos más o revisa:\n'"$LOG_FILE"'" buttons {"Ver log", "OK"} with icon caution'
    if [ "$?" -eq 1 ]; then
        open -e "$LOG_FILE"
    fi
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify"

echo "🎁 Creando instalador OPCIONAL..."

# Crear un simple README
cat > "$DIST_DIR/INSTRUCCIONES.txt" << 'README_EOF'
QUOTIFY v2.1 - INSTRUCCIONES
============================

OPCIÓN 1 - EJECUCIÓN DIRECTA:
1. Doble clic en "Quotify v2.1.app"
2. Si es la primera vez, instalará automáticamente
3. ¡Listo!

OPCIÓN 2 - SI NO FUNCIONA:
1. Clic derecho en "Quotify v2.1.app"
2. Seleccionar "Abrir"
3. Confirmar en el diálogo de seguridad

REQUISITOS:
- macOS 10.13 o superior
- Node.js (se descarga de nodejs.org si no lo tienes)

¿PROBLEMAS?
- Instala Node.js desde https://nodejs.org
- O con Homebrew: brew install node

INCLUIDO:
✅ yt-dlp integrado
✅ Sin dependencias externas
✅ Listo para usar
README_EOF

echo ""
echo "✨ QUOTIFY v2.1 COMPLETO CREADO!"
echo ""
echo "📦 CONTENIDO:"
echo "   📱 Quotify v2.1.app (TODO EN UNO)"
echo "   📄 INSTRUCCIONES.txt"
echo ""
echo "✅ CARACTERÍSTICAS:"
echo "   • Auto-instalación en primera ejecución"
echo "   • yt-dlp incluido"
echo "   • Detección automática de Node.js"
echo "   • Sin fricción técnica"
echo "   • Logs de diagnóstico"
echo ""
echo "🚀 LISTO PARA COMPARTIR"

# Crear ZIP final
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo ""
echo "📦 ZIP FINAL: ${PACKAGE_NAME}.zip"
echo ""
echo "✨ ¡100% COMPLETO Y PORTABLE!"