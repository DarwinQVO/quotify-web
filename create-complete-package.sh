#!/bin/bash

echo "🎯 Quotify - Paquete Completo con Backend"
echo "========================================"

# Variables
CURRENT_DIR="$(pwd)"
PACKAGE_NAME="quotify-completo-$(date +%Y%m%d)"
DIST_DIR="$CURRENT_DIR/$PACKAGE_NAME"

echo "📦 Creando paquete completo..."

# Crear directorio de distribución
mkdir -p "$DIST_DIR"

# Copiar TODOS los archivos necesarios (incluyendo main y preload)
echo "📋 Copiando archivos del proyecto..."
cp -r src "$DIST_DIR/"
cp -r public "$DIST_DIR/"
cp package.json "$DIST_DIR/"
cp package-lock.json "$DIST_DIR/"
cp vite.config.ts "$DIST_DIR/"
cp tsconfig.json "$DIST_DIR/"
cp tsconfig.node.json "$DIST_DIR/"
cp tailwind.config.js "$DIST_DIR/"
cp postcss.config.js "$DIST_DIR/"
cp index.html "$DIST_DIR/"

# Verificar que existe el backend de Electron
if [ -f "src/main/index.js" ]; then
    echo "✅ Backend de Electron encontrado"
else
    echo "❌ Falta el backend de Electron"
    exit 1
fi

# Crear installer completo para el usuario final
cat > "$DIST_DIR/INSTALAR.command" << 'EOF'
#!/bin/bash

echo "🎯 Quotify - Instalación Completa"
echo "================================"

# Obtener directorio del script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Verificar Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado."
    echo "📥 Descarga desde: https://nodejs.org/"
    echo "   Elige la versión LTS, después ejecuta este instalador otra vez."
    read -p "Presiona Enter para salir..."
    exit 1
fi

NODE_VERSION=$(node --version)
echo "✅ Node.js encontrado: $NODE_VERSION"

# Instalar dependencias
echo "📦 Instalando dependencias (puede tomar varios minutos)..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Error instalando dependencias"
    read -p "Presiona Enter para salir..."
    exit 1
fi

# Crear launcher que inicia TODO (frontend + backend)
cat > abrir-quotify.command << 'LAUNCHER_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🎯 Iniciando Quotify Completo..."
echo ""
echo "🔧 Iniciando servidor backend..."
echo "🌐 Quotify se abrirá automáticamente"
echo "💡 Mantén esta ventana abierta mientras uses Quotify"
echo "🔴 Para cerrar Quotify, presiona Ctrl+C aquí"
echo ""

# Verificar puerto
if lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Puerto 5173 en uso. Cerrando proceso anterior..."
    pkill -f "vite.*5173" 2>/dev/null || true
    sleep 2
fi

# Abrir navegador después de que inicie el servidor
(sleep 5 && open http://localhost:5173) &

# Iniciar Quotify con backend completo (igual que npm run dev)
npm run dev

LAUNCHER_EOF

chmod +x abrir-quotify.command

# Crear acceso directo en Desktop
DESKTOP_SHORTCUT="$HOME/Desktop/🎯 Quotify.command"
cat > "$DESKTOP_SHORTCUT" << DESKTOP_EOF
#!/bin/bash
cd "$DIR"
./abrir-quotify.command
DESKTOP_EOF

chmod +x "$DESKTOP_SHORTCUT"

echo ""
echo "✅ ¡Instalación de Quotify completada!"
echo ""
echo "🚀 Para usar Quotify:"
echo "   1. Doble clic en '🎯 Quotify.command' en tu Desktop"
echo "   2. O doble clic en 'abrir-quotify.command' en esta carpeta"
echo ""
echo "📖 ¿Necesitas ayuda? Lee el archivo COMO_USAR.txt"
echo ""

# Esperar para que el usuario vea el mensaje
read -p "Presiona Enter para continuar..."

EOF

# Crear manual en español
cat > "$DIST_DIR/COMO_USAR.txt" << 'EOF'
🎯 QUOTIFY - CÓMO USAR

📋 INICIO RÁPIDO:
1. Doble clic en "INSTALAR.command" (solo la primera vez)
2. Doble clic en "🎯 Quotify.command" en tu Desktop para iniciar
3. Usa Quotify en tu navegador

📱 USANDO QUOTIFY:

1. AGREGAR VIDEO DE YOUTUBE:
   - Copia cualquier URL de video de YouTube
   - Pega en el campo "Add Source"
   - Clic en "Add Source"

2. TRANSCRIBIR AUDIO:
   - Clic en "Transcribe" en tu video
   - Ingresa tu API key de OpenAI (la obtienes en: https://platform.openai.com/api-keys)
   - Espera a que termine la transcripción

3. EXTRAER QUOTES:
   - Ve la transcripción en el panel derecho
   - Selecciona texto para crear quotes
   - Los quotes se guardan automáticamente

🔧 SOLUCIÓN DE PROBLEMAS:

• "Node.js no encontrado":
  Descarga desde https://nodejs.org/ (elige versión LTS)

• "Puerto ya en uso":
  Cierra otras ventanas de Quotify y reinicia

• Errores de permisos:
  Clic derecho en archivos .command y selecciona "Abrir"

• Se borra al hacer refresh:
  ¡Esto es normal! Usa los botones de la app, no refresques el navegador

🔴 PARA CERRAR QUOTIFY:
Presiona Ctrl+C en la ventana de terminal que se abrió

💾 TUS DATOS:
Todos los quotes se guardan en el navegador localmente.
Usa la función Export para respaldar tus quotes.

🆘 AYUDA:
Si algo no funciona, revisa que:
- Node.js esté instalado
- No hayas cerrado la ventana de terminal
- Tu API key de OpenAI sea correcta

EOF

# Hacer ejecutable el installer
chmod +x "$DIST_DIR/INSTALAR.command"

# Crear README para distribuidor
cat > "$DIST_DIR/LEEME-DISTRIBUIDOR.txt" << 'EOF'
🎯 PAQUETE DE DISTRIBUCIÓN QUOTIFY

Este paquete contiene todo lo necesario para ejecutar Quotify localmente.

QUÉ COMPARTIR:
- Comparte esta carpeta completa con tus usuarios
- Solo necesitan ejecutar "INSTALAR.command" una vez
- Después pueden usar "🎯 Quotify.command" en su Desktop

REQUISITOS DEL USUARIO:
- macOS (esta versión)
- Node.js 18+ (el instalador lo verifica)
- Conexión a internet para YouTube y OpenAI

QUÉ PASA:
1. Usuario ejecuta INSTALAR.command
2. Se instalan dependencias localmente
3. Se crea acceso directo en Desktop
4. Usuario puede ejecutar Quotify cuando quiera con doble clic

VENTAJAS:
✅ Funciona exactamente como tu versión de desarrollo
✅ Sin problemas de deployment de producción
✅ Acceso completo a YouTube
✅ Funcionalidad completa de transcripción
✅ Los usuarios no necesitan conocimiento técnico
✅ Incluye backend completo de Electron

EOF

echo ""
echo "✅ ¡Paquete de distribución creado!"
echo ""
echo "📦 Ubicación del paquete: $DIST_DIR"
echo ""
echo "🚀 Para distribuir:"
echo "   1. Comprime toda la carpeta '$PACKAGE_NAME'"
echo "   2. Comparte con tus usuarios"
echo "   3. Los usuarios extraen y ejecutan 'INSTALAR.command'"
echo ""
echo "📋 Creando archivo zip..."

# Crear archivo zip
cd "$CURRENT_DIR"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "✅ Archivo zip creado: ${PACKAGE_NAME}.zip"
echo ""
echo "🎯 ¡Listo para distribuir! Envía a los usuarios el archivo ZIP."
echo ""
echo "🔧 DIFERENCIAS CON LA VERSIÓN ANTERIOR:"
echo "   ✅ Incluye backend completo de Electron"
echo "   ✅ No se borra al hacer refresh"
echo "   ✅ Funciones de YouTube funcionan correctamente"
echo "   ✅ Transcripción funciona igual que en desarrollo"