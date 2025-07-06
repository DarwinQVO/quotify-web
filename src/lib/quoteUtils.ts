import { Word, Quote } from '@/types';

// Group words into speaker segments based on time gaps
function getTranscriptSegments(words: Word[]) {
  if (!words.length) return [];
  
  const segments = [];
  let currentSegment = {
    speakerId: `speaker_0`,
    words: [words[0]],
    startTime: words[0].start,
    endTime: words[0].end
  };
  
  for (let i = 1; i < words.length; i++) {
    const word = words[i];
    const prevWord = words[i - 1];
    const pauseDuration = word.start - prevWord.end;
    
    // If there's a pause longer than 2 seconds, assume new speaker
    if (pauseDuration > 2.0) {
      segments.push(currentSegment);
      currentSegment = {
        speakerId: `speaker_${segments.length}`,
        words: [word],
        startTime: word.start,
        endTime: word.end
      };
    } else {
      currentSegment.words.push(word);
      currentSegment.endTime = word.end;
    }
  }
  
  segments.push(currentSegment);
  return segments;
}

export function createQuote(
  words: Word[],
  selectedRange: { start: number; end: number },
  videoUrl: string,
  metadata: { title: string; channel: string; publish_date: string },
  speakers: {[key: string]: string} = {},
  sourceId: string
): Quote {
  const selectedWords = words.filter(
    w => w.start >= selectedRange.start && w.end <= selectedRange.end
  );
  
  if (selectedWords.length === 0) {
    throw new Error('No words selected');
  }
  
  const text = selectedWords.map(w => w.text).join(' ');
  
  // Find the speaker for this quote based on the timestamp
  const timestamp = selectedWords[0].start;
  let speaker = 'Speaker';
  
  // Find which speaker segment this quote belongs to
  const segments = getTranscriptSegments(words);
  for (const segment of segments) {
    if (timestamp >= segment.startTime && timestamp <= segment.endTime) {
      speaker = speakers[segment.speakerId] || `Speaker ${parseInt(segment.speakerId.split('_')[1]) + 1}`;
      break;
    }
  }
  
  // Format date - handle YYYYMMDD format from YouTube
  let formattedDate = 'Unknown Date';
  if (metadata.publish_date) {
    try {
      let dateString = metadata.publish_date.toString();
      if (dateString.length === 8) {
        // Format: YYYYMMDD
        const year = dateString.substring(0, 4);
        const month = dateString.substring(4, 6);
        const day = dateString.substring(6, 8);
        const date = new Date(parseInt(year), parseInt(month) - 1, parseInt(day));
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        formattedDate = monthNames[date.getMonth()] + ' ' + date.getFullYear();
      } else {
        // Try parsing as regular date
        const date = new Date(metadata.publish_date);
        if (!isNaN(date.getTime())) {
          const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          formattedDate = monthNames[date.getMonth()] + ' ' + date.getFullYear();
        }
      }
    } catch (error) {
      console.warn('Failed to parse date:', metadata.publish_date);
      formattedDate = 'Unknown Date';
    }
  }
  
  // Use curly/smart quotes for better typography
  const quotedText = '\u201C' + text + '\u201D';
  
  // Generate deep link
  const deepLink = generateDeepLink(videoUrl, timestamp);
  
  // Create citation
  const citation = speaker + ' (' + formattedDate + ')';
  
  return {
    id: 'quote-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9),
    text: quotedText,
    speaker,
    timestamp,
    videoUrl,
    citation,
    deepLink,
    sourceId
  };
}

export function generateDeepLink(videoUrl: string, timestamp: number): string {
  const videoIdMatch = videoUrl.match(/(?:v=|youtu\.be\/)([^&\s]+)/);
  const videoId = videoIdMatch ? videoIdMatch[1] : '';
  return 'https://youtu.be/' + videoId + '?t=' + Math.floor(timestamp);
}

export function formatQuoteForExport(quote: Quote): string {
  return quote.text + ' — ' + quote.citation + ' [' + quote.deepLink + ']';
}

// New function for clipboard with embedded link
export function formatQuoteForClipboard(quote: Quote): string {
  // Extract speaker and date from citation  
  const speaker = quote.speaker;
  const citationMatch = quote.citation.match(/\((.+)\)/);
  const date = citationMatch ? citationMatch[1] : 'Unknown Date';
  
  // Keep curly quotes for better typography
  // Format: "Quote text" Speaker (Date) with embedded link
  return `${quote.text} [${speaker} (${date})](${quote.deepLink})`;
}

export function formatQuotesForClipboard(quotes: Quote[]): string {
  return quotes.map(formatQuoteForClipboard).join('\n\n');
}