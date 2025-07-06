import React, { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';
import { getAPI } from '@/lib/webAPI';

interface GeminiConfigDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  apiKey: string;
  prompt: string;
  onConfigChange: (config: { apiKey: string; prompt: string }) => void;
}

export function GeminiConfigDialog({
  open,
  onOpenChange,
  apiKey,
  prompt,
  onConfigChange
}: GeminiConfigDialogProps) {
  const [localApiKey, setLocalApiKey] = useState(apiKey);
  const [localPrompt, setLocalPrompt] = useState(prompt);
  const [isSaving, setIsSaving] = useState(false);
  const { toast } = useToast();
  const api = getAPI();

  const defaultPrompt = `You are an expert conversation analyst. Analyze this transcript and identify speakers using advanced contextual understanding.

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

Word indices refer to the numbered position [0], [1], [2]... in the transcript.`;

  useEffect(() => {
    setLocalApiKey(apiKey);
    setLocalPrompt(prompt || defaultPrompt);
  }, [apiKey, prompt]);

  const handleSave = async () => {
    if (!localApiKey.trim()) {
      toast({
        title: "API Key Required",
        description: "Please enter your Gemini API key",
        variant: "destructive",
      });
      return;
    }

    if (!localPrompt.trim()) {
      toast({
        title: "Prompt Required", 
        description: "Please enter a prompt for Gemini",
        variant: "destructive",
      });
      return;
    }

    setIsSaving(true);
    
    try {
      const success = await api.saveGeminiConfig({
        apiKey: localApiKey.trim(),
        prompt: localPrompt.trim()
      });

      if (success) {
        onConfigChange({
          apiKey: localApiKey.trim(),
          prompt: localPrompt.trim()
        });
        
        toast({
          title: "Settings saved",
          description: "Gemini configuration has been updated",
        });
        
        onOpenChange(false);
      } else {
        throw new Error('Failed to save configuration');
      }
    } catch (error) {
      toast({
        title: "Save failed",
        description: "Could not save Gemini configuration",
        variant: "destructive",
      });
    } finally {
      setIsSaving(false);
    }
  };

  const handleResetPrompt = () => {
    setLocalPrompt(defaultPrompt);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Configure Gemini AI</DialogTitle>
        </DialogHeader>
        
        <div className="space-y-6">
          <div className="space-y-2">
            <Label htmlFor="gemini-api-key">Gemini API Key</Label>
            <Input
              id="gemini-api-key"
              type="password"
              placeholder="Enter your Gemini API key"
              value={localApiKey}
              onChange={(e) => setLocalApiKey(e.target.value)}
            />
            <p className="text-xs text-muted-foreground">
              Get your API key from{' '}
              <a 
                href="#" 
                onClick={(e) => {
                  e.preventDefault();
                  window.electronAPI.openExternal('https://aistudio.google.com/app/apikey');
                }}
                className="text-blue-500 hover:text-blue-700 underline"
              >
                Google AI Studio
              </a>
            </p>
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label htmlFor="gemini-prompt">Gemini Prompt</Label>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={handleResetPrompt}
              >
                Reset to Default
              </Button>
            </div>
            <Textarea
              id="gemini-prompt"
              placeholder="Enter the prompt for Gemini to analyze transcripts"
              value={localPrompt}
              onChange={(e) => setLocalPrompt(e.target.value)}
              rows={12}
              className="font-mono text-sm"
            />
            <p className="text-xs text-muted-foreground">
              This prompt will be used to instruct Gemini on how to analyze transcripts for speaker identification and text corrections.
            </p>
          </div>

          <div className="bg-muted p-4 rounded-lg">
            <h4 className="text-sm font-medium mb-2">How it works:</h4>
            <ul className="text-xs text-muted-foreground space-y-1">
              <li>• Gemini analyzes the transcript after Whisper completes</li>
              <li>• Detects number of speakers by conversation context</li>
              <li>• Assigns speaker names when mentioned in transcript</li>
              <li>• Corrects minor errors (company names, punctuation) without changing actual words</li>
              <li>• Falls back to basic transcript if Gemini fails</li>
            </ul>
          </div>

          <div className="flex justify-end gap-3">
            <Button
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={isSaving}
            >
              Cancel
            </Button>
            <Button
              onClick={handleSave}
              disabled={isSaving}
            >
              {isSaving ? 'Saving...' : 'Save Configuration'}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}