#!/bin/bash

echo "🎯 Quotify - VERSIÓN NVM CORREGIDO"
echo "=================================="

PACKAGE_NAME="Quotify-NVM-CORREGIDO-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión con NVM corregido..."

# Limpiar y crear directorio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/QuotifyApp"
mkdir -p "$DIST_DIR/documentacion"

# Copiar proyecto completo
echo "📋 Copiando proyecto completo..."
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

# 1. INSTALADOR CON DETECCIÓN NVM MEJORADA
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación con Detección NVM"
echo "==========================================="

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

echo ""
echo "📍 Instalando en: $(pwd)"
echo ""

# Función para encontrar Node.js con NVM expandido
find_node() {
    # Buscar primero con which (más confiable)
    local which_node=$(which node 2>/dev/null)
    if [ -n "$which_node" ] && [ -x "$which_node" ]; then
        echo "$which_node"
        return 0
    fi
    
    # Buscar en ubicaciones estándar
    local node_paths=(
        "/usr/local/bin/node"
        "/opt/homebrew/bin/node"
        "/usr/bin/node"
    )
    
    for path in "${node_paths[@]}"; do
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    # Buscar específicamente en NVM (método más robusto)
    if [ -d "$HOME/.nvm/versions/node" ]; then
        for version_dir in "$HOME/.nvm/versions/node"/*; do
            if [ -d "$version_dir/bin" ] && [ -x "$version_dir/bin/node" ]; then
                echo "$version_dir/bin/node"
                return 0
            fi
        done
    fi
    
    # Buscar en otras ubicaciones NVM
    local nvm_paths=(
        "$HOME/.nvm/versions/node/*/bin/node"
        "/usr/local/nvm/versions/node/*/bin/node"
    )
    
    for pattern in "${nvm_paths[@]}"; do
        for path in $pattern; do
            if [ -x "$path" ]; then
                echo "$path"
                return 0
            fi
        done
    done
    
    return 1
}

# Buscar Node.js
echo "🔍 Buscando Node.js..."
NODE_PATH=$(find_node)

if [ -z "$NODE_PATH" ]; then
    echo "❌ Node.js no encontrado"
    echo ""
    echo "🔍 UBICACIONES BUSCADAS:"
    echo "   • which node"
    echo "   • /usr/local/bin/node"
    echo "   • /opt/homebrew/bin/node"
    echo "   • ~/.nvm/versions/node/*/bin/node"
    echo ""
    echo "📥 SOLUCIONES:"
    echo "   1. Instala Node.js: https://nodejs.org/"
    echo "   2. O activa NVM: source ~/.nvm/nvm.sh"
    echo "   3. Ejecuta este script otra vez"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 1
fi

# Obtener directorio de Node.js
NODE_DIR=$(dirname "$NODE_PATH")
NPM_PATH="$NODE_DIR/npm"

echo "✅ Node.js encontrado en: $NODE_PATH"
echo "✅ Version: $($NODE_PATH --version)"

# Verificar npm
if [ ! -x "$NPM_PATH" ]; then
    echo "❌ npm no encontrado en: $NPM_PATH"
    echo "   Buscando npm..."
    
    # Buscar npm con which
    NPM_PATH=$(which npm 2>/dev/null)
    if [ -z "$NPM_PATH" ] || [ ! -x "$NPM_PATH" ]; then
        echo "❌ npm no encontrado"
        echo "   Por favor reinstala Node.js"
        read -p "Presiona Enter para salir..."
        exit 1
    fi
fi

echo "✅ npm encontrado en: $NPM_PATH"
echo "✅ npm version: $($NPM_PATH --version)"
echo ""

# Guardar rutas para la aplicación
cat > "$DIR/node_paths.env" << ENV_EOF
NODE_PATH=$NODE_PATH
NPM_PATH=$NPM_PATH
NODE_DIR=$NODE_DIR
PATH=$NODE_DIR:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin
ENV_EOF

echo "💾 Rutas guardadas en node_paths.env"
echo ""

# Limpiar cache
echo "🧹 Limpiando cache..."
"$NPM_PATH" cache clean --force 2>/dev/null || true

# Instalar dependencias
echo "📦 Instalando dependencias..."
echo "   (Esto puede tomar 3-8 minutos)"
echo ""

"$NPM_PATH" install

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Error en instalación"
    echo ""
    echo "🔧 SOLUCIONES:"
    echo "   1. Verifica conexión a internet"
    echo "   2. Cierra otras aplicaciones"
    echo "   3. Reinicia y prueba otra vez"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 1
fi

echo ""
echo "✅ ¡Instalación completada!"
echo ""
echo "🚀 SIGUIENTE PASO:"
echo "   Doble clic en '🎯 Abrir Quotify.app'"
echo ""
read -p "Presiona Enter para continuar..."

INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. CREAR APLICACIÓN CON NVM CORREGIDO
APP_DIR="$DIST_DIR/🎯 Abrir Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copiar icono si existe
if [ -f "/Users/darwinborges/Desktop/Icono Quotify.png" ]; then
    ICONSET_DIR="/tmp/quotify_nvm.iconset"
    mkdir -p "$ICONSET_DIR"
    
    sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
    sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
    sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
    sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
    sips -z 64 64 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_64x64.png" 2>/dev/null
    sips -z 32 32 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_32x32.png" 2>/dev/null
    sips -z 16 16 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_16x16.png" 2>/dev/null
    
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
    <string>com.quotify.nvm.fixed</string>
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

# Launcher con NVM CORREGIDO
cat > "$APP_DIR/Contents/MacOS/quotify_launcher" << 'LAUNCHER_EOF'
#!/bin/bash

# Obtener directorio de la app
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"
ENV_FILE="$DIR/../../../node_paths.env"

# Función para mostrar diálogos
show_dialog() {
    /usr/bin/osascript -e "tell application \"System Events\" to display dialog \"$1\" buttons {\"$2\"} default button \"$2\" with icon note"
}

show_choice() {
    result=$(/usr/bin/osascript -e "tell application \"System Events\" to display dialog \"$1\" buttons {\"Cancelar\", \"$2\"} default button \"$2\" with icon note" 2>/dev/null)
    if [[ $result == *"$2"* ]]; then
        return 0
    else
        return 1
    fi
}

# Preguntar si quiere abrir
if ! show_choice "🎯 Quotify - NVM Corregido

✅ Detección automática de Node.js/NVM
✅ Backend Electron + Frontend React
✅ Transcripción con OpenAI funcional
🔇 Sin terminal visible

¿Iniciar Quotify?" "🚀 Abrir Quotify"; then
    exit 0
fi

# Verificar que esté instalado
if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    show_dialog "❌ Quotify no está instalado

Por favor ejecuta primero:
'1️⃣ INSTALAR-QUOTIFY.command'

Después intenta abrir Quotify otra vez." "Entendido"
    exit 1
fi

# Cargar rutas de Node.js
if [ ! -f "$ENV_FILE" ]; then
    show_dialog "❌ Archivo de configuración no encontrado

Por favor ejecuta el instalador otra vez:
'1️⃣ INSTALAR-QUOTIFY.command'" "Entendido"
    exit 1
fi

# Cargar variables de entorno
source "$ENV_FILE"

# Verificar que las rutas existan
if [ ! -x "$NODE_PATH" ]; then
    show_dialog "❌ Node.js no encontrado en: $NODE_PATH

Por favor ejecuta el instalador otra vez." "Entendido"
    exit 1
fi

if [ ! -x "$NPM_PATH" ]; then
    show_dialog "❌ npm no encontrado en: $NPM_PATH

Por favor ejecuta el instalador otra vez." "Entendido"
    exit 1
fi

# Cambiar al directorio del proyecto
cd "$QUOTIFY_DIR"

# Establecer PATH correcto
export PATH="$NODE_DIR:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"

# Mostrar progreso
show_dialog "🚀 Iniciando Quotify...

⚡ Node.js: $($NODE_PATH --version)
⚡ Preparando aplicación
🔇 Se ejecutará invisible

¡Esto toma 15-25 segundos!" "Entendido" &

# Cerrar procesos anteriores
/usr/bin/pkill -f "electron.*quotify" 2>/dev/null || true
/usr/bin/pkill -f "vite.*5173" 2>/dev/null || true
/usr/bin/pkill -f "node.*5173" 2>/dev/null || true
sleep 3

# Crear logs
LOG_FILE="/tmp/quotify_nvm_$(date +%s).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Quotify NVM Corrected Log $(date) ==="
echo "Directory: $(pwd)"
echo "Node path: $NODE_PATH"
echo "Node version: $($NODE_PATH --version)"
echo "npm path: $NPM_PATH"
echo "npm version: $($NPM_PATH --version)"
echo "PATH: $PATH"

# Verificar puerto
if /usr/bin/lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "Port 5173 is in use, killing process..."
    /usr/bin/pkill -f ".*5173" 2>/dev/null || true
    sleep 2
fi

# Método 1: Intentar con concurrently
echo "=== Attempting Method 1: npm run dev ==="
"$NPM_PATH" run dev &
NPM_PID=$!

# Esperar a que arranque
sleep 25

# Verificar si está funcionando
if kill -0 $NPM_PID 2>/dev/null && /usr/bin/pgrep -f "electron.*quotify" >/dev/null; then
    echo "=== Method 1 successful ==="
    show_dialog "✅ ¡Quotify funcionando!

📱 Aplicación Electron abierta
🔥 Backend + Frontend completo

Node.js: $($NODE_PATH --version)
Log: $LOG_FILE" "¡Perfecto!"
    exit 0
fi

# Método 2: Manual step-by-step
echo "=== Attempting Method 2: Manual startup ==="
kill $NPM_PID 2>/dev/null || true
sleep 2

# Iniciar Vite primero
echo "Starting Vite server..."
"$NPM_PATH" run dev:vite &
VITE_PID=$!

# Esperar que Vite esté listo
for i in {1..25}; do
    if /usr/bin/curl -s http://localhost:5173 >/dev/null 2>&1; then
        echo "Vite ready on attempt $i"
        break
    fi
    sleep 1
done

# Verificar Vite
if ! /usr/bin/curl -s http://localhost:5173 >/dev/null 2>&1; then
    echo "=== Vite failed to start ==="
    show_dialog "❌ Error: Vite server no arrancó

🔧 DEBUG INFO:
• Node.js: $($NODE_PATH --version)
• npm: $($NPM_PATH --version)
• Directory: $(pwd)

💡 SOLUCIONES:
1. Reinstala: '1️⃣ INSTALAR-QUOTIFY.command'
2. Reinicia computadora
3. Log: $LOG_FILE" "Entendido"
    exit 1
fi

# Iniciar Electron
echo "Starting Electron..."
"$NPM_PATH" run dev:electron &
ELECTRON_PID=$!

# Esperar Electron
sleep 15

# Verificar Electron
if /usr/bin/pgrep -f "electron.*quotify" >/dev/null; then
    echo "=== Method 2 successful ==="
    show_dialog "✅ ¡Quotify funcionando!

📱 Aplicación Electron abierta
🔥 Todas las funciones disponibles

Node.js: $($NODE_PATH --version)
Log: $LOG_FILE" "¡Perfecto!"
else
    echo "=== Both methods failed ==="
    show_dialog "❌ Quotify no pudo arrancar

🔧 DEBUG INFO:
• Node.js: $($NODE_PATH --version)
• Vite: $(/usr/bin/curl -s http://localhost:5173 >/dev/null 2>&1 && echo 'OK' || echo 'FAIL')
• Electron: $(/usr/bin/pgrep -f electron >/dev/null && echo 'OK' || echo 'FAIL')

💡 SOLUCIONES:
1. Reinstala completamente
2. Reinicia computadora
3. Log detallado: $LOG_FILE" "Entendido"
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify_launcher"

# 3. DOCUMENTACIÓN
cat > "documentacion/NVM-CORREGIDO.txt" << 'DOC_EOF'
🎯 QUOTIFY - NVM CORREGIDO

═══════════════════════════════════════

Esta versión está diseñada específicamente para
instalaciones de Node.js con NVM.

🔧 PROBLEMA SOLUCIONADO:
❌ "Node.js no encontrado" con NVM
❌ Rutas NVM no detectadas
✅ Búsqueda mejorada en ~/.nvm/
✅ Detección con 'which node'

📋 DETECCIÓN MEJORADA:
• which node (más confiable)
• ~/.nvm/versions/node/*/bin/node
• /usr/local/bin/node
• /opt/homebrew/bin/node

🚀 INSTALACIÓN:
1. Ejecutar: "1️⃣ INSTALAR-QUOTIFY.command"
   → Detecta automáticamente NVM
   → Guarda rutas correctas
2. Ejecutar: "🎯 Abrir Quotify.app"
   → Usa rutas NVM guardadas

🔥 GARANTÍA:
Detecta Node.js incluso si está instalado con NVM.

DOC_EOF

cat > "LEEME-NVM-CORREGIDO.txt" << 'README_EOF'
🎯 QUOTIFY - VERSIÓN NVM CORREGIDO

═══════════════════════════════════════

¡Esta versión soluciona problemas con NVM!

🔧 PROBLEMA ANTERIOR:
❌ "Node.js no encontrado" con NVM
❌ Rutas ~/.nvm/ no detectadas

✅ SOLUCIÓN APLICADA:
✅ Búsqueda mejorada con 'which node'
✅ Detección específica de rutas NVM
✅ Verificación robusta de npm

📋 INSTALACIÓN:
1. Doble clic: "1️⃣ INSTALAR-QUOTIFY.command"
2. Doble clic: "🎯 Abrir Quotify.app"
3. ¡Debería funcionar con NVM!

🎯 GARANTÍA:
Si tienes Node.js instalado (incluso con NVM)
esta versión DEBE detectarlo.

README_EOF

echo ""
echo "✅ VERSIÓN NVM CORREGIDO CREADA!"
echo ""
echo "🔧 MEJORAS APLICADAS:"
echo "   ✅ Detección con 'which node'"
echo "   ✅ Búsqueda específica en NVM"
echo "   ✅ Verificación robusta de npm"
echo "   ✅ Rutas guardadas correctamente"
echo ""

# Crear ZIP final
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP NVM CORREGIDO: ${PACKAGE_NAME}.zip"
echo ""
echo "🎯 ESTA VERSIÓN DEBE DETECTAR TU NVM"
echo "   Node.js está en: $(which node)"
echo "   npm está en: $(which npm)"