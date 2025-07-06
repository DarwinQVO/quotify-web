const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs').promises;
const { existsSync } = require('fs');
const axios = require('axios');
const FormData = require('form-data');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
const PORT = process.env.PORT || 5174;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.static(path.join(__dirname, 'dist')));

// In-memory storage for demo (replace with database in production)
let appData = {
  sources: [],
  quotes: [],
  speakers: {}
};

let userConfigs = {
  openai_api_key: '',
  gemini_api_key: '',
  gemini_prompt: `You are an expert conversation analyst. Analyze this transcript and identify speakers using advanced contextual understanding.

YOUR TASK:
1. Detect the EXACT number of unique speakers in this conversation
2. Identify speaker changes by analyzing:
   - Conversational flow and turn-taking patterns
   - Questions vs answers (interviewers ask, interviewees respond)
   - Topic transitions and speaking styles
   - First-person vs second-person references
   - Names mentioned in context ("I'm Alex", "Thanks Rajiv")
   - Conversational cues ("So tell us", "Well", "You know")

3. Use real names when clearly mentioned, otherwise use descriptive labels like "Interviewer", "Guest", "Host"

CRITICAL RULES:
- Preserve original timestamps - you're only identifying speakers, not modifying timing
- Fix grammatical errors and add proper punctuation (periods, commas, question marks)
- Remove filler words like "umm", "uhh", "uh", "um", "hmm", "ah", "eh" completely
- Fix obvious transcription errors (misspelled company names, technical terms)
- Analyze the ENTIRE conversation context before assigning speakers
- If unsure between speakers, choose the most contextually appropriate one
- Pay attention to conversational patterns: who asks questions vs who answers

CORRECTIONS TO MAKE:
- Remove filler words: "um", "umm", "uh", "uhh", "ah", "eh", "hmm", "like" (when used as filler)
- Add proper punctuation: periods at sentence ends, commas for pauses, question marks for questions
- Fix grammar: verb tenses, subject-verb agreement, proper capitalization
- Correct technical terms and company names
- Clean up false starts and repetitions ("I I think" → "I think")

CONTEXT ANALYSIS HINTS:
- Interviewers often say: "tell us", "how do you", "can you explain", "what's your"
- Guests often say: "well", "so", "I think", "my experience", "when I was"
- Names are often introduced: "I'm [Name]", "Thanks [Name]", "[Name] at [Company]"
- Speaking style consistency within each speaker

OUTPUT FORMAT - Return ONLY this JSON structure:
{
  "speakers_detected": number,
  "segments": [
    {
      "start_word_index": number,
      "end_word_index": number, 
      "speaker_id": "Speaker name or identifier",
      "corrected_words": [
        {"index": number, "corrected_text": "corrected_word"}
      ]
    }
  ]
}

Word indices refer to the numbered position [0], [1], [2]... in the transcript.`
};

// Helper function to extract YouTube video ID
function extractVideoId(url) {
  const match = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/);
  return match ? match[1] : null;
}

// API Routes

// Scrape YouTube metadata using YouTube Data API v3
app.post('/api/scrape-metadata', async (req, res) => {
  try {
    const { url } = req.body;
    
    if (!url || typeof url !== 'string') {
      return res.status(400).json({ error: 'Invalid URL provided' });
    }

    const youtubeRegex = /^(https?\:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+/;
    if (!youtubeRegex.test(url)) {
      return res.status(400).json({ error: 'Please provide a valid YouTube URL' });
    }

    const videoId = extractVideoId(url);
    if (!videoId) {
      return res.status(400).json({ error: 'Could not extract video ID from URL' });
    }

    // Use YouTube Data API (you'll need to set YOUTUBE_API_KEY environment variable)
    const youtubeApiKey = process.env.YOUTUBE_API_KEY;
    
    if (!youtubeApiKey) {
      // Fallback: Extract basic info from URL pattern
      console.log('⚠️ YouTube API key not found, using fallback metadata extraction');
      
      const metadata = {
        title: `YouTube Video ${videoId}`,
        channel: 'Unknown Channel',
        duration: 0,
        publish_date: new Date().toISOString(),
        views: 0,
        thumbnail: `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`,
        url: url,
        id: videoId
      };
      
      return res.json(metadata);
    }

    // Use YouTube Data API
    const apiUrl = `https://www.googleapis.com/youtube/v3/videos?id=${videoId}&key=${youtubeApiKey}&part=snippet,statistics,contentDetails`;
    
    const response = await axios.get(apiUrl);
    
    if (!response.data.items || response.data.items.length === 0) {
      return res.status(404).json({ error: 'Video not found or is private' });
    }

    const video = response.data.items[0];
    
    // Parse duration from ISO 8601 format (PT4M13S -> 253 seconds)
    const duration = parseDuration(video.contentDetails.duration);
    
    const metadata = {
      title: video.snippet.title || 'Unknown Title',
      channel: video.snippet.channelTitle || 'Unknown Channel',
      duration: duration,
      publish_date: video.snippet.publishedAt || '',
      views: parseInt(video.statistics.viewCount) || 0,
      thumbnail: video.snippet.thumbnails?.maxresdefault?.url || 
                video.snippet.thumbnails?.high?.url || 
                video.snippet.thumbnails?.medium?.url || '',
      url: url,
      id: videoId
    };

    res.json(metadata);

  } catch (error) {
    console.error('Metadata scraping error:', error.message);
    
    if (error.response?.status === 403) {
      return res.status(403).json({ error: 'YouTube API quota exceeded or invalid API key' });
    }
    
    res.status(500).json({ error: `Failed to scrape metadata: ${error.message}` });
  }
});

// Parse YouTube duration from ISO 8601 format
function parseDuration(duration) {
  const match = duration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
  if (!match) return 0;
  
  const hours = parseInt(match[1]) || 0;
  const minutes = parseInt(match[2]) || 0;
  const seconds = parseInt(match[3]) || 0;
  
  return hours * 3600 + minutes * 60 + seconds;
}

// Transcribe audio using direct YouTube URL (simplified for web)
app.post('/api/transcribe-audio', async (req, res) => {
  try {
    const { url, apiKey, geminiApiKey, geminiPrompt } = req.body;
    
    if (!apiKey) {
      return res.status(400).json({ error: 'OpenAI API key is required' });
    }

    // For web version, we'll use a different approach
    // Option 1: Use a service that can extract audio from YouTube URLs
    // Option 2: Ask user to upload audio file directly
    // Option 3: Use browser APIs to capture audio
    
    // For now, return a placeholder response that maintains the same interface
    res.status(501).json({ 
      error: 'Audio transcription requires file upload in web version. Please upload an audio file directly.' 
    });

  } catch (error) {
    console.error('Transcription error:', error.message);
    res.status(500).json({ error: `Transcription failed: ${error.message}` });
  }
});

// Alternative: Audio file upload endpoint
app.post('/api/transcribe-file', async (req, res) => {
  try {
    const { audioFile, apiKey, geminiApiKey, geminiPrompt } = req.body;
    
    if (!apiKey) {
      return res.status(400).json({ error: 'OpenAI API key is required' });
    }

    if (!audioFile) {
      return res.status(400).json({ error: 'Audio file is required' });
    }

    // Convert base64 to buffer
    const audioBuffer = Buffer.from(audioFile, 'base64');
    
    // Transcribe with OpenAI Whisper
    const formData = new FormData();
    formData.append('file', audioBuffer, {
      filename: 'audio.webm',
      contentType: 'audio/webm'
    });
    formData.append('model', 'whisper-1');
    formData.append('response_format', 'verbose_json');
    formData.append('timestamp_granularities[]', 'word');
    
    const response = await axios.post(
      'https://api.openai.com/v1/audio/transcriptions',
      formData,
      {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          ...formData.getHeaders()
        },
        maxBodyLength: Infinity,
        maxContentLength: Infinity,
        timeout: 300000
      }
    );

    const result = response.data;
    const words = result.words?.map(word => ({
      text: word.word.trim(),
      start: word.start,
      end: word.end,
      speaker: null
    })) || [];

    // Process with Gemini if configured
    let finalWords = words;
    let speakerInfo = {};
    
    if (geminiApiKey && geminiPrompt && result.text) {
      try {
        const genAI = new GoogleGenerativeAI(geminiApiKey);
        const model = genAI.getGenerativeModel({ model: 'gemini-2.5-pro' });
        
        const textForAnalysis = words.map((word, index) => `[${index}] ${word.text}`).join(' ');
        const fullPrompt = `${geminiPrompt}\n\nTRANSCRIPT TO ANALYZE:\n${textForAnalysis}`;
        
        const geminiResult = await model.generateContent(fullPrompt);
        const geminiText = geminiResult.response.text();
        
        const cleanedResponse = geminiText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
        const analysis = JSON.parse(cleanedResponse);
        
        if (analysis.segments && Array.isArray(analysis.segments)) {
          for (const segment of analysis.segments) {
            const startIndex = parseInt(segment.start_word_index);
            const endIndex = parseInt(segment.end_word_index);
            
            if (!isNaN(startIndex) && !isNaN(endIndex) && startIndex >= 0 && endIndex < finalWords.length) {
              for (let i = startIndex; i <= endIndex && i < finalWords.length; i++) {
                if (finalWords[i] && segment.speaker_id) {
                  finalWords[i].speaker = segment.speaker_id;
                }
              }
            }
          }
        }
        
        const uniqueSpeakers = [...new Set(finalWords.map(w => w.speaker).filter(Boolean))];
        uniqueSpeakers.forEach((speaker, index) => {
          speakerInfo[`speaker_${index}`] = speaker;
        });
        
      } catch (geminiError) {
        console.error('Gemini processing error:', geminiError.message);
      }
    }

    res.json({
      words: finalWords,
      full_text: result.text,
      speakers: speakerInfo
    });

  } catch (error) {
    console.error('File transcription error:', error.message);
    res.status(500).json({ error: `File transcription failed: ${error.message}` });
  }
});

// Generate deep link
app.post('/api/generate-deep-link', async (req, res) => {
  try {
    const { url, timestamp } = req.body;
    const videoIdMatch = url.match(/(?:v=|youtu\.be\/)([^&\s]+)/);
    const videoId = videoIdMatch ? videoIdMatch[1] : '';
    const deepLink = `https://youtu.be/${videoId}?t=${Math.floor(timestamp)}`;
    res.json({ deepLink });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Storage endpoints (using in-memory for demo, use database in production)
app.post('/api/save-api-key', async (req, res) => {
  try {
    const { apiKey } = req.body;
    userConfigs.openai_api_key = apiKey;
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/load-api-key', async (req, res) => {
  try {
    res.json({ apiKey: userConfigs.openai_api_key });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/save-gemini-config', async (req, res) => {
  try {
    const { apiKey, prompt } = req.body;
    userConfigs.gemini_api_key = apiKey;
    userConfigs.gemini_prompt = prompt;
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/load-gemini-config', async (req, res) => {
  try {
    res.json({ 
      apiKey: userConfigs.gemini_api_key,
      prompt: userConfigs.gemini_prompt
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/save-app-data', async (req, res) => {
  try {
    const { sources, quotes, speakers } = req.body;
    appData = { sources: sources || [], quotes: quotes || [], speakers: speakers || {} };
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/load-app-data', async (req, res) => {
  try {
    res.json(appData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/reprocess-with-gemini', async (req, res) => {
  try {
    const { words, fullText } = req.body;
    
    if (!userConfigs.gemini_api_key || !userConfigs.gemini_prompt) {
      return res.status(400).json({ error: 'Gemini configuration not found' });
    }
    
    const genAI = new GoogleGenerativeAI(userConfigs.gemini_api_key);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-pro' });
    
    const textForAnalysis = words.map((word, index) => `[${index}] ${word.text}`).join(' ');
    const fullPrompt = `${userConfigs.gemini_prompt}\n\nTRANSCRIPT TO ANALYZE:\n${textForAnalysis}`;
    
    const geminiResult = await model.generateContent(fullPrompt);
    const geminiText = geminiResult.response.text();
    
    const cleanedResponse = geminiText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
    const analysis = JSON.parse(cleanedResponse);
    
    let finalWords = [...words];
    let speakerInfo = {};
    
    if (analysis.segments && Array.isArray(analysis.segments)) {
      for (const segment of analysis.segments) {
        const startIndex = parseInt(segment.start_word_index);
        const endIndex = parseInt(segment.end_word_index);
        
        if (!isNaN(startIndex) && !isNaN(endIndex) && startIndex >= 0 && endIndex < finalWords.length) {
          for (let i = startIndex; i <= endIndex && i < finalWords.length; i++) {
            if (finalWords[i] && segment.speaker_id) {
              finalWords[i].speaker = segment.speaker_id;
            }
          }
        }
      }
    }
    
    const uniqueSpeakers = [...new Set(finalWords.map(w => w.speaker).filter(Boolean))];
    uniqueSpeakers.forEach((speaker, index) => {
      speakerInfo[`speaker_${index}`] = speaker;
    });
    
    res.json({
      words: finalWords,
      full_text: fullText,
      speakers: speakerInfo
    });
    
  } catch (error) {
    console.error('Gemini reprocessing error:', error.message);
    res.status(500).json({ error: `Reprocessing failed: ${error.message}` });
  }
});

// Serve React app
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`🚀 Quotify Web Server running on port ${PORT}`);
  console.log(`📱 Access at: http://localhost:${PORT}`);
});

module.exports = app;