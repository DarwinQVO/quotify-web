#!/bin/bash

echo "🎯 Quotify - Versión Organizada y Limpia"
echo "======================================="

PACKAGE_NAME="Quotify-FACIL-$(date +%Y%m%d)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando paquete super organizado..."

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

# 1. INSTALADOR PRINCIPAL (en la raíz)
cat > "1️⃣ INSTALAR-QUOTIFY.command" << 'EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación Fácil"
echo "============================="

# Ir al directorio del proyecto
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/proyecto"

# Verificar Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado."
    echo ""
    echo "📥 POR FAVOR INSTALA Node.js PRIMERO:"
    echo "   1. Ve a: https://nodejs.org/"
    echo "   2. Descarga la versión LTS"
    echo "   3. Instala y ejecuta este archivo otra vez"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 1
fi

echo "✅ Node.js encontrado: $(node --version)"
echo ""

# Instalar dependencias
echo "📦 Instalando Quotify (puede tomar unos minutos)..."
echo "💡 No cierres esta ventana..."
echo ""

npm cache clean --force 2>/dev/null || true
npm install --silent

if [ $? -ne 0 ]; then
    echo "❌ Error en la instalación"
    echo ""
    echo "🔧 SOLUCIONES:"
    echo "   1. Verifica tu conexión a internet"
    echo "   2. Cierra todas las aplicaciones"
    echo "   3. Reinicia tu computadora"
    echo "   4. Ejecuta este instalador otra vez"
    echo ""
    read -p "Presiona Enter para salir..."
    exit 1
fi

# Crear launcher en la raíz
cat > "../2️⃣ ABRIR-QUOTIFY.command" << 'LAUNCHER_EOF'
#!/bin/bash

echo "🎯 Iniciando Quotify..."
echo "====================="

# Ir al proyecto
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/proyecto"

echo ""
echo "🚀 Quotify se está iniciando..."
echo "📱 Se abrirá automáticamente en tu navegador"
echo ""
echo "💡 IMPORTANTE:"
echo "   • Mantén esta ventana abierta mientras uses Quotify"
echo "   • Para cerrar Quotify: presiona Ctrl+C aquí"
echo ""

# Cerrar procesos anteriores
if lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "🔄 Cerrando Quotify anterior..."
    pkill -f "vite.*5173" 2>/dev/null || true
    pkill -f "electron.*quotify" 2>/dev/null || true
    sleep 3
fi

# Abrir navegador después de que inicie
(sleep 6 && open http://localhost:5173) &

# Iniciar Quotify completo
npm run dev

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

echo ""
echo "✅ ¡Quotify instalado correctamente!"
echo ""
echo "🚀 PARA USAR QUOTIFY:"
echo "   Opción 1: Doble clic en '🎯 Quotify.command' en tu Desktop"
echo "   Opción 2: Doble clic en '2️⃣ ABRIR-QUOTIFY.command' aquí"
echo ""
echo "🎉 ¡YA ESTÁ LISTO!"
echo ""

read -p "Presiona Enter para continuar..."

EOF

chmod +x "1️⃣ INSTALAR-QUOTIFY.command"

# 2. CREAR DOCUMENTACIÓN ORGANIZADA
cat > "documentacion/COMO-USAR.txt" << 'EOF'
🎯 QUOTIFY - GUÍA COMPLETA

═══════════════════════════════════════

📋 PASOS PARA INSTALAR:
1. Doble clic en "1️⃣ INSTALAR-QUOTIFY.command"
2. Esperar que termine la instalación
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

🔑 API KEY DE OPENAI:
• Consigue en: https://platform.openai.com/api-keys
• Se guarda seguro en tu computadora
• Solo se usa para transcribir

🔴 PARA CERRAR:
Presiona Ctrl+C en la ventana de terminal

💾 TUS DATOS:
Todo se guarda en tu navegador localmente.
Usa "Export" para respaldar tus quotes.

🆘 PROBLEMAS COMUNES:

• "Node.js no encontrado":
  Instala desde https://nodejs.org/

• "Error en instalación":
  Revisa tu internet y reinicia

• "Transcripción falla":
  Verifica tu API key de OpenAI

• "Se cierra solo":
  No cierres la ventana de terminal

EOF

cat > "documentacion/REQUISITOS.txt" << 'EOF'
🔧 REQUISITOS PARA QUOTIFY

═══════════════════════════════════════

✅ NECESARIO:
• macOS (cualquier versión reciente)
• Node.js 18 o superior
• Conexión a internet
• API key de OpenAI (para transcribir)

📥 DESCARGAR NODE.JS:
• Ve a: https://nodejs.org/
• Descarga versión LTS (recomendada)
• Instala normalmente

🔑 CONSEGUIR API KEY:
• Ve a: https://platform.openai.com/api-keys
• Crea cuenta si no tienes
• Genera nueva API key
• Copia y guarda seguro

💰 COSTOS:
• Quotify: GRATIS
• Node.js: GRATIS
• OpenAI: ~$0.006 por minuto de audio

⚡ RENDIMIENTO:
• Video de 10 min ≈ $0.06 USD
• Transcripción toma 2-5 minutos
• Funciona offline después de transcribir

EOF

cat > "documentacion/SOLUCION-PROBLEMAS.txt" << 'EOF'
🆘 SOLUCIÓN DE PROBLEMAS

═══════════════════════════════════════

❌ "Node.js no está instalado"
🔧 SOLUCIÓN:
   1. Ve a https://nodejs.org/
   2. Descarga versión LTS
   3. Instala y reinicia
   4. Ejecuta instalador otra vez

❌ "Error en la instalación"
🔧 SOLUCIÓN:
   1. Verifica conexión a internet
   2. Cierra todas las aplicaciones
   3. Reinicia computadora
   4. Ejecuta instalador otra vez

❌ "Transcripción falla"
🔧 SOLUCIÓN:
   1. Verifica API key de OpenAI
   2. Checa tu saldo en OpenAI
   3. Intenta con video más corto
   4. Reinicia Quotify

❌ "Quotify se cierra solo"
🔧 SOLUCIÓN:
   1. NO cierres la ventana de terminal
   2. Si se cerró, abre otra vez
   3. Verifica que puerto 5173 esté libre

❌ "No se abre en navegador"
🔧 SOLUCIÓN:
   1. Abre manual: http://localhost:5173
   2. Verifica que terminal siga abierto
   3. Espera un poco más (puede tardar)

❌ "YouTube no funciona"
🔧 SOLUCIÓN:
   1. Verifica que URL sea de YouTube
   2. Prueba con video público
   3. Copia URL completa

💡 CONSEJOS:
• Usa videos de menos de 30 minutos
• Ten buena conexión a internet
• Mantén ventana de terminal abierta
• Guarda API key en lugar seguro

EOF

# Crear README principal bonito
cat > "LEEME-PRIMERO.txt" << 'EOF'
🎯 BIENVENIDO A QUOTIFY

═══════════════════════════════════════

¡Hola! Este es Quotify, la herramienta que convierte
videos de YouTube en quotes extraíbles perfectamente.

📋 INSTALACIÓN SÚPER FÁCIL:

   1️⃣ Doble clic: "1️⃣ INSTALAR-QUOTIFY.command"
   2️⃣ Doble clic: "2️⃣ ABRIR-QUOTIFY.command"
   
   ¡Y ya! 🎉

📖 ¿NECESITAS AYUDA?
   
   Revisa la carpeta "documentacion" donde está todo:
   • Cómo usar paso a paso
   • Requisitos del sistema  
   • Solución de problemas
   • Y más...

🔥 LO QUE HACE QUOTIFY:

   ✅ Extrae metadata de YouTube instantáneamente
   ✅ Descarga y transcribe audio automáticamente
   ✅ Te deja seleccionar texto para crear quotes
   ✅ Guarda todo localmente en tu computadora
   ✅ Exporta quotes en formato bonito

💡 CONSEJO:
   
   Si es tu primera vez, lee "COMO-USAR.txt" 
   en la carpeta documentacion.

🆘 ¿PROBLEMAS?
   
   Ve a "SOLUCION-PROBLEMAS.txt" en documentacion.

¡Disfruta Quotify! 🎯

EOF

echo ""
echo "✅ Paquete organizado creado!"
echo ""
echo "📂 ESTRUCTURA FINAL:"
echo "   📋 LEEME-PRIMERO.txt"
echo "   1️⃣ INSTALAR-QUOTIFY.command"
echo "   2️⃣ ABRIR-QUOTIFY.command" 
echo "   📁 documentacion/"
echo "      ├── COMO-USAR.txt"
echo "      ├── REQUISITOS.txt"
echo "      └── SOLUCION-PROBLEMAS.txt"
echo "   📁 proyecto/ (código fuente)"
echo ""

# Crear ZIP organizado
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP final: ${PACKAGE_NAME}.zip"
echo ""
echo "🎉 ¡PERFECTO! Ahora tu usuario solo ve:"
echo "   ✅ Los 2 archivos que necesita"
echo "   ✅ Documentación organizada"
echo "   ✅ Todo limpio y profesional"