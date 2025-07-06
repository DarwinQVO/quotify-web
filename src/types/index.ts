export interface VideoMetadata {
  title: string;
  channel: string;
  duration: number;
  publish_date: string;
  views: number;
  thumbnail: string;
  url: string;
}

export interface Word {
  text: string;
  start: number;
  end: number;
  speaker?: string;
}

export interface TranscriptionResult {
  words: Word[];
  full_text: string;
  speakers?: {[key: string]: string};
}

export interface Quote {
  id: string;
  text: string;
  speaker: string;
  timestamp: number;
  videoUrl: string;
  citation: string;
  deepLink: string;
  sourceId: string;
}

export interface Source {
  id: string;
  url: string;
  status: 'idle' | 'scraping' | 'transcribing' | 'ready' | 'error';
  progress: number;
  metadata?: VideoMetadata;
  transcript?: TranscriptionResult;
  error?: string;
  speakers?: {[key: string]: string}; // Speaker names specific to this source
}