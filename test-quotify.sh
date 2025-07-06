#!/bin/bash

echo "🔍 Probando Quotify v2.1..."
echo ""

# Probar el instalador directamente
echo "1. Probando instalador..."
/Users/darwinborges/Desktop/Quotify-v2.1/Instalar\ Quotify.app/Contents/MacOS/installer

echo ""
echo "2. Verificando estructura..."
ls -la /Users/darwinborges/Desktop/Quotify-v2.1/

echo ""
echo "3. Verificando QuotifyApp..."
ls -la /Users/darwinborges/Desktop/Quotify-v2.1/QuotifyApp/ | head -10

echo ""
echo "4. Verificando node_modules..."
if [ -d "/Users/darwinborges/Desktop/Quotify-v2.1/QuotifyApp/node_modules" ]; then
    echo "✅ node_modules existe"
else
    echo "❌ node_modules NO existe"
fi

echo ""
echo "5. Verificando yt-dlp incluido..."
if [ -f "/Users/darwinborges/Desktop/Quotify-v2.1/QuotifyApp/bin/yt-dlp" ]; then
    echo "✅ yt-dlp existe"
    ls -la /Users/darwinborges/Desktop/Quotify-v2.1/QuotifyApp/bin/yt-dlp
else
    echo "❌ yt-dlp NO existe"
fi