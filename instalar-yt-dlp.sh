#!/bin/bash

echo "🔧 Instalando yt-dlp para Quotify"
echo "================================="

# Detectar arquitectura y sistema
ARCH=$(uname -m)
OS=$(uname -s)

echo ""
echo "📋 Sistema detectado:"
echo "   OS: $OS"
echo "   Arquitectura: $ARCH"
echo ""

# Directorio de instalación
INSTALL_DIR="/usr/local/bin"

# Verificar si ya está instalado
if command -v yt-dlp &> /dev/null; then
    echo "✅ yt-dlp ya está instalado:"
    echo "   Ubicación: $(which yt-dlp)"
    echo "   Versión: $(yt-dlp --version)"
    echo ""
    read -p "¿Quieres actualizar? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 0
    fi
fi

# Método 1: Intentar con Homebrew (si está disponible)
if command -v brew &> /dev/null; then
    echo "📦 Instalando con Homebrew..."
    brew install yt-dlp
    
    if command -v yt-dlp &> /dev/null; then
        echo "✅ yt-dlp instalado correctamente con Homebrew"
        echo "   Ubicación: $(which yt-dlp)"
        echo "   Versión: $(yt-dlp --version)"
        exit 0
    fi
fi

# Método 2: Descarga directa
echo "📥 Descargando yt-dlp directamente..."

# URL según arquitectura
if [[ "$ARCH" == "arm64" ]]; then
    # Apple Silicon (M1/M2)
    YT_DLP_URL="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos"
else
    # Intel
    YT_DLP_URL="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos"
fi

# Descargar
echo "⬇️ Descargando desde GitHub..."
curl -L "$YT_DLP_URL" -o /tmp/yt-dlp

# Hacer ejecutable
chmod +x /tmp/yt-dlp

# Mover a directorio de sistema (requiere sudo)
echo ""
echo "📁 Instalando en $INSTALL_DIR"
echo "   (Se requiere contraseña de administrador)"
echo ""

sudo mv /tmp/yt-dlp "$INSTALL_DIR/yt-dlp"

# Verificar instalación
if command -v yt-dlp &> /dev/null; then
    echo ""
    echo "✅ ¡yt-dlp instalado correctamente!"
    echo "   Ubicación: $(which yt-dlp)"
    echo "   Versión: $(yt-dlp --version)"
    echo ""
    echo "🎯 Ahora Quotify puede descargar audio de YouTube"
else
    echo ""
    echo "❌ Error en la instalación"
    echo ""
    echo "🔧 INSTALACIÓN MANUAL:"
    echo "   1. Ve a: https://github.com/yt-dlp/yt-dlp"
    echo "   2. Descarga la versión para macOS"
    echo "   3. Muévela a /usr/local/bin/"
fi

echo ""
read -p "Presiona Enter para continuar..."