import React, { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { AlertCircle, Upload } from 'lucide-react';
import { getAPI, isElectronEnvironment } from '@/lib/webAPI';

interface AddSourceDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onAddSource: (url: string, audioFile?: ArrayBuffer) => void;
  apiKey: string;
  onApiKeyChange: (key: string) => void;
}

export function AddSourceDialog({
  open,
  onOpenChange,
  onAddSource,
  apiKey,
  onApiKeyChange
}: AddSourceDialogProps) {
  const [url, setUrl] = useState('');
  const [error, setError] = useState('');
  const [audioFile, setAudioFile] = useState<ArrayBuffer | null>(null);
  const [fileName, setFileName] = useState<string>('');
  const [useFileUpload, setUseFileUpload] = useState(!isElectronEnvironment());

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (useFileUpload) {
      // Handle file upload
      if (!audioFile) {
        setError('Please select an audio file');
        return;
      }
      if (!url.trim()) {
        setError('Please enter the YouTube URL for metadata');
        return;
      }
      if (!apiKey) {
        setError('Please enter your OpenAI API key');
        return;
      }
      
      onAddSource(url, audioFile);
    } else {
      // Handle URL-based (Electron only)
      try {
        const urlObj = new URL(url);
        if (!urlObj.hostname.includes('youtube.com') && !urlObj.hostname.includes('youtu.be')) {
          setError('Please enter a valid YouTube URL');
          return;
        }
      } catch {
        setError('Please enter a valid URL');
        return;
      }

      if (!apiKey) {
        setError('Please enter your OpenAI API key');
        return;
      }

      onAddSource(url);
    }
    
    setUrl('');
    setAudioFile(null);
    setFileName('');
    onOpenChange(false);
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setFileName(file.name);
      const reader = new FileReader();
      reader.onload = () => {
        if (reader.result instanceof ArrayBuffer) {
          setAudioFile(reader.result);
        }
      };
      reader.readAsArrayBuffer(file);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <form onSubmit={handleSubmit}>
          <DialogHeader>
            <DialogTitle>Add YouTube Source</DialogTitle>
            <DialogDescription>
              Paste a YouTube URL to transcribe and extract quotes.
            </DialogDescription>
          </DialogHeader>
          
          <div className="grid gap-4 py-4">
            <div className="grid gap-2">
              <Label htmlFor="url">YouTube URL</Label>
              <Input
                id="url"
                placeholder="https://www.youtube.com/watch?v=..."
                value={url}
                onChange={(e) => setUrl(e.target.value)}
              />
            </div>
            
            {!apiKey && (
              <div className="grid gap-2">
                <Label htmlFor="apiKey">OpenAI API Key</Label>
                <Input
                  id="apiKey"
                  type="password"
                  placeholder="sk-..."
                  value={apiKey}
                  onChange={(e) => onApiKeyChange(e.target.value)}
                />
              </div>
            )}
            
            {apiKey && (
              <div className="grid gap-2">
                <Label>OpenAI API Key</Label>
                <div className="flex items-center justify-between p-3 bg-muted rounded-md">
                  <span className="text-sm text-muted-foreground">
                    API key saved ✓ (••••{apiKey.slice(-4)})
                  </span>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => onApiKeyChange('')}
                  >
                    Change
                  </Button>
                </div>
              </div>
            )}

            {/* Web version: Show file upload option */}
            {!isElectronEnvironment() && (
              <>
                <div className="border-t pt-4">
                  <div className="flex items-center gap-2 mb-3">
                    <Upload className="h-4 w-4" />
                    <Label>Upload Audio File</Label>
                  </div>
                  <div className="text-xs text-muted-foreground mb-3">
                    For web version: Download audio from YouTube first, then upload here
                  </div>
                  <Input
                    type="file"
                    accept="audio/*,.mp3,.wav,.m4a,.ogg,.flac"
                    onChange={handleFileUpload}
                  />
                  {fileName && (
                    <div className="text-sm text-green-600 mt-2">
                      ✓ {fileName} selected
                    </div>
                  )}
                </div>
              </>
            )}
            
            {error && (
              <div className="flex items-center gap-2 text-sm text-destructive">
                <AlertCircle className="h-4 w-4" />
                <span>{error}</span>
              </div>
            )}
          </div>
          
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit">
              {!isElectronEnvironment() ? 'Upload & Transcribe' : 'Add Source'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}