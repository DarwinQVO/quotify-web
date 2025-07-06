# 🎯 Quotify - Easy Distribution Guide

## For End Users (Non-Technical)

### Quick Setup (5 minutes)

1. **Download Quotify**
   - Get `quotify-dev-distribution.zip`
   - Extract it to your preferred folder

2. **Install Node.js** (if you don't have it)
   - Go to: https://nodejs.org/
   - Download and install the LTS version
   - Restart your computer

3. **Run the Installer**
   - Open Terminal/Command Prompt
   - Drag the `install-dev.sh` file into Terminal
   - Press Enter and follow instructions

4. **Start Using Quotify**
   - Double-click "Quotify Dev.command" on your Desktop
   - Browser will open at http://localhost:5173
   - Start adding YouTube URLs!

### What You Get
- ✅ **Full YouTube Integration** - Extract metadata from any public video
- ✅ **AI Transcription** - Convert speech to text with timestamps
- ✅ **Quote Management** - Organize and cite quotes perfectly
- ✅ **Export Features** - Copy formatted quotes to clipboard
- ✅ **Real-time Updates** - Changes save automatically

### Usage Tips
- Keep the terminal window open while using Quotify
- Add your OpenAI API key for transcription features
- Use Chrome/Firefox for best experience
- Internet connection required for YouTube access

---

## For Developers

### Manual Setup
```bash
# Extract and setup
unzip quotify-dev-distribution.zip
cd quotify-dev-distribution
npm install
npm run dev
```

### Customization
- Edit `src/` files for UI changes
- Modify `src/main/index.js` for backend logic
- Update `package.json` for dependencies

### Deployment Options
1. **Local Development** - `npm run dev`
2. **Build Static** - `npm run build` 
3. **Electron App** - `npm run build` (creates .app/.dmg)

### Architecture
- **Frontend**: React + TypeScript + Tailwind CSS
- **Backend**: Electron Main Process
- **YouTube**: ytdl-core + youtube-dl-exec fallback
- **AI**: OpenAI Whisper API for transcription