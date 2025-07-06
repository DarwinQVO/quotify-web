import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { AlertCircle, Download, Upload } from 'lucide-react';

interface WebAudioExtractorProps {
  url: string;
  onAudioExtracted: (audioBuffer: ArrayBuffer) => void;
  onError: (error: string) => void;
}

export function WebAudioExtractor({ url, onAudioExtracted, onError }: WebAudioExtractorProps) {
  const [isExtracting, setIsExtracting] = useState(false);
  const [showFileUpload, setShowFileUpload] = useState(false);

  const extractAudioFromVideo = async () => {
    setIsExtracting(true);
    
    try {
      // Method 1: Try to get audio stream directly from YouTube
      const response = await fetch('/api/extract-audio', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url })
      });

      if (response.ok) {
        const audioBuffer = await response.arrayBuffer();
        onAudioExtracted(audioBuffer);
        return;
      }

      // Method 2: If server extraction fails, ask user to download manually
      setShowFileUpload(true);
      onError('Please download the audio manually and upload it below');
      
    } catch (error) {
      setShowFileUpload(true);
      onError('Could not extract audio automatically. Please upload an audio file instead.');
    } finally {
      setIsExtracting(false);
    }
  };

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = () => {
        if (reader.result instanceof ArrayBuffer) {
          onAudioExtracted(reader.result);
        }
      };
      reader.readAsArrayBuffer(file);
    }
  };

  const openYouTubeDownloader = () => {
    // Provide instructions for manual download
    const downloadUrl = `https://yt-dlp.org/`;
    window.open(downloadUrl, '_blank');
  };

  if (showFileUpload) {
    return (
      <div className="space-y-4">
        <div className="flex items-center gap-2 text-amber-600">
          <AlertCircle className="h-4 w-4" />
          <span className="text-sm">Automatic extraction failed. Please upload audio manually.</span>
        </div>
        
        <div className="space-y-2">
          <Label htmlFor="audio-file">Upload Audio File (MP3, WAV, M4A, etc.)</Label>
          <Input
            id="audio-file"
            type="file"
            accept="audio/*"
            onChange={handleFileUpload}
          />
        </div>

        <div className="text-xs text-muted-foreground">
          <p>To download audio from YouTube:</p>
          <ol className="list-decimal list-inside space-y-1 mt-2">
            <li>Use a YouTube downloader tool</li>
            <li>Download as audio (MP3/M4A)</li>
            <li>Upload the file above</li>
          </ol>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Button 
        onClick={extractAudioFromVideo}
        disabled={isExtracting}
        className="w-full"
      >
        {isExtracting ? (
          <>
            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
            Extracting Audio...
          </>
        ) : (
          <>
            <Download className="h-4 w-4 mr-2" />
            Extract Audio from Video
          </>
        )}
      </Button>
      
      <div className="text-center">
        <span className="text-xs text-muted-foreground">or</span>
      </div>
      
      <Button 
        variant="outline" 
        onClick={() => setShowFileUpload(true)}
        className="w-full"
      >
        <Upload className="h-4 w-4 mr-2" />
        Upload Audio File Instead
      </Button>
    </div>
  );
}