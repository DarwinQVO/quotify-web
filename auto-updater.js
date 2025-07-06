const express = require('express');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
const cors = require('cors');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Configuración
const CONFIG = {
    version: '1.0.0',
    downloadUrl: 'https://github.com/TU_USUARIO/quotify/archive/main.zip',
    installPath: path.join(process.env.HOME, 'Quotify'),
    serverUrl: 'http://localhost:5173'
};

// API endpoints
app.get('/api/version', (req, res) => {
    res.json({
        current: CONFIG.version,
        downloadUrl: CONFIG.downloadUrl,
        releaseNotes: [
            '✅ Metadata extraction mejorada',
            '🎤 Transcripción con ytdl-core + fallback',
            '🐛 Corregidos errores de pantalla negra',
            '⚡ Mejor rendimiento y estabilidad'
        ]
    });
});

app.post('/api/install', async (req, res) => {
    try {
        const { installPath = CONFIG.installPath } = req.body;
        
        res.writeHead(200, {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive'
        });
        
        const sendProgress = (message, progress = null) => {
            res.write(`data: ${JSON.stringify({ message, progress })}\\n\\n`);
        };
        
        // Paso 1: Crear directorio
        sendProgress('📁 Creando directorio de instalación...', 10);
        if (!fs.existsSync(installPath)) {
            fs.mkdirSync(installPath, { recursive: true });
        }
        
        // Paso 2: Descargar código
        sendProgress('📥 Descargando Quotify...', 25);
        await downloadAndExtract(CONFIG.downloadUrl, installPath);
        
        // Paso 3: Instalar dependencias
        sendProgress('📦 Instalando dependencias...', 50);
        await installDependencies(installPath);
        
        // Paso 4: Crear script de launch
        sendProgress('🚀 Configurando launcher...', 75);
        await createLaunchScript(installPath);
        
        // Paso 5: Crear acceso directo
        sendProgress('🔗 Creando accesos directos...', 90);
        await createShortcuts(installPath);
        
        sendProgress('✅ Instalación completada', 100);
        res.write('data: {"complete": true}\\n\\n');
        res.end();
        
    } catch (error) {
        res.write(`data: {"error": "${error.message}"}\\n\\n`);
        res.end();
    }
});

app.post('/api/launch', (req, res) => {
    const { installPath = CONFIG.installPath } = req.body;
    
    // Iniciar servidor de desarrollo
    const quotifyProcess = exec('npm run dev', { 
        cwd: installPath,
        detached: true 
    });
    
    quotifyProcess.stdout.on('data', (data) => {
        console.log('Quotify output:', data);
    });
    
    res.json({ 
        success: true, 
        url: CONFIG.serverUrl,
        pid: quotifyProcess.pid 
    });
});

// Funciones auxiliares
async function downloadAndExtract(url, destPath) {
    return new Promise((resolve, reject) => {
        const cmd = `curl -L ${url} -o temp.zip && unzip -o temp.zip -d ${destPath} && rm temp.zip`;
        exec(cmd, (error) => {
            if (error) reject(error);
            else resolve();
        });
    });
}

async function installDependencies(installPath) {
    return new Promise((resolve, reject) => {
        exec('npm install', { cwd: installPath }, (error) => {
            if (error) reject(error);
            else resolve();
        });
    });
}

async function createLaunchScript(installPath) {
    const scriptContent = `#!/bin/bash
cd "${installPath}"
echo "🎯 Iniciando Quotify..."
echo "🌐 Abriendo en http://localhost:5173"
npm run dev
`;
    
    const scriptPath = path.join(installPath, 'launch-quotify.sh');
    fs.writeFileSync(scriptPath, scriptContent);
    fs.chmodSync(scriptPath, '755');
}

async function createShortcuts(installPath) {
    // Crear comando para macOS
    const commandContent = `#!/bin/bash
cd "${installPath}"
./launch-quotify.sh
`;
    
    const desktopPath = path.join(process.env.HOME, 'Desktop', 'Quotify.command');
    fs.writeFileSync(desktopPath, commandContent);
    fs.chmodSync(desktopPath, '755');
}

// Servir el launcher HTML
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'quotify-launcher.html'));
});

app.listen(PORT, () => {
    console.log(`🎯 Quotify Auto-Updater running at http://localhost:${PORT}`);
    console.log('📱 Usuarios pueden acceder para instalar/actualizar');
});

module.exports = app;