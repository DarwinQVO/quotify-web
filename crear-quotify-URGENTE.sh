#!/bin/bash

echo "🔥 Quotify - VERSIÓN URGENTE FUNCIONAL"
echo "====================================="

PACKAGE_NAME="Quotify-URGENTE-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión URGENTE..."

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

# 1. INSTALADOR DIRECTO
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación URGENTE"
echo "================================"

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
echo "📦 Instalando..."
"$NPM_PATH" install

echo ""
echo "✅ ¡Listo!"
echo ""
read -p "Presiona Enter..."
INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. ABRIR DIRECTO (SIN APP BUNDLE)
cat > "2️⃣ ABRIR-QUOTIFY.command" << 'OPEN_EOF'
#!/bin/bash

echo "🚀 Abriendo Quotify..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

# RUTAS HARDCODED
export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/usr/local/bin:/usr/bin:/bin"
NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

# Cerrar anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
sleep 2

# Abrir Quotify
echo "⚡ Iniciando..."
"$NPM_PATH" run dev
OPEN_EOF

chmod +x "2️⃣ ABRIR-QUOTIFY.command"

# 3. VERSIÓN ELECTRON DIRECTO
cat > "3️⃣ ELECTRON-DIRECTO.command" << 'ELECTRON_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

# RUTAS HARDCODED
export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/usr/local/bin:/usr/bin:/bin"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

# Cerrar anteriores
pkill -f "electron" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true
sleep 2

# Iniciar Vite en background
"$NPM_PATH" run dev:vite &
VITE_PID=$!

# Esperar Vite
echo "⏳ Esperando Vite..."
sleep 10

# Iniciar Electron
echo "🚀 Abriendo Electron..."
"$NPM_PATH" run dev:electron
ELECTRON_EOF

chmod +x "3️⃣ ELECTRON-DIRECTO.command"

# LEEME
cat > "LEEME-URGENTE.txt" << 'README_EOF'
🔥 QUOTIFY - VERSIÓN URGENTE

================================

3 FORMAS DE ABRIR:

1️⃣ INSTALAR primero (solo una vez)
2️⃣ ABRIR-QUOTIFY (método normal)
3️⃣ ELECTRON-DIRECTO (si falla el 2)

TODAS usan tus rutas exactas de NVM.
README_EOF

echo ""
echo "✅ VERSIÓN URGENTE CREADA!"
echo ""
echo "📋 INCLUYE 3 COMANDOS:"
echo "   1️⃣ INSTALAR (una vez)"
echo "   2️⃣ ABRIR normal"
echo "   3️⃣ ELECTRON directo"
echo ""

# ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"