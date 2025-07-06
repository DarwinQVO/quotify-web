#!/bin/bash

echo "✨ Quotify v2.0 - VERSIÓN LIMPIA"
echo "==============================="

PACKAGE_NAME="Quotify-v2.0-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando Quotify v2.0..."

# Copiar la versión que funcionaba
rm -rf "$DIST_DIR"
cp -r "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349" "$DIST_DIR"

cd "$DIST_DIR"

echo "🔧 Aplicando cambios superficiales..."

# CAMBIO 1: Quitar consola
sed -i '' 's/mainWindow.webContents.openDevTools();/\/\/ mainWindow.webContents.openDevTools(); \/\/ Sin consola/' "QuotifyApp/src/main/index.js"

# CAMBIO 2: Agregar icono
sed -i '' '/minHeight: 700,/a\
    icon: path.join(__dirname, "..\/..\/public\/icon.png"),
' "QuotifyApp/src/main/index.js"

# Copiar icono
mkdir -p "QuotifyApp/public"
cp "/Users/darwinborges/Desktop/Icono Quotify.png" "QuotifyApp/public/icon.png"

echo "🗑️ Eliminando comandos innecesarios..."

# Eliminar comandos 2️⃣ y 3️⃣
rm -f "2️⃣"* "3️⃣"* 2>/dev/null

# Renombrar app con el nombre v2.0
mv "🎯 Abrir Quotify.app" "Quotify v2.0.app"

# Actualizar Info.plist con el nuevo nombre
cat > "Quotify v2.0.app/Contents/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>quotify_launcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.quotify.v2</string>
    <key>CFBundleName</key>
    <string>Quotify v2.0</string>
    <key>CFBundleDisplayName</key>
    <string>Quotify v2.0</string>
    <key>CFBundleVersion</key>
    <string>2.0</string>
    <key>CFBundleIconFile</key>
    <string>quotify</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

# Actualizar launcher con mensaje v2.0
cat > "Quotify v2.0.app/Contents/MacOS/quotify_launcher" << 'LAUNCHER_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUOTIFY_DIR="$DIR/../../../QuotifyApp"

export PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
NODE_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/node"
NPM_PATH="/Users/darwinborges/.nvm/versions/node/v20.19.2/bin/npm"

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
if ! show_choice "✨ Quotify v2.0

🚫 Sin consola molesta
🎨 Logo propio incluido
✅ Todas las funciones activas
🎵 Transcripción funcionando

¿Iniciar Quotify v2.0?" "🚀 Abrir"; then
    exit 0
fi

# Verificar instalación
if [ ! -d "$QUOTIFY_DIR/node_modules" ]; then
    show_dialog "❌ Quotify no está instalado

Por favor ejecuta primero:
'1️⃣ INSTALAR-QUOTIFY.command'" "Entendido"
    exit 1
fi

cd "$QUOTIFY_DIR"

# Cerrar anteriores
pkill -f "electron.*quotify" 2>/dev/null || true
pkill -f "vite.*5173" 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 2

# Mostrar progreso
show_dialog "🚀 Iniciando Quotify v2.0...

✨ Sin consola molesta
🎨 Con logo propio
⏱️ Espera 20 segundos

¡Se abrirá automáticamente!" "Entendido" &

# Ejecutar
LOG="/tmp/quotify_v2_$(date +%s).log"
{
    echo "=== Quotify v2.0 Log $(date) ==="
    echo "PWD: $(pwd)"
    echo "Node: $NODE_PATH"
    echo "npm: $NPM_PATH"
    
    "$NPM_PATH" run dev
} > "$LOG" 2>&1 &

sleep 20

if pgrep -f "electron.*quotify" >/dev/null; then
    show_dialog "✅ ¡Quotify v2.0 funcionando!

🚫 Sin consola molesta
🎨 Logo propio activo
📱 Aplicación limpia
🎵 Transcripción lista

¡Disfruta Quotify v2.0!" "¡Perfecto!"
else
    show_dialog "⚠️ Quotify v2.0 tardó en abrir

Espera un poco más o revisa:
$LOG" "Entendido"
fi

LAUNCHER_EOF

chmod +x "Quotify v2.0.app/Contents/MacOS/quotify_launcher"

# Actualizar instalador para mencionar v2.0
sed -i '' 's/🎯 Abrir Quotify.app/Quotify v2.0.app/' "1️⃣ INSTALAR-QUOTIFY.command"

# LEEME actualizado
cat > "LEEME-v2.0.txt" << 'README_EOF'
✨ QUOTIFY v2.0 - VERSIÓN LIMPIA

===============================

La versión más limpia y funcional.

📋 SOLO 2 ARCHIVOS:

1. "1️⃣ INSTALAR-QUOTIFY.command"
   (Solo la primera vez)

2. "Quotify v2.0.app" 
   (La app con icono bonito)

✨ NOVEDADES v2.0:
🚫 Sin consola molesta
🎨 Logo propio en Cmd+Tab
🗑️ Sin comandos innecesarios
📱 Interfaz más limpia

✅ MANTIENE TODO:
✅ Transcripción funcionando
✅ Metadata de YouTube
✅ Todas las funciones
✅ Mismo rendimiento

¡La versión más simple y elegante!
README_EOF

echo ""
echo "✨ QUOTIFY v2.0 CREADO!"
echo ""
echo "📦 SOLO 2 ARCHIVOS:"
echo "   1️⃣ Instalador"
echo "   ✨ Quotify v2.0.app"
echo ""
echo "🗑️ ELIMINADOS:"
echo "   ❌ Comando 2️⃣"
echo "   ❌ Comando 3️⃣"
echo ""
echo "✨ MEJORAS v2.0:"
echo "   🚫 Sin consola"
echo "   🎨 Logo propio"
echo "   🗑️ Sin archivos extras"

cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "✨ ¡QUOTIFY v2.0 LISTO!"