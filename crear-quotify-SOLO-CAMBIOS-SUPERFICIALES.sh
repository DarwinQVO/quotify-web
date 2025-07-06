#!/bin/bash

echo "✨ Quotify - SOLO CAMBIOS SUPERFICIALES"
echo "======================================"

PACKAGE_NAME="Quotify-SOLO-SUPERFICIAL-$(date +%Y%m%d-%H%M)"
DIST_DIR="/Users/darwinborges/Desktop/$PACKAGE_NAME"

echo "📦 Copiando la versión que FUNCIONABA PERFECTO..."

# Copiar EXACTAMENTE la versión que funcionaba
rm -rf "$DIST_DIR"
cp -r "/Users/darwinborges/Desktop/Quotify-ESTRUCTURA-ORIGINAL-20250702-2349" "$DIST_DIR"

cd "$DIST_DIR"

echo "🔧 Aplicando SOLO los 2 cambios superficiales..."

# CAMBIO 1: Quitar consola (comentar línea)
sed -i '' 's/mainWindow.webContents.openDevTools();/\/\/ mainWindow.webContents.openDevTools(); \/\/ Sin consola/' "QuotifyApp/src/main/index.js"

# CAMBIO 2: Agregar icono (una línea)
sed -i '' '/minHeight: 700,/a\
    icon: path.join(__dirname, "..\/..\/public\/icon.png"),
' "QuotifyApp/src/main/index.js"

# Copiar icono
mkdir -p "QuotifyApp/public"
cp "/Users/darwinborges/Desktop/Icono Quotify.png" "QuotifyApp/public/icon.png"

echo "✅ Solo 2 cambios aplicados:"
echo "   🚫 Consola comentada"  
echo "   🎨 Icono agregado"

# Actualizar LEEME
cat > "LEEME-SUPERFICIAL.txt" << 'README_EOF'
✨ QUOTIFY - SOLO CAMBIOS SUPERFICIALES

======================================

Esta es EXACTAMENTE la versión que funcionaba
+ solo 2 cambios superficiales:

🚫 Sin consola molesta
🎨 Logo propio en Cmd+Tab

📋 USO (IGUAL):
1. "1️⃣ INSTALAR-QUOTIFY.command" 
2. "🎯 Quotify.app"

✅ GARANTIZADO:
✅ Misma funcionalidad que funcionaba
✅ Solo cambios superficiales
✅ No toqué nada más

¡Debe funcionar igual que antes!
README_EOF

echo ""
echo "✨ SOLO CAMBIOS SUPERFICIALES APLICADOS!"
echo ""
echo "📋 BASE: La versión que funcionaba perfecto"
echo "🔧 SOLO agregué: Sin consola + Logo propio"
echo ""

cd "/Users/darwinborges/Desktop"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" -q

echo "📦 ZIP: ${PACKAGE_NAME}.zip"
echo ""
echo "✨ ¡DEBE FUNCIONAR IGUAL + MEJORAS SUPERFICIALES!"