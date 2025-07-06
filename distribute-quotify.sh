#!/bin/bash

echo "🎯 Quotify Distribution Package Creator"
echo "======================================"

# Variables
CURRENT_DIR="$(pwd)"
PACKAGE_NAME="quotify-portable-$(date +%Y%m%d)"
DIST_DIR="$CURRENT_DIR/$PACKAGE_NAME"

echo "📦 Creating distribution package..."

# Crear directorio de distribución
mkdir -p "$DIST_DIR"

# Copiar archivos necesarios
echo "📋 Copying project files..."
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

# Crear installer script para el usuario final
cat > "$DIST_DIR/INSTALL.command" << 'EOF'
#!/bin/bash

echo "🎯 Quotify - Easy Setup"
echo "======================"

# Obtener directorio del script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Verificar Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required but not installed."
    echo "📥 Download from: https://nodejs.org/"
    echo "   Choose the LTS version, then run this script again."
    read -p "Press Enter to exit..."
    exit 1
fi

echo "✅ Node.js found: $(node --version)"

# Instalar dependencias
echo "📦 Installing dependencies (this may take a few minutes)..."
npm install

# Crear launcher
cat > launch-quotify.command << 'LAUNCHER_EOF'
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🎯 Starting Quotify..."
echo ""
echo "🌐 Quotify will open at: http://localhost:5173"
echo "💡 Keep this window open while using Quotify"
echo "🔴 To close Quotify, press Ctrl+C here"
echo ""

# Verificar puerto
if lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port 5173 is already in use. Trying to stop existing process..."
    pkill -f "vite.*5173" 2>/dev/null || true
    sleep 2
fi

# Abrir navegador
(sleep 3 && open http://localhost:5173) &

# Iniciar servidor
npm run dev:vite

LAUNCHER_EOF

chmod +x launch-quotify.command

# Crear acceso directo en Desktop
DESKTOP_SHORTCUT="$HOME/Desktop/Quotify.command"
cat > "$DESKTOP_SHORTCUT" << DESKTOP_EOF
#!/bin/bash
cd "$DIR"
./launch-quotify.command
DESKTOP_EOF

chmod +x "$DESKTOP_SHORTCUT"

echo ""
echo "✅ Quotify setup complete!"
echo ""
echo "🚀 To start Quotify:"
echo "   1. Double-click 'Quotify.command' on your Desktop"
echo "   2. Or double-click 'launch-quotify.command' in this folder"
echo ""
echo "📖 Need help? Read the HOW_TO_USE.txt file"

# Esperar para que el usuario vea el mensaje
read -p "Press Enter to continue..."

EOF

# Crear manual de usuario
cat > "$DIST_DIR/HOW_TO_USE.txt" << 'EOF'
🎯 QUOTIFY - HOW TO USE

📋 QUICK START:
1. Double-click "INSTALL.command" (only needed once)
2. Double-click "Quotify.command" on your Desktop to start
3. Use Quotify in your browser at http://localhost:5173

📱 USING QUOTIFY:

1. ADD YOUTUBE VIDEO:
   - Copy any YouTube video URL
   - Paste in "Add Source" field
   - Click "Add Source"

2. TRANSCRIBE AUDIO:
   - Click "Transcribe" on your video
   - Enter your OpenAI API key (get it from: https://platform.openai.com/api-keys)
   - Wait for transcription to complete

3. EXTRACT QUOTES:
   - View transcription in the right panel
   - Select text to create quotes
   - Quotes are saved automatically

🔧 TROUBLESHOOTING:

• "Node.js not found":
  Download from https://nodejs.org/ (choose LTS version)

• "Port already in use":
  Close other Quotify instances and restart

• Permission errors:
  Right-click the .command files and select "Open"

🔴 TO CLOSE QUOTIFY:
Press Ctrl+C in the terminal window that opened

💾 YOUR DATA:
All quotes are saved in your browser locally.
Use the Export feature to backup your quotes.

EOF

# Hacer ejecutable el installer
chmod +x "$DIST_DIR/INSTALL.command"

# Crear README para quien distribuye
cat > "$DIST_DIR/README-DISTRIBUTOR.txt" << 'EOF'
🎯 QUOTIFY DISTRIBUTION PACKAGE

This package contains everything needed to run Quotify locally.

WHAT TO SHARE:
- Share this entire folder with your users
- They only need to run "INSTALL.command" once
- Then they can use "Quotify.command" on their Desktop

USER REQUIREMENTS:
- macOS (this version)
- Node.js 18+ (installer will check)
- Internet connection for YouTube and OpenAI

WHAT HAPPENS:
1. User runs INSTALL.command
2. Dependencies are installed locally
3. Desktop shortcut is created
4. User can run Quotify anytime by double-clicking Desktop shortcut

ADVANTAGES:
✅ Works exactly like your dev version
✅ No production deployment issues
✅ Full YouTube access
✅ Complete transcription functionality
✅ Users don't need technical knowledge

EOF

echo ""
echo "✅ Distribution package created!"
echo ""
echo "📦 Package location: $DIST_DIR"
echo ""
echo "🚀 To distribute:"
echo "   1. Zip the entire '$PACKAGE_NAME' folder"
echo "   2. Share with your users"
echo "   3. Users extract and run 'INSTALL.command'"
echo ""
echo "📋 Creating zip file..."

# Crear archivo zip
cd "$CURRENT_DIR"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "✅ Zip file created: ${PACKAGE_NAME}.zip"
echo ""
echo "🎯 Ready to distribute! Send users the ZIP file."