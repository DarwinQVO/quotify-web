#!/bin/bash

echo "🔍 Prueba manual de Quotify v2.1..."
echo ""

# Verificar estructura básica
echo "1. Verificando archivos..."
if [ -f "/Users/darwinborges/Desktop/Quotify-v2.1/QuotifyApp/bin/yt-dlp" ]; then
    echo "✅ yt-dlp incluido"
else
    echo "❌ yt-dlp NO encontrado"
fi

if [ -f "/Users/darwinborges/Desktop/Quotify-v2.1/QuotifyApp/package.json" ]; then
    echo "✅ package.json existe"
else
    echo "❌ package.json NO encontrado"
fi

echo ""
echo "2. Verificando main/index.js..."
grep -n "ytdlpPath" /Users/darwinborges/Desktop/Quotify-v2.1/QuotifyApp/src/main/index.js | head -5

echo ""
echo "3. Abriendo aplicación directamente..."
echo "Ejecutando: open '/Users/darwinborges/Desktop/Quotify-v2.1/Instalar Quotify.app'"
open '/Users/darwinborges/Desktop/Quotify-v2.1/Instalar Quotify.app'

echo ""
echo "✅ Si no se abre, puede ser por seguridad de macOS."
echo "   Intenta: Clic derecho > Abrir"