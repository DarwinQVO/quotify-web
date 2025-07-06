import { Word } from '@/types';

const FILLER_WORDS = ['um', 'uh', 'like', 'you know', 'i mean', 'sort of', 'kind of'];
const MIN_WORD_LENGTH = 1;
const MAX_PAUSE_DURATION = 10; // seconds

export function cleanTranscript(words: Word[]): Word[] {
  return words
    .filter(word => {
      // Remove very short words that are likely noise
      if (word.text.length < MIN_WORD_LENGTH) return false;
      
      // Remove filler words
      const lowerText = word.text.toLowerCase();
      if (FILLER_WORDS.some(filler => lowerText === filler)) return false;
      
      return true;
    })
    .map((word, index, filteredWords) => {
      // Check for long pauses
      if (index > 0) {
        const prevWord = filteredWords[index - 1];
        const pauseDuration = word.start - prevWord.end;
        
        if (pauseDuration > MAX_PAUSE_DURATION) {
          // Mark as potential speaker change
          return { ...word, speaker: 'Speaker 2' };
        }
      }
      
      return word;
    });
}

export function removeRepeatedWords(words: Word[]): Word[] {
  return words.filter((word, index) => {
    if (index === 0) return true;
    const prevWord = words[index - 1];
    return word.text.toLowerCase() !== prevWord.text.toLowerCase() || 
           word.start - prevWord.end > 0.5;
  });
}