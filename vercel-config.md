# 🚀 Quotify en Vercel - Configuración Completa

## Estrategia: Frontend en Vercel + API Functions

### ✅ Lo Que Funciona Directo en Vercel:
- **Metadata extraction** con ytdl-core
- **UI completa** de Quotify  
- **Quote management** local
- **PWA features** (instalar como app)

### 🔧 Lo Que Necesita API Functions:
- **Audio transcription** (descarga + OpenAI)

---

## Configuración para Vercel

### 1. Crear API Functions

```javascript
// api/transcribe.js
import ytdl from 'ytdl-core';
import { OpenAI } from 'openai';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { url, apiKey } = req.body;
  
  try {
    // Descargar audio
    const info = await ytdl.getInfo(url);
    const audioFormats = ytdl.filterFormats(info.formats, 'audioonly');
    const audioStream = ytdl.downloadFromInfo(info, { format: audioFormats[0] });
    
    // Convertir a buffer
    const chunks = [];
    for await (const chunk of audioStream) {
      chunks.push(chunk);
    }
    const audioBuffer = Buffer.concat(chunks);
    
    // Transcribir con OpenAI
    const openai = new OpenAI({ apiKey });
    const transcription = await openai.audio.transcriptions.create({
      file: new File([audioBuffer], 'audio.mp3', { type: 'audio/mp3' }),
      model: 'whisper-1',
      response_format: 'verbose_json',
      timestamp_granularities: ['word']
    });
    
    res.json(transcription);
    
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}
```

### 2. Configurar vercel.json

```json
{
  "functions": {
    "api/transcribe.js": {
      "maxDuration": 300
    }
  },
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

---

## Resultado Final

### 🌐 URL: https://quotify-tu-nombre.vercel.app

**Tu usuario obtiene:**
- ✅ App PWA completa (instala como nativa)
- ✅ Metadata de YouTube instantánea  
- ✅ Transcripción completa con timestamps
- ✅ Quote management completo
- ✅ Auto-actualizaciones
- ✅ Funciona offline (datos guardados)

**Limitaciones de Vercel Functions:**
- ⏱️ 5 minutos max por transcripción (suficiente para videos normales)
- 💾 512MB RAM (suficiente para audio)
- 🔄 Arranque en frío (1-2s delay primera vez)

---

## Alternativas Si Necesitas Más Potencia

### Railway.app (Recomendada para backend pesado)
```bash
# Deploy completo de Node.js
railway deploy
```
- ✅ Sin límites de tiempo
- ✅ Servidor Node.js completo
- ✅ $5/mes (muy barato)

### Render.com (Gratis con limitaciones)
- ✅ 750 horas gratis/mes
- ⏱️ Se duerme después de 15min inactividad

---

## ¿Qué Eliges?

| Opción | Costo | Facilidad | Transcripción | Límites |
|--------|-------|-----------|---------------|---------|
| **Vercel** | Gratis | 🟢 Fácil | ✅ Sí | 5min/video |
| **Railway** | $5/mes | 🟢 Fácil | ✅ Sí | Sin límites |
| **Render** | Gratis | 🟡 Medio | ✅ Sí | Se duerme |

**Para testing: Vercel**  
**Para producción seria: Railway ($5/mes)**