#!/bin/bash

echo "🎯 Quotify - Versión Completa con Electron"
echo "========================================="

PACKAGE_NAME="quotify-con-electron-$(date +%Y%m%d)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Creando paquete completo con Electron..."

# Crear directorio limpio
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Copiar TODO el proyecto
echo "📋 Copiando proyecto completo..."
cp -r . "$DIST_DIR/"

# Limpiar archivos innecesarios
cd "$DIST_DIR"
rm -rf node_modules dist-electron .git
rm -f *.zip *.dmg

# Crear instalador simple
cat > "INSTALAR-QUOTIFY.command" << 'EOF'
#!/bin/bash

echo "🎯 Quotify - Instalador Completo"
echo "==============================="

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Verificar Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado."
    echo "📥 Descarga desde: https://nodejs.org/"
    read -p "Presiona Enter para salir..."
    exit 1
fi

echo "✅ Node.js encontrado: $(node --version)"

# Limpiar e instalar
echo "📦 Instalando dependencias..."
npm cache clean --force 2>/dev/null || true
npm install

if [ $? -ne 0 ]; then
    echo "❌ Error instalando dependencias"
    read -p "Presiona Enter para salir..."
    exit 1
fi

# Crear launcher
cat > "abrir-quotify.command" << 'LAUNCHER_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🎯 Iniciando Quotify COMPLETO con Electron..."
echo ""
echo "🔧 Esto incluye:"
echo "   • Frontend React"
echo "   • Backend Electron" 
echo "   • Funciones de YouTube"
echo "   • Transcripción con OpenAI"
echo ""
echo "💡 Mantén esta ventana abierta"
echo "🔴 Para cerrar: Ctrl+C"
echo ""

# Verificar puerto
if lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "🔄 Cerrando proceso anterior..."
    pkill -f "vite.*5173" 2>/dev/null || true
    pkill -f "electron.*quotify" 2>/dev/null || true
    sleep 3
fi

# Iniciar Quotify COMPLETO (React + Electron)
npm run dev

LAUNCHER_EOF

chmod +x "abrir-quotify.command"

# Crear acceso directo en Desktop  
DESKTOP_SHORTCUT="$HOME/Desktop/🎯 Quotify COMPLETO.command"
cat > "$DESKTOP_SHORTCUT" << DESKTOP_EOF
#!/bin/bash
cd "$DIR"
./abrir-quotify.command
DESKTOP_EOF

chmod +x "$DESKTOP_SHORTCUT"

echo ""
echo "✅ ¡Quotify COMPLETO instalado!"
echo ""
echo "🚀 Para usar:"
echo "   Doble clic en '🎯 Quotify COMPLETO.command' en Desktop"
echo ""
echo "🔥 INCLUYE:"
echo "   ✅ YouTube metadata"
echo "   ✅ Audio transcription" 
echo "   ✅ Quote extraction"
echo "   ✅ Todo funciona igual que desarrollo"
echo ""

read -p "Presiona Enter para continuar..."

EOF

chmod +x "INSTALAR-QUOTIFY.command"

# Crear manual
cat > "INSTRUCCIONES.txt" << 'EOF'
🎯 QUOTIFY COMPLETO - INSTRUCCIONES

🚀 INSTALACIÓN:
1. Doble clic en "INSTALAR-QUOTIFY.command"
2. Esperar que termine la instalación
3. Doble clic en "🎯 Quotify COMPLETO.command" en Desktop

📱 FUNCIONAMIENTO:
• Se abre ventana de terminal (NO CERRAR)
• Se abre Quotify en navegador automáticamente
• Todo funciona igual que versión de desarrollo

🔥 FUNCIONES INCLUIDAS:
✅ Metadata de YouTube (instantáneo)
✅ Descarga de audio (automática)  
✅ Transcripción con OpenAI (necesita API key)
✅ Extracción de quotes (clic en texto)
✅ Export/import de quotes

🔴 PARA CERRAR:
Presionar Ctrl+C en la ventana de terminal

💡 DIFERENCIA CON OTRAS VERSIONES:
Esta versión incluye TODO el backend de Electron,
por eso funciona exactamente igual que desarrollo.

EOF

echo ""
echo "✅ Paquete completo creado en Desktop!"
echo ""
echo "📍 Ubicación: $DIST_DIR"
echo ""
echo "🎯 ESTE PAQUETE INCLUYE:"
echo "   ✅ Frontend React completo"
echo "   ✅ Backend Electron completo"  
echo "   ✅ Todas las funciones de YouTube"
echo "   ✅ Transcripción completa"
echo "   ✅ Instalador automático"
echo ""

# Crear ZIP en Desktop
cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP creado: ${PACKAGE_NAME}.zip"
echo ""
echo "🎉 ¡LISTO! Comparte el ZIP del Desktop"