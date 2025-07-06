#!/bin/bash

echo "🎯 Quotify Portable - Setup Script"
echo "=================================="

# Variables
INSTALL_DIR="$HOME/QuotifyApp"
QUOTIFY_URL="https://github.com/research-quotes/Quotify/archive/main.zip"

# Función para verificar comando
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is required but not installed."
        if [[ "$1" == "node" ]]; then
            echo "📥 Download from: https://nodejs.org/"
            echo "   Choose the LTS version"
        fi
        exit 1
    else
        echo "✅ $1 is available"
    fi
}

# Verificar dependencias
echo "🔍 Checking requirements..."
check_command "node"
check_command "npm"

# Mostrar versiones
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
echo "📦 Node.js: $NODE_VERSION"
echo "📦 npm: $NPM_VERSION"

# Crear directorio
echo ""
echo "📁 Setting up Quotify..."
if [ -d "$INSTALL_DIR" ]; then
    echo "🔄 Updating existing installation..."
    rm -rf "$INSTALL_DIR"
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Descargar código fuente
echo "📥 Downloading Quotify..."
curl -L "$QUOTIFY_URL" -o quotify.zip
unzip -q quotify.zip
mv quotify-main/* .
rm -rf quotify-main quotify.zip

# Instalar dependencias
echo "📦 Installing dependencies (this may take a few minutes)..."
npm install

# Crear script de lanzamiento mejorado
cat > launch-quotify.command << 'EOF'
#!/bin/bash

# Obtener directorio del script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🎯 Starting Quotify..."
echo ""
echo "🌐 Quotify will open at: http://localhost:5173"
echo "💡 Keep this window open while using Quotify"
echo "🔴 To close Quotify, press Ctrl+C here"
echo ""

# Verificar si el puerto está en uso
if lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port 5173 is already in use. Trying to stop existing process..."
    pkill -f "vite.*5173" 2>/dev/null || true
    sleep 2
fi

# Abrir navegador después de 3 segundos
(sleep 3 && open http://localhost:5173) &

# Iniciar Quotify
npm run dev

EOF

# Hacer ejecutable el launcher
chmod +x launch-quotify.command

# Crear acceso directo en el Desktop
DESKTOP_SHORTCUT="$HOME/Desktop/Quotify.command"
cat > "$DESKTOP_SHORTCUT" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
./launch-quotify.command
EOF

chmod +x "$DESKTOP_SHORTCUT"

# Crear script de actualización
cat > update-quotify.sh << 'EOF'
#!/bin/bash
echo "🔄 Updating Quotify..."

# Backup de configuración local si existe
if [ -f "quotify-config.json" ]; then
    cp quotify-config.json quotify-config.backup
fi

# Descargar nueva versión
curl -L "https://github.com/research-quotes/Quotify/archive/main.zip" -o quotify-update.zip
unzip -q quotify-update.zip
cp -r quotify-main/* .
rm -rf quotify-main quotify-update.zip

# Restaurar configuración
if [ -f "quotify-config.backup" ]; then
    mv quotify-config.backup quotify-config.json
fi

# Actualizar dependencias
npm install

echo "✅ Quotify updated successfully!"
EOF

chmod +x update-quotify.sh

# Crear README para el usuario
cat > HOW_TO_USE.md << 'EOF'
# 🎯 Quotify - Instrucciones de Uso

## 🚀 Abrir Quotify

### Opción 1: Acceso Directo (Más Fácil)
- Hacer **doble clic** en "Quotify.command" en tu **Desktop**
- Se abrirá una ventana de terminal y tu navegador
- ¡Listo! Ya puedes usar Quotify

### Opción 2: Desde la Carpeta
- Ir a la carpeta QuotifyApp en tu Home
- Hacer doble clic en "launch-quotify.command"

## 📱 Usar Quotify

1. **Agregar Video de YouTube**
   - Copiar URL del video
   - Pegar en el campo "Add Source"
   - Click "Add Source"

2. **Transcribir Audio**
   - Click en "Transcribe" en el video agregado
   - Ingresar tu API Key de OpenAI
   - Esperar a que termine (puede tomar varios minutos)

3. **Extraer Quotes**
   - Ver la transcripción en el panel derecho
   - Seleccionar texto para crear quotes
   - Los quotes se guardan automáticamente

## 🔧 Configuración

### API Key de OpenAI
- Obtener en: https://platform.openai.com/api-keys
- Se guarda localmente (seguro)
- Solo se usa para transcripción

## 🔄 Actualizar Quotify

- Ejecutar: `./update-quotify.sh`
- O volver a ejecutar el script de instalación

## 🆘 Problemas Comunes

### "Puerto ya en uso"
- Cerrar otras instancias de Quotify
- Reiniciar el launcher

### Error de permisos
```bash
chmod +x launch-quotify.command
```

### Dependencias faltantes
```bash
npm install
```

## 💾 Datos

Todos tus quotes y configuración se guardan en:
- Tu navegador (localStorage)
- No se comparten con nadie
- Backup recomendado con "Export"

## 🔴 Cerrar Quotify

- Presionar **Ctrl+C** en la ventana de terminal
- O cerrar la ventana de terminal
EOF

echo ""
echo "✅ Quotify installation complete!"
echo ""
echo "🚀 To start Quotify:"
echo "   1. Double-click 'Quotify.command' on your Desktop"
echo "   2. Or run: $INSTALL_DIR/launch-quotify.command"
echo ""
echo "📖 Read instructions: $INSTALL_DIR/HOW_TO_USE.md"
echo "🔄 To update later: $INSTALL_DIR/update-quotify.sh"
echo ""
echo "🎯 Quotify installed in: $INSTALL_DIR"