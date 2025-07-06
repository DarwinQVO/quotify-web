#!/bin/bash

echo "🎯 Quotify - VERSIÓN FINAL CON GESTIÓN DE PUERTOS"
echo "================================================"

PACKAGE_NAME="Quotify-FINAL-PUERTO-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando versión FINAL con gestión de puertos..."

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

# 1. INSTALADOR
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'INSTALL_EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación"
echo "========================"

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
    echo "⚠️ yt-dlp no instalado (necesario para transcripciones)"
fi

echo ""
echo "📦 Instalando dependencias..."
"$NPM_PATH" install

echo ""
echo "✅ ¡Instalación completada!"
echo ""
read -p "Presiona Enter para continuar..."
INSTALL_EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. CERRAR QUOTIFY
cat > "2️⃣ CERRAR-QUOTIFY.command" << 'CLOSE_EOF'
#!/bin/bash

echo "🛑 Cerrando Quotify..."
echo "====================="
echo ""

# Cerrar todos los procesos de Quotify
echo "Cerrando procesos..."

# Electron
pkill -f "electron.*quotify" 2>/dev/null && echo "✅ Electron cerrado" || echo "• Electron no estaba abierto"

# Vite
pkill -f "vite" 2>/dev/null && echo "✅ Vite cerrado" || echo "• Vite no estaba abierto"

# Node en puerto 5173
lsof -ti:5173 | xargs kill -9 2>/dev/null && echo "✅ Puerto 5173 liberado" || echo "• Puerto 5173 ya estaba libre"

# Esperar
sleep 2

echo ""
echo "✅ Quotify cerrado completamente"
echo ""
read -p "Presiona Enter para salir..."
CLOSE_EOF

chmod +x "2️⃣ CERRAR-QUOTIFY.command"

# 3. APP BUNDLE MEJORADO
APP_DIR="$DIST_DIR/🎯 Abrir Quotify.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copiar icono
if [ -f "/Users/darwinborges/Desktop/Icono Quotify.png" ]; then
    ICONSET_DIR="/tmp/quotify_final_puerto.iconset"
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
    <string>com.quotify.final.puerto</string>
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

# LAUNCHER FINAL ROBUSTO
cat > "$APP_DIR/Contents/MacOS/quotify_launcher" << 'LAUNCHER_EOF'
#!/bin/bash

# Directorio de la app
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

# RUTAS HARDCODED
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
if ! show_choice "🎯 Quotify - Aplicación Final

✅ Versión estable y completa
✅ Gestión automática de puertos
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

# CERRAR PROCESOS ANTERIORES AGRESIVAMENTE
{
    # Matar cualquier proceso en el puerto 5173
    lsof -ti:5173 | xargs kill -9 2>/dev/null
    
    # Matar procesos de Electron
    pkill -9 -f "electron.*quotify" 2>/dev/null
    
    # Matar procesos de Vite
    pkill -9 -f "vite" 2>/dev/null
    
    # Matar procesos npm relacionados
    pkill -9 -f "npm.*dev" 2>/dev/null
    
    # Esperar que se cierren
    sleep 3
} &>/dev/null

# Mostrar progreso
show_dialog "🚀 Iniciando Quotify...

⚡ Cerrando instancias anteriores
⏱️ Preparando nueva sesión
🔇 Sin terminal visible

¡Espera 20 segundos!" "Entendido" &

# LOG
LOG_FILE="/tmp/quotify_final_$(date +%s).log"

# EJECUTAR CON TIMEOUT Y REINTENTOS
{
    echo "=== Quotify Final Log $(date) ==="
    echo "PWD: $(pwd)"
    echo "Node: $NODE_PATH"
    echo "npm: $NPM_PATH"
    echo "PATH: $PATH"
    echo "yt-dlp: $(which yt-dlp || echo 'not found')"
    echo ""
    
    # Intento 1: Normal
    echo "=== Intento 1: npm run dev ==="
    timeout 30 "$NPM_PATH" run dev 2>&1
    
    # Si falla, intento 2: Manual
    if [ $? -ne 0 ]; then
        echo ""
        echo "=== Intento 2: Manual startup ==="
        
        # Limpiar puerto otra vez
        lsof -ti:5173 | xargs kill -9 2>/dev/null
        sleep 2
        
        # Iniciar Vite
        "$NPM_PATH" run dev:vite &
        VITE_PID=$!
        
        # Esperar Vite
        sleep 10
        
        # Iniciar Electron
        "$NPM_PATH" run dev:electron &
        ELECTRON_PID=$!
        
        # Mantener vivos los procesos
        wait
    fi
} > "$LOG_FILE" 2>&1 &

# Esperar arranque
sleep 25

# Verificar resultado
if pgrep -f "electron.*quotify" >/dev/null; then
    show_dialog "✅ ¡Quotify funcionando!

📱 Aplicación abierta
🔇 Sin terminal visible
✨ Todas las funciones activas

Si no ves la ventana:
• Revisa el Dock
• Usa Command+Tab" "¡Perfecto!"
else
    # Verificar si el puerto está ocupado
    if lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null 2>&1; then
        show_dialog "⚠️ Puerto 5173 ocupado

Cierra otras aplicaciones o usa:
'2️⃣ CERRAR-QUOTIFY.command'

Luego intenta abrir otra vez." "Entendido"
    else
        show_dialog "⚠️ Quotify no pudo abrir

Prueba:
1. Ejecutar '2️⃣ CERRAR-QUOTIFY.command'
2. Reiniciar la computadora
3. Revisar log: $LOG_FILE" "Entendido"
    fi
fi

LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/quotify_launcher"

# LEEME
cat > "LEEME-FINAL.txt" << 'README_EOF'
🎯 QUOTIFY - VERSIÓN FINAL ESTABLE

==================================

✅ GESTIÓN AUTOMÁTICA DE PUERTOS
✅ CIERRE LIMPIO DE PROCESOS
✅ SIN TERMINAL VISIBLE

📋 USO:
1. Instalar: "1️⃣ INSTALAR-QUOTIFY.command"
2. Abrir: "🎯 Abrir Quotify.app"
3. Cerrar: "2️⃣ CERRAR-QUOTIFY.command"

🔧 SI HAY PROBLEMAS:
• Ejecuta "2️⃣ CERRAR-QUOTIFY" antes de abrir
• Esto limpia puertos y procesos

¡Versión final y estable!
README_EOF

echo ""
echo "✅ VERSIÓN FINAL CON GESTIÓN DE PUERTOS!"
echo ""
echo "📦 INCLUYE:"
echo "   1️⃣ Instalador"
echo "   2️⃣ Cerrador de procesos"
echo "   🎯 App mejorada"
echo ""

# ZIP
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "🎯 ¡VERSIÓN FINAL LISTA!"
echo ""
echo "💡 IMPORTANTE: Si falla, usa primero:"
echo "   '2️⃣ CERRAR-QUOTIFY.command'"