#!/bin/bash

echo "🎯 Quotify Development Installer"
echo "================================"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required but not installed."
    echo "📥 Please install Node.js from: https://nodejs.org/"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is required but not installed."
    exit 1
fi

echo "✅ Node.js and npm are installed"

# Create installation directory
INSTALL_DIR="$HOME/Quotify-Dev"
echo "📁 Installing to: $INSTALL_DIR"

# Remove existing installation if it exists
if [ -d "$INSTALL_DIR" ]; then
    echo "🗑️  Removing existing installation..."
    rm -rf "$INSTALL_DIR"
fi

# Clone or copy the project
echo "📥 Downloading Quotify..."
mkdir -p "$INSTALL_DIR"

# Copy all necessary files (you would run this from the quotify-app directory)
cp -r . "$INSTALL_DIR/"

cd "$INSTALL_DIR"

echo "📦 Installing dependencies..."
npm install

# Create launch script
cat > "$INSTALL_DIR/launch-quotify.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "🎯 Starting Quotify Development Version..."
echo "🌐 Opening browser at http://localhost:5173"
echo "💡 Keep this terminal open while using Quotify"
echo ""
npm run dev
EOF

chmod +x "$INSTALL_DIR/launch-quotify.sh"

# Create desktop shortcut for macOS
cat > "$HOME/Desktop/Quotify Dev.command" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
./launch-quotify.sh
EOF

chmod +x "$HOME/Desktop/Quotify Dev.command"

echo ""
echo "✅ Installation Complete!"
echo ""
echo "🚀 To start Quotify:"
echo "   Option 1: Double-click 'Quotify Dev.command' on your Desktop"
echo "   Option 2: Run: $INSTALL_DIR/launch-quotify.sh"
echo ""
echo "🌐 Quotify will open at: http://localhost:5173"
echo "❗ Keep the terminal window open while using Quotify"