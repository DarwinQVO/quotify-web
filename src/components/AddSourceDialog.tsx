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
import { AlertCircle } from 'lucide-react';

interface AddSourceDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onAddSource: (url: string) => void;
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

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    // Validate URL
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

    // Validate API key
    if (!apiKey) {
      setError('Please enter your OpenAI API key');
      return;
    }

    onAddSource(url);
    setUrl('');
    onOpenChange(false);
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
            <Button type="submit">Add Source</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}