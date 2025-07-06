#!/bin/bash

echo "🎯 Quotify - Versión Silenciosa (Sin Terminal Visible)"
echo "====================================================="

PACKAGE_NAME="Quotify-SILENCIOSO-$(date +%Y%m%d)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando paquete súper silencioso..."

# Crear directorio principal limpio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Crear subdirectorios
mkdir -p "$DIST_DIR/proyecto"
mkdir -p "$DIST_DIR/documentacion"

# Copiar TODO el proyecto a la subcarpeta
echo "📋 Copiando proyecto a subcarpeta..."
cp -r . "$DIST_DIR/proyecto/"

# Limpiar archivos innecesarios del proyecto
cd "$DIST_DIR/proyecto"
rm -rf node_modules dist-electron .git
rm -f *.zip *.dmg *.sh

# CREAR LOS 2 ARCHIVOS PRINCIPALES EN LA RAÍZ
cd "$DIST_DIR"

# 1. INSTALADOR SILENCIOSO (en la raíz)
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'EOF'
#!/bin/bash

# Crear ventana de progreso visual usando AppleScript
osascript << 'APPLESCRIPT'
tell application "System Events"
    set userChoice to display dialog "🎯 Quotify - Instalación" with text "¿Quieres instalar Quotify ahora?

✅ Se instalará automáticamente
⏱️ Tomará unos minutos
🔇 Instalación silenciosa (sin terminal)

¿Continuar?" buttons {"Cancelar", "Instalar"} default button "Instalar" with icon note
    if button returned of userChoice is "Cancelar" then
        return
    end if
end tell
APPLESCRIPT

if [ $? -ne 0 ]; then
    exit 0
fi

# Ir al directorio del proyecto
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/proyecto"

# Verificar Node.js silenciosamente
if ! command -v node &> /dev/null; then
    osascript -e 'tell application "System Events" to display dialog "❌ Node.js no está instalado

📥 Por favor instala Node.js primero:
1. Ve a: https://nodejs.org/
2. Descarga versión LTS
3. Instala y ejecuta este instalador otra vez" buttons {"Entendido"} default button "Entendido" with icon caution'
    exit 1
fi

# Mostrar progreso de instalación
osascript << 'APPLESCRIPT' &
tell application "System Events"
    set progress to display dialog "📦 Instalando Quotify...

⏳ Por favor espera, esto tomará unos minutos
🔇 Instalación en progreso (silenciosa)
💡 No cierres esta ventana" buttons {} giving up after 300 with icon note
end tell
APPLESCRIPT

PROGRESS_PID=$!

# Instalar dependencias silenciosamente
npm cache clean --force &>/dev/null || true
npm install --silent --no-progress &>/dev/null

INSTALL_SUCCESS=$?

# Cerrar ventana de progreso
kill $PROGRESS_PID 2>/dev/null || true

if [ $INSTALL_SUCCESS -ne 0 ]; then
    osascript -e 'tell application "System Events" to display dialog "❌ Error en la instalación

🔧 Soluciones:
• Verifica tu conexión a internet
• Reinicia tu computadora
• Ejecuta el instalador otra vez

¿Necesitas ayuda? Revisa la carpeta documentacion" buttons {"Entendido"} default button "Entendido" with icon stop'
    exit 1
fi

# Crear launcher silencioso
cat > "../2️⃣ ABRIR-QUOTIFY.command" << 'LAUNCHER_EOF'
#!/bin/bash

# Mostrar mensaje inicial
osascript << 'APPLESCRIPT'
tell application "System Events"
    set userChoice to display dialog "🎯 Quotify está listo

🚀 Se abrirá automáticamente en tu navegador
🔇 Funcionará en segundo plano (sin terminal visible)
💡 Para cerrar: usa el menú o reinicia tu computadora

¿Abrir Quotify?" buttons {"Cancelar", "Abrir Quotify"} default button "Abrir Quotify" with icon note
    if button returned of userChoice is "Cancelar" then
        return
    end if
end tell
APPLESCRIPT

if [ $? -ne 0 ]; then
    exit 0
fi

# Ir al proyecto
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/proyecto"

# Cerrar procesos anteriores silenciosamente
pkill -f "vite.*5173" 2>/dev/null || true
pkill -f "electron.*quotify" 2>/dev/null || true
sleep 2

# Mostrar que se está iniciando
osascript << 'APPLESCRIPT' &
tell application "System Events"
    display dialog "🚀 Iniciando Quotify...

⏳ Se abrirá en tu navegador en unos segundos
🌐 URL: http://localhost:5173
🔇 Ejecutándose silenciosamente

Esta ventana se cerrará automáticamente." buttons {} giving up after 8 with icon note
end tell
APPLESCRIPT

# Abrir navegador después de unos segundos
(sleep 10 && open http://localhost:5173) &

# Iniciar Quotify COMPLETAMENTE EN SEGUNDO PLANO
nohup npm run dev > /dev/null 2>&1 &

# Esperar un poco para que inicie
sleep 12

# Mostrar que ya está listo
osascript -e 'tell application "System Events" to display dialog "✅ ¡Quotify está funcionando!

🌐 Se abrió en tu navegador
📱 Si no se abrió, ve a: http://localhost:5173

💡 Quotify funciona en segundo plano
🔴 Para cerrar: reinicia tu computadora o usa Activity Monitor" buttons {"Entendido"} default button "Entendido" with icon note'

LAUNCHER_EOF

chmod +x "../2️⃣ ABRIR-QUOTIFY.command"

# Crear acceso directo en Desktop
DESKTOP_SHORTCUT="$HOME/Desktop/🎯 Quotify.command"
cat > "$DESKTOP_SHORTCUT" << DESKTOP_EOF
#!/bin/bash
cd "$DIR"
./2️⃣\\ ABRIR-QUOTIFY.command
DESKTOP_EOF

chmod +x "$DESKTOP_SHORTCUT"

# Mostrar éxito
osascript -e 'tell application "System Events" to display dialog "✅ ¡Quotify instalado correctamente!

🚀 PARA USAR QUOTIFY:
• Doble clic en: 2️⃣ ABRIR-QUOTIFY.command
• O usa el acceso directo en tu Desktop

🔇 Todo funcionará silenciosamente
📖 Ayuda disponible en carpeta documentacion" buttons {"Perfecto"} default button "Perfecto" with icon note'

EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. CREAR DOCUMENTACIÓN ACTUALIZADA
cat > "documentacion/COMO-USAR-SILENCIOSO.txt" << 'EOF'
🎯 QUOTIFY SILENCIOSO - GUÍA COMPLETA

═══════════════════════════════════════

🔇 ESTA VERSIÓN ES COMPLETAMENTE SILENCIOSA:
• No verás ventanas de terminal
• Todo funciona en segundo plano
• Solo ventanas informativas bonitas

📋 PASOS PARA INSTALAR:
1. Doble clic en "1️⃣ INSTALAR-QUOTIFY.command"
2. Seguir las ventanas que aparecen
3. Doble clic en "2️⃣ ABRIR-QUOTIFY.command"

📱 CÓMO USAR QUOTIFY:

1️⃣ AGREGAR VIDEO:
   • Copia URL de cualquier video de YouTube
   • Pega en campo "Add Source"
   • Clic "Add Source"

2️⃣ TRANSCRIBIR:
   • Clic en "Transcribe" en el video
   • Ingresa API key de OpenAI
   • Espera que termine (puede tomar varios minutos)

3️⃣ CREAR QUOTES:
   • Ve la transcripción en panel derecho
   • Selecciona texto para crear quotes
   • Los quotes se guardan automáticamente

🔴 PARA CERRAR QUOTIFY:
• Opción 1: Reinicia tu computadora
• Opción 2: Abre Activity Monitor y termina proceso "node"
• Opción 3: En terminal ejecuta: pkill -f "vite.*5173"

💡 DIFERENCIAS CON VERSIÓN NORMAL:
✅ No hay ventanas de terminal asustadoras
✅ Todo funciona en segundo plano
✅ Ventanas informativas bonitas
✅ Más fácil para usuarios no técnicos

EOF

cat > "documentacion/CERRAR-QUOTIFY.txt" << 'EOF'
🔴 CÓMO CERRAR QUOTIFY SILENCIOSO

═══════════════════════════════════════

Como Quotify funciona en segundo plano silenciosamente,
aquí tienes varias formas de cerrarlo:

🟢 FORMA MÁS FÁCIL:
   Reinicia tu computadora

🟡 FORMA INTERMEDIA:
   1. Abre "Activity Monitor" (Spotlight: Activity Monitor)
   2. Busca proceso "node" o "electron"
   3. Selecciona y clic "Force Quit"

🔴 FORMA TÉCNICA:
   1. Abre Terminal
   2. Ejecuta: pkill -f "vite.*5173"
   3. Ejecuta: pkill -f "electron.*quotify"

💡 NOTA:
   En la versión silenciosa, Quotify funciona en segundo
   plano para no molestar con ventanas técnicas.

🔄 PARA REINICIAR:
   Después de cerrar, simplemente ejecuta otra vez:
   "2️⃣ ABRIR-QUOTIFY.command"

EOF

# Crear README principal actualizado
cat > "LEEME-PRIMERO-SILENCIOSO.txt" << 'EOF'
🎯 BIENVENIDO A QUOTIFY SILENCIOSO

═══════════════════════════════════════

¡Hola! Esta es la versión SILENCIOSA de Quotify.

🔇 ¿QUÉ SIGNIFICA "SILENCIOSO"?
   • No verás ventanas técnicas de terminal
   • Todo funciona en segundo plano
   • Solo ventanas informativas bonitas
   • Perfecto para usuarios no técnicos

📋 INSTALACIÓN SÚPER FÁCIL:

   1️⃣ Doble clic: "1️⃣ INSTALAR-QUOTIFY.command"
      → Sigues las ventanas que aparecen
   
   2️⃣ Doble clic: "2️⃣ ABRIR-QUOTIFY.command"
      → Se abre automáticamente en navegador
   
   ¡Y ya! 🎉

📖 ¿NECESITAS AYUDA?
   
   Revisa la carpeta "documentacion":
   • COMO-USAR-SILENCIOSO.txt
   • CERRAR-QUOTIFY.txt
   • REQUISITOS.txt
   • SOLUCION-PROBLEMAS.txt

🔥 LO QUE HACE QUOTIFY:

   ✅ Extrae metadata de YouTube instantáneamente
   ✅ Descarga y transcribe audio automáticamente
   ✅ Te deja seleccionar texto para crear quotes
   ✅ Guarda todo localmente en tu computadora
   ✅ Exporta quotes en formato bonito

🔇 VENTAJAS VERSIÓN SILENCIOSA:

   ✅ Sin ventanas técnicas asustadoras
   ✅ Ventanas informativas bonitas
   ✅ Funciona en segundo plano
   ✅ Perfecto para cualquier usuario

💡 PARA CERRAR:
   Reinicia tu computadora o ve a "CERRAR-QUOTIFY.txt"

¡Disfruta Quotify sin complicaciones! 🎯

EOF

echo ""
echo "✅ Paquete SILENCIOSO creado!"
echo ""
echo "📂 ESTRUCTURA FINAL:"
echo "   📋 LEEME-PRIMERO-SILENCIOSO.txt"
echo "   1️⃣ INSTALAR-QUOTIFY.command (CON VENTANAS BONITAS)"
echo "   2️⃣ ABRIR-QUOTIFY.command (SIN TERMINAL VISIBLE)"
echo "   📁 documentacion/"
echo "      ├── COMO-USAR-SILENCIOSO.txt"
echo "      ├── CERRAR-QUOTIFY.txt"
echo "      ├── REQUISITOS.txt"
echo "      └── SOLUCION-PROBLEMAS.txt"
echo "   📁 proyecto/ (código fuente)"
echo ""

# Crear ZIP organizado
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP final: ${PACKAGE_NAME}.zip"
echo ""
echo "🎉 ¡PERFECTO! Ahora:"
echo "   🔇 SIN ventanas de terminal asustadoras"
echo "   ✅ Solo ventanas informativas bonitas"
echo "   🎯 Perfecto para usuarios no técnicos"
echo "   📱 Todo funciona en segundo plano"