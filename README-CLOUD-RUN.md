# Quotify Web - Cloud Run Deployment Guide

## 🚀 Quick Deploy

### Prerequisites
1. **Google Cloud Project** with billing enabled
2. **gcloud CLI** installed and authenticated
3. **Docker** installed

### One-Click Deploy
```bash
# Replace YOUR_PROJECT_ID with your actual GCP project ID
./deploy-to-cloud-run.sh YOUR_PROJECT_ID
```

## 📋 Manual Deployment Steps

### 1. Setup Google Cloud
```bash
# Install gcloud CLI (if not already installed)
# macOS: brew install google-cloud-sdk
# Or download from: https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 2. Build and Deploy
```bash
# Build Docker image
docker build -t gcr.io/YOUR_PROJECT_ID/quotify-web .

# Push to Google Container Registry
docker push gcr.io/YOUR_PROJECT_ID/quotify-web

# Deploy to Cloud Run
gcloud run deploy quotify-web \
    --image gcr.io/YOUR_PROJECT_ID/quotify-web \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated \
    --memory 2Gi \
    --cpu 1 \
    --timeout 3600 \
    --port 5174
```

## ⚙️ Configuration

### Environment Variables
Set these in Cloud Run console or via gcloud:

```bash
# Optional: YouTube API key for enhanced metadata scraping
gcloud run services update quotify-web \
    --region us-central1 \
    --set-env-vars YOUTUBE_API_KEY=your_youtube_api_key_here
```

### Resource Limits
- **Memory**: 2GB (sufficient for AI processing)
- **CPU**: 1 vCPU 
- **Timeout**: 60 minutes (for long transcriptions)
- **Concurrency**: 100 requests per instance
- **Max Instances**: 10 (adjust based on expected traffic)

## 🔑 API Keys Setup

Users need to provide their own API keys in the web interface:

1. **OpenAI API Key** (required)
   - For Whisper audio transcription
   - Get at: https://platform.openai.com/api-keys

2. **Google Gemini API Key** (optional)
   - For advanced speaker detection
   - Get at: https://ai.google.dev/

3. **YouTube API Key** (optional)
   - For enhanced video metadata
   - Get at: https://console.cloud.google.com/apis/credentials

## 📊 Monitoring

### View Logs
```bash
gcloud logs tail /projects/YOUR_PROJECT_ID/logs/run.googleapis.com%2Frequests
```

### Metrics
- Access Cloud Run metrics in Google Cloud Console
- Monitor request latency, error rates, and resource usage

## 🔒 Security Notes

- The app stores API keys temporarily (in-memory only)
- No persistent storage of user data by default
- All communication is over HTTPS
- Consider implementing authentication for production use

## 💰 Cost Optimization

- **Pay per request** - only charged when app is being used
- **Scales to zero** - no cost when idle
- **Automatic scaling** - handles traffic spikes efficiently

Estimated costs for typical usage:
- Light usage (< 100 transcriptions/month): ~$5-10
- Medium usage (< 1000 transcriptions/month): ~$20-40
- Heavy usage varies based on video length and frequency

## 🛠️ Troubleshooting

### Common Issues

1. **Docker build fails**
   ```bash
   # Clear Docker cache
   docker system prune -a
   ```

2. **Permission denied**
   ```bash
   # Re-authenticate
   gcloud auth login
   gcloud auth configure-docker
   ```

3. **Service timeout**
   - Increase timeout for large video files
   - Consider implementing chunking for very long videos

### Local Testing
```bash
# Test locally before deploying
npm run build
npm start

# Test with Docker
docker build -t quotify-web .
docker run -p 5174:5174 quotify-web
```

## 🎯 Differences from Electron Version

### ✅ What Works the Same
- All UI functionality
- OpenAI Whisper transcription  
- Gemini AI speaker detection
- Quote extraction and management
- Video playback and navigation

### ⚠️ Web Limitations
- **Audio processing**: Users need to upload audio files instead of automatic YouTube download
- **File storage**: Uses in-memory storage (consider adding database for persistence)
- **Offline mode**: Requires internet connection

### 🔧 Enhancements for Web
- **Shareable URLs**: Easy to share with team members
- **Cross-platform**: Works on any device with browser
- **No installation**: Instant access
- **Automatic updates**: Always latest version
- **Scalable**: Handles multiple users simultaneously

## 📈 Future Enhancements

Consider adding:
- User authentication
- Persistent database (PostgreSQL/MongoDB)
- File upload for large audio files
- WebRTC for real-time transcription
- Integration with cloud storage (GCS/S3)

---

**Your Quotify web app maintains 100% of the core functionality while gaining cloud scalability!** 🚀