// Web API adapter to replace electronAPI calls
// This maintains the same interface but uses web APIs instead

export interface WebAPI {
  scrapeMetadata: (url: string) => Promise<any>;
  transcribeAudio: (data: { url: string; apiKey: string; geminiApiKey?: string; geminiPrompt?: string }) => Promise<any>;
  transcribeFile: (data: { audioFile: string; apiKey: string; geminiApiKey?: string; geminiPrompt?: string }) => Promise<any>;
  generateDeepLink: (data: { url: string; timestamp: number }) => Promise<string>;
  openExternal: (url: string) => Promise<void>;
  saveApiKey: (apiKey: string) => Promise<boolean>;
  loadApiKey: () => Promise<string>;
  saveGeminiConfig: (config: { apiKey: string; prompt: string }) => Promise<boolean>;
  loadGeminiConfig: () => Promise<{ apiKey: string; prompt: string }>;
  saveAppData: (data: { sources: any[]; quotes: any[]; speakers: {[key: string]: string} }) => Promise<boolean>;
  loadAppData: () => Promise<{ sources: any[]; quotes: any[]; speakers: {[key: string]: string} }>;
  reprocessWithGemini: (data: { words: any[]; fullText: string }) => Promise<any>;
}

class WebAPIImplementation implements WebAPI {
  private baseUrl: string;

  constructor() {
    // Use current origin in production, localhost in development
    this.baseUrl = process.env.NODE_ENV === 'development' 
      ? 'http://localhost:5174'
      : window.location.origin;
  }

  private async fetchAPI(endpoint: string, options: RequestInit = {}) {
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: response.statusText }));
      throw new Error(error.error || `HTTP ${response.status}: ${response.statusText}`);
    }

    return response.json();
  }

  async scrapeMetadata(url: string) {
    return this.fetchAPI('/api/scrape-metadata', {
      method: 'POST',
      body: JSON.stringify({ url }),
    });
  }

  async transcribeAudio(data: { url: string; apiKey: string; geminiApiKey?: string; geminiPrompt?: string }) {
    // For web version, we'll show a message about file upload requirement
    throw new Error('For web version, please use file upload instead of URL. Use transcribeFile method.');
  }

  async transcribeFile(data: { audioFile: string; apiKey: string; geminiApiKey?: string; geminiPrompt?: string }) {
    return this.fetchAPI('/api/transcribe-file', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async generateDeepLink(data: { url: string; timestamp: number }) {
    const result = await this.fetchAPI('/api/generate-deep-link', {
      method: 'POST',
      body: JSON.stringify(data),
    });
    return result.deepLink;
  }

  async openExternal(url: string) {
    // Use window.open for web version
    window.open(url, '_blank', 'noopener,noreferrer');
  }

  async saveApiKey(apiKey: string) {
    try {
      await this.fetchAPI('/api/save-api-key', {
        method: 'POST',
        body: JSON.stringify({ apiKey }),
      });
      return true;
    } catch {
      return false;
    }
  }

  async loadApiKey() {
    try {
      const result = await this.fetchAPI('/api/load-api-key');
      return result.apiKey || '';
    } catch {
      return '';
    }
  }

  async saveGeminiConfig(config: { apiKey: string; prompt: string }) {
    try {
      await this.fetchAPI('/api/save-gemini-config', {
        method: 'POST',
        body: JSON.stringify(config),
      });
      return true;
    } catch {
      return false;
    }
  }

  async loadGeminiConfig() {
    try {
      const result = await this.fetchAPI('/api/load-gemini-config');
      return {
        apiKey: result.apiKey || '',
        prompt: result.prompt || ''
      };
    } catch {
      return { apiKey: '', prompt: '' };
    }
  }

  async saveAppData(data: { sources: any[]; quotes: any[]; speakers: {[key: string]: string} }) {
    try {
      await this.fetchAPI('/api/save-app-data', {
        method: 'POST',
        body: JSON.stringify(data),
      });
      return true;
    } catch {
      return false;
    }
  }

  async loadAppData() {
    try {
      const result = await this.fetchAPI('/api/load-app-data');
      return {
        sources: result.sources || [],
        quotes: result.quotes || [],
        speakers: result.speakers || {}
      };
    } catch {
      return { sources: [], quotes: [], speakers: {} };
    }
  }

  async reprocessWithGemini(data: { words: any[]; fullText: string }) {
    return this.fetchAPI('/api/reprocess-with-gemini', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }
}

// Create singleton instance
export const webAPI = new WebAPIImplementation();

// Helper function to detect if we're in Electron or web environment
export function isElectronEnvironment(): boolean {
  return typeof window !== 'undefined' && 'electronAPI' in window;
}

// Universal API that works in both Electron and web environments
export function getAPI(): WebAPI {
  if (isElectronEnvironment()) {
    // Return Electron API with same interface
    return (window as any).electronAPI;
  } else {
    // Return web API
    return webAPI;
  }
}