#!/bin/bash

echo "✨ Quotify v2.1 - VERSIÓN SIN CONCURRENTLY (Arreglado)"
echo "====================================================="

PACKAGE_NAME="Quotify-v2.1-SIN-CONCURRENTLY"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión que evita el problema de concurrently..."

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

echo "📦 Modificando package.json para evitar concurrently..."
cd QuotifyApp

# Crear una versión de package.json que no use concurrently
cp package.json package.json.backup

# Crear script simple que no use concurrently
cat > package.json << 'PACKAGE_EOF'
{
  "name": "quotify",
  "version": "1.0.0",
  "main": "dist/main/index.js",
  "scripts": {
    "dev": "npm run build:electron && npm run start:electron",
    "build": "npm run build:vite && npm run build:electron",
    "build:vite": "vite build",
    "build:electron": "tsc -p tsconfig.node.json",
    "start:electron": "electron . --dev",
    "preview": "vite preview"
  },
  "dependencies": {
    "@radix-ui/react-checkbox": "^1.1.3",
    "@radix-ui/react-dialog": "^1.1.4",
    "@radix-ui/react-dropdown-menu": "^2.1.4",
    "@radix-ui/react-label": "^2.1.1",
    "@radix-ui/react-progress": "^1.1.1",
    "@radix-ui/react-select": "^2.1.4",
    "@radix-ui/react-switch": "^1.1.1",
    "@radix-ui/react-toast": "^1.2.5",
    "axios": "^1.7.8",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "electron-updater": "^6.3.9",
    "form-data": "^4.0.1",
    "framer-motion": "^11.15.0",
    "lucide-react": "^0.468.0",
    "openai": "^4.77.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-player": "^2.16.0",
    "tailwind-merge": "^2.5.5",
    "tailwindcss-animate": "^1.0.7",
    "youtube-dl-exec": "^2.5.8",
    "ytdl-core": "^4.11.5",
    "zod": "^3.24.1"
  },
  "devDependencies": {
    "@types/react": "^18.3.17",
    "@types/react-dom": "^18.3.5",
    "@typescript-eslint/eslint-plugin": "^6.21.0",
    "@typescript-eslint/parser": "^6.21.0",
    "@vitejs/plugin-react": "^4.3.4",
    "autoprefixer": "^10.4.20",
    "electron": "^29.4.6",
    "electron-builder": "^25.1.8",
    "eslint": "^8.57.1",
    "eslint-plugin-react-hooks": "^4.6.2",
    "eslint-plugin-react-refresh": "^0.4.16",
    "postcss": "^8.5.0",
    "tailwindcss": "^3.4.17",
    "typescript": "^5.7.3",
    "vite": "^5.4.19"
  }
}
PACKAGE_EOF

echo "📦 Instalando dependencias SIN concurrently..."
npm install --no-audit --no-fund

echo "🔨 Compilando el proyecto..."
npm run build:electron

cd ..

echo "🎯 Creando aplicación que funciona..."

# UNA SOLA APP
APP_DIR="$DIST_DIR/Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Crear icono
ICONSET_DIR="/tmp/quotify_sin_concurrently.iconset"
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
    <string>com.quotify.noconcurrently</string>
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

# Launcher que ejecuta directamente sin concurrently
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

# Buscar Node.js del sistema
find_node() {
    if command -v node >/dev/null 2>&1; then
        echo "$(command -v node)"
        return 0
    fi
    
    for node_path in \
        "/usr/local/bin/node" \
        "/opt/homebrew/bin/node" \
        "/usr/bin/node" \
        "$HOME/.nvm/versions/node/*/bin/node"
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

Instala Node.js desde:
https://nodejs.org" buttons {"Abrir nodejs.org", "Cerrar"} default button "Cerrar" with icon stop
if button returned of result is "Abrir nodejs.org" then
    do shell script "open https://nodejs.org"
end if
EOF
    exit 1
fi

# Verificar dependencias
if [ ! -d "node_modules" ]; then
    osascript << 'EOF'
display dialog "Instalando dependencias...

Por favor espera." buttons {"OK"} with icon note
EOF
    
    "$NPM_BIN" install > /tmp/quotify_install_noconcurrently.log 2>&1
    
    if [ $? -ne 0 ]; then
        osascript -e 'display dialog "Error instalando dependencias" buttons {"OK"} with icon stop'
        exit 1
    fi
    
    # Compilar después de instalar
    "$NPM_BIN" run build:electron > /tmp/quotify_build.log 2>&1
fi

# Configurar PATH incluyendo yt-dlp local
export PATH="$QUOTIFY_DIR/bin:${NODE_BIN%/*}:/usr/local/bin:/usr/bin:/bin"

# Limpiar procesos anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 1

# Ejecutar Vite en background
"$NPM_BIN" run build:vite > /tmp/quotify_vite.log 2>&1

# Esperar un poco
sleep 3

# Ejecutar Electron directamente
exec "$NPM_BIN" run start:electron > /tmp/quotify_electron.log 2>&1
LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/Quotify"

echo "📄 Creando instrucciones..."
cat > "$DIST_DIR/INSTRUCCIONES.txt" << 'INSTRUCTIONS'
QUOTIFY v2.1 - SIN CONCURRENTLY
===============================

REQUISITO:
Node.js (desde nodejs.org)

USO:
1. Doble clic en Quotify.app
2. ¡Listo!

ARREGLADO:
✅ Sin problemas de concurrently
✅ Ejecución directa de Electron
✅ yt-dlp incluido
✅ Dependencias limpias

LOGS:
/tmp/quotify_*.log
INSTRUCTIONS

echo "🔓 Removiendo restricciones..."
xattr -cr "$DIST_DIR" 2>/dev/null || true

echo "🧪 PROBANDO..."

# Test compilación
if [ -f "QuotifyApp/dist/main/index.js" ]; then
    echo "✅ Proyecto compilado"
else
    echo "❌ Proyecto no compilado"
    exit 1
fi

if [ -d "QuotifyApp/node_modules" ]; then
    echo "✅ Dependencias OK"
else
    echo "❌ Dependencias falta"
    exit 1
fi

if [ -x "QuotifyApp/bin/yt-dlp" ]; then
    echo "✅ yt-dlp OK"
else
    echo "❌ yt-dlp falta"
    exit 1
fi

echo ""
echo "✨ QUOTIFY v2.1 SIN CONCURRENTLY CREADO!"
echo ""
echo "📦 ARREGLADO:"
echo "   • Sin concurrently corrupto"
echo "   • Ejecución directa"
echo "   • Proyecto precompilado"
echo ""

# Crear ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -x "*.DS_Store" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🚀 ¡Esta versión debería funcionar!"