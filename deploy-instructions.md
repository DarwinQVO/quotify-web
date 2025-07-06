# 🚀 Instrucciones de Deployment para Quotify Web

## Opción 1: Desde tu computadora (después de instalar gcloud)

```bash
# 1. Instala gcloud CLI
# macOS:
brew install google-cloud-sdk

# Windows/Linux:
# Visita: https://cloud.google.com/sdk/docs/install

# 2. Autentícate
gcloud auth login

# 3. Configura tu proyecto (reemplaza YOUR-PROJECT-ID)
gcloud config set project YOUR-PROJECT-ID

# 4. Habilita las APIs necesarias
gcloud services enable cloudbuild.googleapis.com run.googleapis.com

# 5. Despliega directamente (¡sin Docker local!)
gcloud run deploy quotify-web \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 1 \
  --timeout 3600 \
  --port 5174
```

## Opción 2: Desde Google Cloud Console (sin instalar nada)

1. **Sube el código a GitHub**
   ```bash
   git init
   git add .
   git commit -m "Quotify web version for Cloud Run"
   git remote add origin https://github.com/TU-USUARIO/quotify-web.git
   git push -u origin main
   ```

2. **En Google Cloud Console:**
   - Ve a: https://console.cloud.google.com/run
   - Click "Create Service"
   - Selecciona "Continuously deploy from a repository"
   - Conecta tu GitHub y selecciona el repo
   - Configuración:
     - Build type: Dockerfile
     - Port: 5174
     - Memory: 2 GiB
     - CPU: 1
     - Request timeout: 3600 seconds
     - Max instances: 10
   - Click "Create"

## Opción 3: Cloud Build Trigger (deployment automático)

1. **Sube el código a GitHub** (como en Opción 2)

2. **En Google Cloud Console:**
   - Ve a: https://console.cloud.google.com/cloud-build/triggers
   - Click "Create Trigger"
   - Conecta tu repo de GitHub
   - Configuración:
     - Event: Push to branch
     - Branch: main
     - Build configuration: Cloud Build configuration file
     - Location: /cloudbuild.yaml
   - Click "Create"

3. **Cada push a GitHub desplegará automáticamente**

## Opción 4: Usando Cloud Shell (todo en el navegador)

1. **Abre Cloud Shell:** https://console.cloud.google.com/cloudshell

2. **Clona tu repo o sube los archivos:**
   ```bash
   # Opción A: Clonar desde GitHub
   git clone https://github.com/TU-USUARIO/quotify-web.git
   cd quotify-web
   
   # Opción B: Subir archivos
   # Usa el botón "Upload" en Cloud Shell
   ```

3. **Despliega:**
   ```bash
   gcloud run deploy quotify-web \
     --source . \
     --platform managed \
     --region us-central1 \
     --allow-unauthenticated \
     --memory 2Gi \
     --cpu 1 \
     --timeout 3600 \
     --port 5174
   ```

## 🎯 Resultado esperado

Después del deployment exitoso verás:
```
Service [quotify-web] revision [quotify-web-00001-abc] has been deployed and is serving 100 percent of traffic.
Service URL: https://quotify-web-xxxxx-uc.a.run.app
```

¡Tu app estará disponible en esa URL!

## 📝 Configurar API Keys (opcional)

Para habilitar YouTube metadata scraping:
```bash
gcloud run services update quotify-web \
  --region us-central1 \
  --set-env-vars YOUTUBE_API_KEY=tu_api_key_aqui
```

## 🔍 Ver logs
```bash
gcloud logs tail /projects/YOUR-PROJECT-ID/logs/run.googleapis.com%2Frequests --region us-central1
```

## ❓ Problemas comunes

1. **"You do not have permission"**
   - Asegúrate de tener rol de "Cloud Run Admin" en tu proyecto

2. **"Billing account not configured"**
   - Activa billing en: https://console.cloud.google.com/billing

3. **"API not enabled"**
   - Ejecuta: `gcloud services enable run.googleapis.com cloudbuild.googleapis.com`