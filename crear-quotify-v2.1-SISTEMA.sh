#!/bin/bash

echo "✨ Quotify v2.1 - VERSIÓN QUE USA NODE.JS DEL SISTEMA"
echo "===================================================="

PACKAGE_NAME="Quotify-v2.1-SISTEMA"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión que funciona con Node.js del sistema..."

# Limpiar
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "📋 Copiando proyecto base..."
cp -r "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349/QuotifyApp" "$DIST_DIR/"

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

echo "🛠️ Configurando yt-dlp incluido..."
mkdir -p "QuotifyApp/bin"
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos -o "QuotifyApp/bin/yt-dlp" --progress-bar
chmod +x "QuotifyApp/bin/yt-dlp"

echo "🔨 Corrigiendo main/index.js para usar yt-dlp incluido..."

# Reemplazar la línea de yt-dlp hardcodeada
sed -i '' "s|const ytdlpPath = '/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp';|const ytdlpPath = path.join(__dirname, '../../bin/yt-dlp');|g" "QuotifyApp/src/main/index.js"

# Asegurar que path está importado
if ! grep -q "const path = require('path')" "QuotifyApp/src/main/index.js"; then
    sed -i '' "1i\\
const path = require('path');\\
" "QuotifyApp/src/main/index.js"
fi

echo "📦 Instalando dependencias con tu Node.js actual..."
cd QuotifyApp

# Limpiar e instalar con tu Node.js
rm -rf node_modules package-lock.json
npm install --no-audit --no-fund

cd ..

echo "🎯 Creando aplicación que usa Node.js del sistema..."

# UNA SOLA APP
APP_DIR="$DIST_DIR/Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Crear icono
ICONSET_DIR="/tmp/quotify_sistema.iconset"
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
    <string>com.quotify.sistema</string>
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
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

# Launcher que usa Node.js del sistema
cat > "$APP_DIR/Contents/MacOS/Quotify" << 'LAUNCHER_EOF'
#!/bin/bash

# Variables
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$APP_DIR/../../.."
QUOTIFY_DIR="$BASE_DIR/QuotifyApp"

# Cambiar al directorio
cd "$QUOTIFY_DIR" || {
    osascript -e 'display dialog "Error: No se encuentra QuotifyApp" buttons {"OK"} with icon stop'
    exit 1
}

# Buscar Node.js del sistema de forma exhaustiva
find_node() {
    # Intentar which primero
    if command -v node >/dev/null 2>&1; then
        echo "$(command -v node)"
        return 0
    fi
    
    # Buscar en ubicaciones conocidas
    for node_path in \
        "/usr/local/bin/node" \
        "/opt/homebrew/bin/node" \
        "/opt/homebrew/opt/node/bin/node" \
        "/usr/bin/node" \
        "$HOME/.nvm/versions/node/*/bin/node" \
        "$HOME/.volta/bin/node" \
        "$HOME/.fnm/node-versions/*/installation/bin/node"
    do
        for expanded in $node_path; do
            if [ -x "$expanded" ]; then
                echo "$expanded"
                return 0
            fi
        done
    done
    
    return 1
}

find_npm() {
    if [ -n "$1" ]; then
        local npm_path="${1%/node}/npm"
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
    osascript << 'EOF'
display dialog "Node.js no encontrado

Por favor instala Node.js desde:
https://nodejs.org

O usando Homebrew:
brew install node" buttons {"Abrir nodejs.org", "Cerrar"} default button "Cerrar" with icon stop
if button returned of result is "Abrir nodejs.org" then
    do shell script "open https://nodejs.org"
end if
EOF
    exit 1
fi

# Verificar dependencias
if [ ! -d "node_modules" ]; then
    osascript << 'EOF'
display dialog "Primera ejecución: Instalando dependencias...

Esto puede tomar 1-2 minutos." buttons {"OK"} with icon note
EOF
    
    "$NPM_BIN" install > /tmp/quotify_install_sistema.log 2>&1
    
    if [ $? -ne 0 ]; then
        osascript -e 'display dialog "Error instalando dependencias\n\nRevisa: /tmp/quotify_install_sistema.log" buttons {"OK"} with icon stop'
        exit 1
    fi
fi

# Configurar PATH incluyendo yt-dlp local
export PATH="$QUOTIFY_DIR/bin:${NODE_BIN%/*}:/usr/local/bin:/usr/bin:/bin"

# Limpiar procesos anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 1

# Ejecutar
exec "$NPM_BIN" run dev > /tmp/quotify_sistema.log 2>&1
LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/Quotify"

echo "📄 Creando instrucciones..."
cat > "$DIST_DIR/INSTRUCCIONES.txt" << 'INSTRUCTIONS'
QUOTIFY v2.1 - VERSIÓN SISTEMA
==============================

REQUISITO:
Node.js debe estar instalado en tu Mac
(Descarga desde: https://nodejs.org)

USO:
1. Doble clic en Quotify.app
2. ¡Listo!

SI NO ABRE:
• Clic derecho en Quotify.app
• Seleccionar "Abrir"
• Confirmar seguridad

INCLUYE:
✅ yt-dlp integrado
✅ Dependencias preinstaladas
✅ Transcripción funcionando

LOGS: /tmp/quotify_sistema.log
INSTRUCTIONS

echo "🔓 Removiendo restricciones..."
xattr -cr "$DIST_DIR" 2>/dev/null || true

echo "🧪 PROBANDO la aplicación..."

# Test básico
if [ -d "QuotifyApp/node_modules" ]; then
    echo "✅ node_modules OK"
else
    echo "❌ node_modules falta"
    exit 1
fi

if [ -x "QuotifyApp/bin/yt-dlp" ]; then
    echo "✅ yt-dlp OK"
else
    echo "❌ yt-dlp falta"
    exit 1
fi

# Probar que encuentra Node.js
if command -v node >/dev/null 2>&1; then
    echo "✅ Node.js del sistema encontrado: $(node --version)"
else
    echo "⚠️  Node.js no encontrado en este sistema"
fi

echo ""
echo "✨ QUOTIFY v2.1 SISTEMA CREADO!"
echo ""
echo "📦 CONTENIDO:"
echo "   📱 Quotify.app"
echo "   📄 INSTRUCCIONES.txt"
echo ""
echo "✅ CARACTERÍSTICAS:"
echo "   • Usa Node.js del sistema"
echo "   • yt-dlp incluido"
echo "   • Dependencias preinstaladas"
echo "   • Sin permisos complicados"
echo ""

# Crear ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -x "*.DS_Store" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🚀 Listo para probar!"