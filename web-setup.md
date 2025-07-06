# 🎯 Quotify Web Setup

## Quick Start for Users

### Prerequisites
- Node.js 18+ installed
- Terminal/Command Line access

### One-Line Installation

```bash
curl -fsSL https://your-domain.com/install.sh | bash
```

### Manual Installation

1. **Download & Extract**
   ```bash
   # Download the development version
   wget https://your-domain.com/quotify-dev.zip
   unzip quotify-dev.zip
   cd quotify-dev
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Start Quotify**
   ```bash
   npm run dev
   ```

4. **Open in Browser**
   - Go to: http://localhost:5173
   - Keep terminal open while using

### Features
- ✅ Full YouTube metadata extraction
- ✅ Audio transcription with OpenAI Whisper
- ✅ Quote management with timestamps
- ✅ Export functionality
- ✅ Real-time updates

### Troubleshooting

**Port Already in Use?**
```bash
# Kill existing process
pkill -f "vite"
npm run dev
```

**Dependencies Issues?**
```bash
# Clean install
rm -rf node_modules package-lock.json
npm install
```

**Need Help?**
- Check console for error messages
- Ensure Node.js version 18+
- Verify internet connection for YouTube access