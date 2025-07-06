#!/bin/bash

echo "🎯 Quotify - Instalador Simple y Seguro"
echo "======================================"

# Crear directorio en Home (sin espacios, sin permisos especiales)
INSTALL_DIR="$HOME/Quotify"
CURRENT_DIR="$(pwd)"

echo "📁 Creando directorio de instalación en: $INSTALL_DIR"

# Limpiar instalación anterior si existe
if [ -d "$INSTALL_DIR" ]; then
    echo "🔄 Removiendo instalación anterior..."
    rm -rf "$INSTALL_DIR"
fi

# Crear directorio limpio
mkdir -p "$INSTALL_DIR"

# Copiar archivos desde donde está el usuario
echo "📋 Copiando archivos..."
cp -r "$CURRENT_DIR"/* "$INSTALL_DIR/" 2>/dev/null || true

# Ir al directorio de instalación
cd "$INSTALL_DIR"

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

# Limpiar cache de npm por si acaso
echo "🧹 Limpiando cache..."
npm cache clean --force 2>/dev/null || true

# Instalar dependencias en directorio limpio
echo "📦 Instalando dependencias..."
npm install --no-audit --no-fund

if [ $? -ne 0 ]; then
    echo "❌ Error instalando dependencias"
    echo "🔧 Intentando instalación alternativa..."
    
    # Intentar con yarn si está disponible
    if command -v yarn &> /dev/null; then
        echo "📦 Instalando con yarn..."
        yarn install
    else
        echo "❌ No se pudo instalar. Intenta:"
        echo "   1. Cerrar todas las aplicaciones"
        echo "   2. Reiniciar la computadora"
        echo "   3. Ejecutar este instalador otra vez"
    fi
    
    read -p "Presiona Enter para salir..."
    exit 1
fi

# Crear launcher simple
cat > "$INSTALL_DIR/abrir-quotify.command" << 'EOF'
#!/bin/bash

# Ir al directorio correcto
cd "$HOME/Quotify"

echo "🎯 Iniciando Quotify..."
echo ""
echo "🌐 Quotify se abrirá en tu navegador"
echo "💡 Mantén esta ventana abierta"
echo "🔴 Para cerrar: presiona Ctrl+C"
echo ""

# Verificar puerto
if lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Cerrando proceso anterior..."
    pkill -f "vite.*5173" 2>/dev/null || true
    sleep 2
fi

# Abrir navegador
(sleep 4 && open http://localhost:5173) &

# Iniciar Quotify
npm run dev

EOF

# Hacer ejecutable
chmod +x "$INSTALL_DIR/abrir-quotify.command"

# Crear acceso directo en Desktop
DESKTOP_SHORTCUT="$HOME/Desktop/🎯 Quotify.command"
cat > "$DESKTOP_SHORTCUT" << EOF
#!/bin/bash
cd "$HOME/Quotify"
./abrir-quotify.command
EOF

chmod +x "$DESKTOP_SHORTCUT"

# Crear manual simple
cat > "$INSTALL_DIR/INSTRUCCIONES.txt" << 'EOF'
🎯 QUOTIFY INSTALADO CORRECTAMENTE

📋 CÓMO USAR:
1. Doble clic en "🎯 Quotify.command" en tu Desktop
2. Espera a que se abra en el navegador
3. ¡Listo para usar!

📱 FUNCIONES:
• Agregar videos de YouTube
• Transcribir automáticamente
• Extraer quotes fácilmente

🔴 PARA CERRAR:
Presiona Ctrl+C en la ventana que se abre

💡 CONSEJOS:
• No cierres la ventana de terminal mientras uses Quotify
• No refresques el navegador, usa los botones de la app
• Necesitas API key de OpenAI para transcribir

EOF

echo ""
echo "✅ ¡Quotify instalado correctamente!"
echo ""
echo "📍 Instalación ubicada en: $HOME/Quotify"
echo ""
echo "🚀 Para usar:"
echo "   Doble clic en '🎯 Quotify.command' en tu Desktop"
echo ""
echo "📖 Lee INSTRUCCIONES.txt para más ayuda"
echo ""

# Pausa para que el usuario vea el mensaje
read -p "Presiona Enter para continuar..."