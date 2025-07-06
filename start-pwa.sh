#!/bin/bash

echo "🎯 Starting Quotify PWA Distribution Server"
echo "=========================================="

# Verificar Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required but not installed."
    echo "📥 Download from: https://nodejs.org/"
    exit 1
fi

# Verificar dependencias
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

echo ""
echo "🚀 Starting PWA server..."
echo "📱 Users can install from: http://localhost:8080"
echo "💡 Keep this terminal open"
echo ""

# Iniciar servidor PWA
node pwa-server.js