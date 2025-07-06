const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 8080;

// Servir archivos estáticos con headers PWA
app.use(express.static('.', {
    setHeaders: (res, filePath) => {
        // Headers para PWA
        if (filePath.endsWith('manifest.json')) {
            res.set('Content-Type', 'application/manifest+json');
        }
        
        if (filePath.endsWith('sw.js')) {
            res.set('Service-Worker-Allowed', '/');
            res.set('Cache-Control', 'no-cache');
        }
        
        // Headers de seguridad
        res.set('X-Content-Type-Options', 'nosniff');
        res.set('X-Frame-Options', 'DENY');
    }
}));

// Crear iconos dinámicamente si no existen
app.get('/icon-:size.png', (req, res) => {
    const size = req.params.size;
    
    // SVG del icono Quotify
    const iconSvg = `
    <svg width="${size}" height="${size}" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
        <defs>
            <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:#007aff;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#5856d6;stop-opacity:1" />
            </linearGradient>
        </defs>
        <rect width="100" height="100" rx="20" fill="url(#grad)"/>
        <text x="50" y="65" font-family="Arial, sans-serif" font-size="40" font-weight="bold" text-anchor="middle" fill="white">🎯</text>
    </svg>`;
    
    res.set('Content-Type', 'image/svg+xml');
    res.send(iconSvg);
});

// API para verificar versión
app.get('/api/version', (req, res) => {
    const packageJson = JSON.parse(fs.readFileSync('./package.json', 'utf8'));
    res.json({
        version: packageJson.version,
        name: packageJson.name,
        timestamp: new Date().toISOString()
    });
});

// Ruta principal - servir PWA launcher
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'quotify-pwa.html'));
});

// Fallback para rutas de PWA
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'quotify-pwa.html'));
});

app.listen(PORT, () => {
    console.log(`
🎯 Quotify PWA Server running!

📱 Users can install from: http://localhost:${PORT}
🔄 Auto-updates enabled
📦 PWA ready for offline use

Instructions for users:
1. Go to: http://localhost:${PORT}
2. Click "Install as App" 
3. Quotify will work like a native app!
    `);
});

module.exports = app;