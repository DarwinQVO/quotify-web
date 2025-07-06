#!/bin/bash

echo "✨ Quotify v2.1 - VERSIÓN UNIVERSAL COMPLETA"
echo "==========================================="

PACKAGE_NAME="Quotify-v2.1-UNIVERSAL"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión universal que funciona en CUALQUIER Mac..."

# Limpiar y crear directorio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/QuotifyApp"

# Copiar proyecto completo
echo "📋 Copiando proyecto..."
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

echo "🔧 Aplicando cambios..."

# Quitar consola
sed -i '' 's/mainWindow.webContents.openDevTools();/\/\/ mainWindow.webContents.openDevTools();/' "QuotifyApp/src/main/index.js"

# Agregar icono
sed -i '' '/minHeight: 700,/a\
    icon: path.join(__dirname, "../../public/icon.png"),
' "QuotifyApp/src/main/index.js"

# Copiar icono
cp "/Users/darwinborges/Desktop/Icono Quotify.png" "QuotifyApp/public/icon.png"

echo "🛠️ Incluyendo yt-dlp..."

mkdir -p "QuotifyApp/bin"
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos -o "QuotifyApp/bin/yt-dlp" -s
chmod +x "QuotifyApp/bin/yt-dlp"

echo "📦 Instalando dependencias localmente..."

# Instalar node_modules AHORA, no después
cd "$DIST_DIR/QuotifyApp"

# Usar el Node.js que sabemos que funciona
NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

if [ -x "$NODE_PATH" ] && [ -x "$NPM_PATH" ]; then
    echo "Usando Node.js local para instalar..."
    "$NPM_PATH" install --production
else
    echo "Usando Node.js del sistema..."
    npm install --production
fi

cd "$DIST_DIR"

echo "🔨 Corrigiendo rutas de yt-dlp..."

# Corregir main/index.js
sed -i '' "s|/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp|path.join(__dirname, '../../bin/yt-dlp')|g" "QuotifyApp/src/main/index.js"

# Si la línea no existe, agregar después de los requires
if ! grep -q "ytdlpPath" "QuotifyApp/src/main/index.js"; then
    sed -i '' "/const path = require('path');/a\\
const ytdlpPath = path.join(__dirname, '../../bin/yt-dlp');" "QuotifyApp/src/main/index.js"
fi

echo "📱 Creando aplicación TODO-EN-UNO..."

# APP PRINCIPAL
APP_DIR="$DIST_DIR/Quotify v2.1.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Crear todos los tamaños de iconos
ICONSET_DIR="/tmp/quotify_universal.iconset"
mkdir -p "$ICONSET_DIR"
sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
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
    <string>com.quotify.app</string>
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
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

# Launcher SUPER ROBUSTO
cat > "$APP_DIR/Contents/MacOS/Quotify" << 'LAUNCHER_EOF'
#!/bin/bash

# Configuración
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$APP_DIR/../../../QuotifyApp"

# Cambiar al directorio de la app
cd "$QUOTIFY_DIR" 2>/dev/null || {
    osascript -e 'display dialog "Error: No se encuentra QuotifyApp" buttons {"OK"} with icon stop'
    exit 1
}

# Buscar Node.js en TODAS las ubicaciones posibles
find_node() {
    # Primero intentar con which
    local node_which=$(which node 2>/dev/null)
    if [ -n "$node_which" ] && [ -x "$node_which" ]; then
        echo "$node_which"
        return 0
    fi
    
    # Lista exhaustiva de ubicaciones
    local node_paths=(
        "/usr/local/bin/node"
        "/usr/local/opt/node/bin/node"
        "/opt/homebrew/bin/node"
        "/opt/homebrew/opt/node/bin/node"
        "/opt/homebrew/opt/node@20/bin/node"
        "/opt/homebrew/opt/node@18/bin/node"
        "/opt/homebrew/opt/node@16/bin/node"
        "/usr/bin/node"
        "/opt/local/bin/node"
        "/opt/node/bin/node"
        "$HOME/.nvm/versions/node/v20.*/bin/node"
        "$HOME/.nvm/versions/node/v18.*/bin/node"
        "$HOME/.nvm/versions/node/v16.*/bin/node"
        "$HOME/.volta/bin/node"
        "$HOME/.fnm/node-versions/v*/installation/bin/node"
        "$HOME/n/bin/node"
        "$HOME/.local/bin/node"
        "$HOME/bin/node"
        "/Applications/Node.app/Contents/MacOS/node"
    )
    
    for node_path in "${node_paths[@]}"; do
        # Expandir wildcards
        for expanded in $node_path; do
            if [ -x "$expanded" ]; then
                echo "$expanded"
                return 0
            fi
        done
    done
    
    # Última opción: buscar con find
    local found=$(find /usr/local /opt /Applications "$HOME" -name node -type f -perm +111 2>/dev/null | grep -v node_modules | grep -v ".Trash" | head -1)
    if [ -n "$found" ] && [ -x "$found" ]; then
        echo "$found"
        return 0
    fi
    
    return 1
}

# Buscar npm basado en node
find_npm() {
    if [ -n "$1" ]; then
        local npm_path="${1%/node}/npm"
        if [ -x "$npm_path" ]; then
            echo "$npm_path"
            return 0
        fi
    fi
    
    # Buscar independientemente
    local npm_which=$(which npm 2>/dev/null)
    if [ -n "$npm_which" ] && [ -x "$npm_which" ]; then
        echo "$npm_which"
        return 0
    fi
    
    return 1
}

# Buscar Node.js
NODE_BIN=$(find_node)
NPM_BIN=$(find_npm "$NODE_BIN")

if [ -z "$NODE_BIN" ] || [ -z "$NPM_BIN" ]; then
    osascript << 'EOF'
display dialog "Node.js no encontrado

Quotify requiere Node.js para funcionar.

Por favor instálalo desde:
https://nodejs.org

O usando Homebrew:
brew install node" buttons {"Abrir nodejs.org", "Cerrar"} default button "Cerrar" with icon stop
if button returned of result is "Abrir nodejs.org" then
    do shell script "open https://nodejs.org"
end if
EOF
    exit 1
fi

# Verificar si ya está instalado
if [ ! -d "node_modules" ]; then
    osascript << 'EOF'
display dialog "Primera ejecución detectada

Se instalarán las dependencias.
Esto puede tomar 1-2 minutos.

¿Continuar?" buttons {"Cancelar", "Instalar"} default button "Instalar" with icon note
if button returned of result is "Cancelar" then
    error number -128
end if
EOF
    
    if [ $? -ne 0 ]; then
        exit 0
    fi
    
    # Instalar con progreso
    osascript -e 'display dialog "Instalando Quotify...\n\nPor favor espera..." buttons {} giving up after 120' &
    DIALOG_PID=$!
    
    "$NPM_BIN" install > /tmp/quotify_install.log 2>&1
    INSTALL_RESULT=$?
    
    kill $DIALOG_PID 2>/dev/null
    
    if [ $INSTALL_RESULT -ne 0 ]; then
        osascript -e 'display dialog "Error al instalar\n\nRevisa: /tmp/quotify_install.log" buttons {"OK"} with icon stop'
        exit 1
    fi
fi

# Configurar PATH correctamente
export PATH="$QUOTIFY_DIR/bin:${NODE_BIN%/*}:/usr/local/bin:/usr/bin:/bin"

# Limpiar procesos anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 1

# Ejecutar con el npm encontrado
exec "$NPM_BIN" run dev > /tmp/quotify_run.log 2>&1

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/Quotify"

# Crear script de verificación
cat > "$DIST_DIR/VERIFICAR.command" << 'VERIFY_EOF'
#!/bin/bash

echo "🔍 Verificando Quotify v2.1..."
echo ""

# Verificar node_modules
if [ -d "QuotifyApp/node_modules" ]; then
    echo "✅ Dependencias instaladas"
else
    echo "❌ Dependencias NO instaladas"
fi

# Verificar yt-dlp
if [ -f "QuotifyApp/bin/yt-dlp" ]; then
    echo "✅ yt-dlp incluido"
else
    echo "❌ yt-dlp NO encontrado"
fi

# Verificar Node.js del sistema
if which node >/dev/null 2>&1; then
    echo "✅ Node.js: $(node --version)"
else
    echo "❌ Node.js NO instalado en el sistema"
fi

echo ""
read -p "Presiona Enter para cerrar..."
VERIFY_EOF

chmod +x "$DIST_DIR/VERIFICAR.command"

echo ""
echo "✨ QUOTIFY v2.1 UNIVERSAL CREADO!"
echo ""
echo "📦 INCLUYE:"
echo "   • Quotify v2.1.app"
echo "   • node_modules preinstalado"
echo "   • yt-dlp incluido"
echo "   • VERIFICAR.command (para diagnóstico)"
echo ""
echo "🚀 CARACTERÍSTICAS:"
echo "   • Busca Node.js en 20+ ubicaciones"
echo "   • Funciona con cualquier instalación de Node"
echo "   • node_modules ya incluido"
echo "   • Sin dependencias de Python"
echo ""

# Crear ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "✨ ¡VERSIÓN UNIVERSAL LISTA!"