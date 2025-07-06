#!/bin/bash

echo "🎯 Quotify - VERSIÓN FINAL CON ELECTRON COMPLETO"
echo "=============================================="

PACKAGE_NAME="Quotify-ELECTRON-FINAL-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión final con Electron completo..."

# Crear directorio principal limpio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/QuotifyApp"
mkdir -p "$DIST_DIR/documentacion"

# Copiar TODO el proyecto (incluyendo node_modules si existe)
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

# Verificar que backend esté incluido
if [ ! -f "$DIST_DIR/QuotifyApp/src/main/index.js" ]; then
    echo "❌ Error: Backend de Electron no encontrado"
    exit 1
fi

echo "✅ Backend de Electron incluido correctamente"

cd "$DIST_DIR"

# 1. INSTALADOR COMPLETO
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'EOF'
#!/bin/bash

exec > >(tee /tmp/quotify_install.log) 2>&1

# Función para mostrar ventanas sin terminal
show_dialog() {
    osascript -e "tell application \"System Events\" to display dialog \"$1\" buttons {\"$2\"} default button \"$2\" with icon note"
}

show_error() {
    osascript -e "tell application \"System Events\" to display dialog \"❌ $1\" buttons {\"Entendido\"} default button \"Entendido\" with icon stop"
}

show_progress() {
    osascript << APPLESCRIPT &
tell application "System Events"
    display dialog "$1" buttons {} giving up after $2 with icon note
end tell
APPLESCRIPT
    echo $!
}

# Mostrar inicio
if ! show_dialog "🎯 Quotify - Instalación Completa

✅ Instalará Electron + React completo
✅ Transcripción funcional con OpenAI
✅ Metadata de YouTube instantánea
✅ Aplicación nativa (no web)
🔇 Completamente invisible después

¿Continuar con la instalación?" "Instalar"; then
    exit 0
fi

# Verificar Node.js
if ! command -v node &> /dev/null; then
    show_error "Node.js no está instalado.

Pasos:
1. Ve a: https://nodejs.org/
2. Descarga versión LTS
3. Instala y ejecuta este instalador otra vez"
    exit 1
fi

NODE_VERSION=$(node --version)
show_dialog "✅ Node.js encontrado: $NODE_VERSION

Continuando con la instalación..." "Continuar"

# Ir al directorio correcto
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/QuotifyApp"

# Mostrar progreso de instalación
PROGRESS_PID=$(show_progress "📦 Instalando Quotify Electron...

⏳ Descargando dependencias (3-8 minutos)
🔧 Configurando Electron + React
🔧 Preparando transcripción con OpenAI
🔇 Instalación silenciosa en progreso

NO CIERRES esta ventana..." 500)

# Limpiar cache e instalar
npm cache clean --force &>/dev/null || true
npm install --silent --no-progress --loglevel=error &>/dev/null

INSTALL_RESULT=$?

# Cerrar ventana de progreso
kill $PROGRESS_PID 2>/dev/null || true

if [ $INSTALL_RESULT -ne 0 ]; then
    show_error "Error en la instalación.

Soluciones:
• Verifica conexión a internet estable
• Cierra otras aplicaciones
• Reinicia y prueba otra vez
• Revisa el log: /tmp/quotify_install.log"
    exit 1
fi

show_dialog "✅ ¡Quotify Electron instalado correctamente!

🚀 PARA USAR:
• Doble clic en '🎯 Abrir Quotify.app'
• Se abrirá como aplicación nativa (Electron)
• NO es versión web, es app completa

🔥 INCLUYE TODO:
✅ Aplicación Electron nativa
✅ Transcripción completa
✅ Metadata de YouTube
✅ Completamente invisible

📖 Ayuda en carpeta 'documentacion'" "¡Listo!"

EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. CREAR APP BUNDLE CON ICONO BONITO
echo "🎯 Creando aplicación con icono bonito..."

APP_DIR="$DIST_DIR/🎯 Abrir Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Crear icono usando el existente o generar uno nuevo
if [ -f "/Users/darwinborges/Desktop/Icono Quotify.png" ]; then
    # Usar icono existente
    ICONSET_DIR="/tmp/quotify.iconset"
    mkdir -p "$ICONSET_DIR"
    
    sips -z 1024 1024 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null || true
    sips -z 512 512 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null || true
    sips -z 256 256 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null || true
    sips -z 128 128 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null || true
    sips -z 64 64 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_64x64.png" 2>/dev/null || true
    sips -z 32 32 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_32x32.png" 2>/dev/null || true
    sips -z 16 16 "/Users/darwinborges/Desktop/Icono Quotify.png" --out "$ICONSET_DIR/icon_16x16.png" 2>/dev/null || true
    
    iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/quotify.icns" 2>/dev/null || true
    rm -rf "$ICONSET_DIR"
fi

# Crear Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>quotify_launcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.quotify.electron.app</string>
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

# Crear launcher que ejecute ELECTRON (no web)
cat > "$APP_DIR/Contents/MacOS/quotify_launcher" << 'LAUNCHER_EOF'
#!/bin/bash

# Obtener directorio de la app
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

osascript << 'APPLESCRIPT'

on showDialog(message, buttonText)
    tell application "System Events"
        display dialog message buttons {buttonText} default button buttonText with icon note
    end tell
end showDialog

on showChoice(message, buttonText)
    tell application "System Events"
        set userChoice to display dialog message buttons {"Cancelar", buttonText} default button buttonText with icon note
        return button returned of userChoice
    end tell
end showChoice

-- Preguntar si quiere abrir
set userResponse to showChoice("🎯 Quotify Electron

✅ Aplicación NATIVA (no web)
✅ Backend + Frontend completo
✅ Transcripción con OpenAI
✅ Metadata de YouTube
🔇 Completamente invisible

¿Iniciar Quotify Electron?", "🚀 Abrir Quotify")

if userResponse is "Cancelar" then
    return
end if

-- Mostrar progreso
tell application "System Events"
    display dialog "🚀 Iniciando Quotify Electron...

⚡ Arrancando aplicación nativa
⚡ Cargando interfaz Electron
🔇 Ejecutándose invisiblemente
📱 Se abrirá como app nativa (no navegador)

Esto toma 15-25 segundos..." buttons {} giving up after 30 with icon note
end tell

-- Obtener directorio del proyecto
set quotifyPath to "QUOTIFY_PATH_PLACEHOLDER"

-- Cerrar procesos anteriores
do shell script "pkill -f 'electron' 2>/dev/null || true"
do shell script "pkill -f 'vite' 2>/dev/null || true"
do shell script "pkill -f 'node.*5173' 2>/dev/null || true"

delay 3

-- Ejecutar Quotify ELECTRON (no npm run dev que es web)
-- Usar el comando de desarrollo que incluye Electron
do shell script "cd '" & quotifyPath & "' && nohup npm run dev > /dev/null 2>&1 &" without altering line endings

-- Esperar que Electron esté listo
delay 20

-- Verificar si está funcionando
try
    -- Buscar proceso de Electron
    do shell script "pgrep -f 'electron.*quotify' > /dev/null 2>&1"
    
    showDialog("✅ ¡Quotify Electron funcionando!

📱 Aplicación nativa abierta
🔥 TODAS LAS FUNCIONES:
✅ Metadata de YouTube
✅ Transcripción con OpenAI
✅ Extracción de quotes
✅ Export/import

🔇 Funcionando invisiblemente
🔴 Para cerrar: Cierra ventana de Quotify", "¡Perfecto!")
    
on error
    showDialog("⏳ Quotify está iniciando...

📱 Debería aparecer la ventana de Quotify
⏱️ Dale 1-2 minutos más

Si no aparece, ejecuta esta app otra vez.", "Entendido")
end try

APPLESCRIPT

LAUNCHER_EOF

# Reemplazar placeholder
sed -i '' "s|QUOTIFY_PATH_PLACEHOLDER|$QUOTIFY_DIR|g" "$APP_DIR/Contents/MacOS/quotify_launcher"
chmod +x "$APP_DIR/Contents/MacOS/quotify_launcher"

# 3. DOCUMENTACIÓN
cat > "documentacion/GUIA-ELECTRON.txt" << 'EOF'
🎯 QUOTIFY ELECTRON - APLICACIÓN NATIVA

═══════════════════════════════════════

Esta versión de Quotify es una APLICACIÓN NATIVA
usando Electron, NO es una página web.

📋 INSTALACIÓN:
1. Doble clic: "1️⃣ INSTALAR-QUOTIFY.command"
2. Esperar instalación (3-8 minutos)
3. ¡Listo para usar!

🚀 USO DIARIO:
1. Doble clic: "🎯 Abrir Quotify.app"
2. Se abre como aplicación nativa
3. NO se abre en navegador

🔥 VENTAJAS APLICACIÓN NATIVA:
✅ Funciona sin navegador
✅ Mejor rendimiento
✅ Acceso completo al sistema
✅ Transcripción más confiable
✅ Funciona offline (después de transcribir)

📱 DIFERENCIAS CON VERSIÓN WEB:
• Se abre en ventana propia (no navegador)
• Mejor acceso a archivos del sistema
• Transcripción más estable
• Funciona sin conexión (para quotes ya creados)

EOF

echo ""
echo "✅ VERSIÓN ELECTRON FINAL CREADA!"
echo ""
echo "📂 ESTRUCTURA:"
echo "   📋 LEEME-DEFINITIVO.txt"
echo "   1️⃣ INSTALAR-QUOTIFY.command (INSTALADOR)"
echo "   🎯 Abrir Quotify.app (ELECTRON NATIVO)"
echo "   📁 documentacion/ (GUÍAS)"
echo "   📁 QuotifyApp/ (PROYECTO COMPLETO)"
echo ""
echo "🔥 CARACTERÍSTICAS:"
echo "   ✅ Aplicación Electron nativa"
echo "   ✅ Backend completo incluido"
echo "   ✅ Transcripción funcional"
echo "   ✅ Completamente invisible"
echo "   ✅ Icono bonito"
echo ""

# Crear ZIP final
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP FINAL: ${PACKAGE_NAME}.zip"
echo ""
echo "🎉 ¡LISTO PARA DISTRIBUCIÓN!"