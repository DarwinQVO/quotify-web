#!/bin/bash

echo "🎯 Quotify - VERSIÓN COMPLETA CON YT-DLP"
echo "========================================"

PACKAGE_NAME="Quotify-COMPLETO-YTDLP-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión COMPLETA con yt-dlp..."

# Limpiar y crear directorio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/QuotifyApp"
mkdir -p "$DIST_DIR/tools"

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

# 0. INSTALADOR DE YT-DLP
cat > "0️⃣ INSTALAR-YT-DLP.command" << 'YTDLP_EOF'
#!/bin/bash

echo "🔧 Instalador de yt-dlp para Quotify"
echo "===================================="
echo ""
echo "yt-dlp es necesario para descargar audio de YouTube"
echo ""

# Verificar si ya está instalado
if command -v yt-dlp &> /dev/null; then
    echo "✅ yt-dlp ya está instalado!"
    echo "   Ubicación: $(which yt-dlp)"
    echo "   Versión: $(yt-dlp --version)"
    echo ""
    echo "¡Puedes continuar con la instalación de Quotify!"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 0
fi

echo "❌ yt-dlp NO está instalado"
echo ""
echo "📥 OPCIONES DE INSTALACIÓN:"
echo ""
echo "1. AUTOMÁTICA (recomendada):"
echo "   Se descargará e instalará automáticamente"
echo "   (Requiere contraseña de administrador)"
echo ""
echo "2. MANUAL:"
echo "   Ve a: https://github.com/yt-dlp/yt-dlp"
echo "   Descarga e instala manualmente"
echo ""
read -p "¿Instalar automáticamente? (s/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "📥 Descargando yt-dlp..."
    curl -L "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos" -o /tmp/yt-dlp
    
    echo "🔧 Instalando (requiere contraseña)..."
    chmod +x /tmp/yt-dlp
    sudo mv /tmp/yt-dlp /usr/local/bin/yt-dlp
    
    if command -v yt-dlp &> /dev/null; then
        echo ""
        echo "✅ ¡yt-dlp instalado correctamente!"
        echo "   Versión: $(yt-dlp --version)"
    else
        echo "❌ Error en la instalación"
    fi
fi

echo ""
read -p "Presiona Enter para continuar..."
YTDLP_EOF

chmod +x "0️⃣ INSTALAR-YT-DLP.command"

# 1. INSTALADOR QUOTIFY
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación COMPLETA"
echo "================================="

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

# RUTAS HARDCODED
NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

echo ""
echo "📍 Directorio: $(pwd)"
echo "✅ Node.js: $($NODE_PATH --version)"
echo "✅ npm: $($NPM_PATH --version)"

# Verificar yt-dlp
echo ""
echo "🔍 Verificando yt-dlp..."
if command -v yt-dlp &> /dev/null; then
    echo "✅ yt-dlp: $(yt-dlp --version)"
else
    echo "❌ yt-dlp NO está instalado"
    echo ""
    echo "⚠️ IMPORTANTE: yt-dlp es necesario para transcripciones"
    echo "   Ejecuta primero: '0️⃣ INSTALAR-YT-DLP.command'"
    echo ""
    read -p "¿Continuar sin yt-dlp? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "📦 Instalando dependencias..."
echo "   (Esto toma 3-8 minutos)"
echo ""
"$NPM_PATH" install

echo ""
echo "✅ ¡Instalación completada!"
echo ""
echo "🚀 SIGUIENTE PASO:"
echo "   Doble clic en '🎯 Abrir Quotify.app'"
echo ""
read -p "Presiona Enter para continuar..."
INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. APP BUNDLE MEJORADO
APP_DIR="$DIST_DIR/🎯 Abrir Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copiar icono
if [ -f "/Users/darwinborges/Desktop/Icono Quotify.png" ]; then
    ICONSET_DIR="/tmp/quotify_ytdlp.iconset"
    mkdir -p "$ICONSET_DIR"
    
    sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null
    sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null
    sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null
    sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null
    
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
    <string>com.quotify.ytdlp</string>
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

# LAUNCHER CON PATH COMPLETO
cat > "$APP_DIR/Contents/MacOS/quotify_launcher" << 'LAUNCHER_EOF'
#!/bin/bash

# Directorio de la app
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

# RUTAS HARDCODED + yt-dlp paths
export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

# Función para diálogos
show_dialog() {
    osascript -e "tell application \"System Events\" to display dialog \"$1\" buttons {\"$2\"} default button \"$2\" with icon note"
}

show_choice() {
    result=$(osascript -e "tell application \"System Events\" to display dialog \"$1\" buttons {\"Cancelar\", \"$2\"} default button \"$2\" with icon note" 2>&1)
    if [[ $result == *"$2"* ]]; then
        return 0
    else
        return 1
    fi
}

# Preguntar si abrir
if ! show_choice "🎯 Quotify - Versión Completa

✅ Todas las funciones activas
✅ Transcripción con yt-dlp + OpenAI
✅ Sin terminal visible
🔇 Ejecución invisible

¿Iniciar Quotify?" "🚀 Abrir Quotify"; then
    exit 0
fi

# Verificar instalación
if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    show_dialog "❌ Quotify no está instalado

Por favor ejecuta primero:
'1️⃣ INSTALAR-QUOTIFY.command'" "Entendido"
    exit 1
fi

# Cambiar al directorio
cd "$QUOTIFY_DIR"

# Cerrar procesos anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
sleep 2

# Mostrar progreso
show_dialog "🚀 Iniciando Quotify...

⚡ Preparando aplicación
⏱️ Toma 15-20 segundos
🔇 Sin terminal visible

¡No cierres este mensaje!" "Entendido" &

# LOG SILENCIOSO
LOG_FILE="/tmp/quotify_ytdlp_$(date +%s).log"

# EJECUTAR INVISIBLE
{
    echo "=== Quotify Complete Log $(date) ==="
    echo "PWD: $(pwd)"
    echo "Node: $NODE_PATH"
    echo "npm: $NPM_PATH"
    echo "PATH: $PATH"
    echo "yt-dlp: $(which yt-dlp || echo 'not found')"
    echo ""
    
    # Ejecutar npm run dev
    "$NPM_PATH" run dev
} > "$LOG_FILE" 2>&1 &

# Esperar que arranque
sleep 20

# Verificar si funciona
if pgrep -f "electron.*quotify" >/dev/null; then
    show_dialog "✅ ¡Quotify funcionando!

📱 Aplicación abierta
🎵 Transcripción lista
🔇 Sin terminal visible

Si no ves la ventana:
• Revisa el Dock
• Usa Mission Control (F3)" "¡Perfecto!"
else
    show_dialog "⚠️ Quotify tardó en abrir

Intenta otra vez o revisa:
Log: $LOG_FILE" "Entendido"
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify_launcher"

# 3. VERIFICADOR DE SISTEMA
cat > "3️⃣ VERIFICAR-SISTEMA.command" << 'CHECK_EOF'
#!/bin/bash

echo "🔍 Verificación de Sistema para Quotify"
echo "======================================"
echo ""

# Node.js
echo "📋 Node.js:"
if [ -x "/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node" ]; then
    echo "✅ Instalado: $(/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node --version)"
else
    echo "❌ NO encontrado en NVM"
fi

# npm
echo ""
echo "📋 npm:"
if [ -x "/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm" ]; then
    echo "✅ Instalado: $(/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm --version)"
else
    echo "❌ NO encontrado"
fi

# yt-dlp
echo ""
echo "📋 yt-dlp:"
if command -v yt-dlp &> /dev/null; then
    echo "✅ Instalado: $(yt-dlp --version)"
    echo "   Ubicación: $(which yt-dlp)"
else
    echo "❌ NO instalado - necesario para transcripciones"
    echo "   Ejecuta: '0️⃣ INSTALAR-YT-DLP.command'"
fi

# Quotify
echo ""
echo "📋 Quotify:"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -d "$DIR/QuotifyApp/node_modules" ]; then
    echo "✅ Dependencias instaladas"
else
    echo "❌ Dependencias NO instaladas"
    echo "   Ejecuta: '1️⃣ INSTALAR-QUOTIFY.command'"
fi

echo ""
echo "=================================="
echo ""
read -p "Presiona Enter para salir..."
CHECK_EOF

chmod +x "3️⃣ VERIFICAR-SISTEMA.command"

# LEEME
cat > "LEEME-COMPLETO.txt" << 'README_EOF'
🎯 QUOTIFY - VERSIÓN COMPLETA CON YT-DLP

========================================

✅ INCLUYE TODO LO NECESARIO
✅ TRANSCRIPCIÓN FUNCIONANDO
✅ SIN TERMINAL VISIBLE

📋 INSTALACIÓN COMPLETA:

1. PRIMERO (solo si falla transcripción):
   "0️⃣ INSTALAR-YT-DLP.command"

2. INSTALAR QUOTIFY:
   "1️⃣ INSTALAR-QUOTIFY.command"

3. ABRIR QUOTIFY:
   "🎯 Abrir Quotify.app"

🔍 VERIFICAR SISTEMA:
   "3️⃣ VERIFICAR-SISTEMA.command"

🎵 TRANSCRIPCIÓN:
• Requiere yt-dlp instalado
• Requiere API key de OpenAI
• Funciona con cualquier video de YouTube

¡Disfruta Quotify completo!
README_EOF

echo ""
echo "✅ VERSIÓN COMPLETA CON YT-DLP CREADA!"
echo ""
echo "📦 INCLUYE:"
echo "   0️⃣ Instalador de yt-dlp"
echo "   1️⃣ Instalador de Quotify"
echo "   🎯 App invisible"
echo "   3️⃣ Verificador de sistema"
echo ""

# ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🎯 ¡VERSIÓN COMPLETA LISTA!"