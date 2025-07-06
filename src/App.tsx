import React, { useState, useEffect, useRef } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import ReactPlayer from 'react-player';
import { Moon, Sun, Copy, Download, Plus, Command, Trash2, Settings, ChevronLeft, ChevronRight } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { SourceCard } from '@/components/SourceCard';
import { TranscriptPane } from '@/components/TranscriptPane';
import { QuoteList } from '@/components/QuoteList';
import { AddSourceDialog } from '@/components/AddSourceDialog';
import { GeminiConfigDialog } from '@/components/GeminiConfigDialog';
import { useToast } from '@/hooks/use-toast';
import { Toaster } from '@/components/ui/toaster';
import { Source, Quote, VideoMetadata, TranscriptionResult } from '@/types';
import { createQuote, formatQuotesForClipboard } from '@/lib/quoteUtils';
import { cleanTranscript } from '@/lib/cleanTranscript';
import { getAPI } from '@/lib/webAPI';

declare global {
  interface Window {
    electronAPI: {
      scrapeMetadata: (url: string) => Promise<VideoMetadata>;
      transcribeAudio: (data: { url: string; apiKey: string; geminiApiKey?: string; geminiPrompt?: string }) => Promise<TranscriptionResult>;
      generateDeepLink: (data: { url: string; timestamp: number }) => Promise<string>;
      openExternal: (url: string) => Promise<void>;
      saveApiKey: (apiKey: string) => Promise<boolean>;
      loadApiKey: () => Promise<string>;
      saveGeminiConfig: (config: { apiKey: string; prompt: string }) => Promise<boolean>;
      loadGeminiConfig: () => Promise<{ apiKey: string; prompt: string }>;
      saveAppData: (data: { sources: Source[]; quotes: Quote[]; speakers: {[key: string]: string} }) => Promise<boolean>;
      loadAppData: () => Promise<{ sources: Source[]; quotes: Quote[]; speakers: {[key: string]: string} }>;
      reprocessWithGemini: (data: { words: any[]; fullText: string }) => Promise<TranscriptionResult>;
    };
  }
}

function App() {
  const [sources, setSources] = useState<Source[]>([]);
  const [selectedSourceId, setSelectedSourceId] = useState<string | null>(null);
  const [quotes, setQuotes] = useState<Quote[]>([]);
  const [selectedQuotes, setSelectedQuotes] = useState<Set<string>>(new Set());
  const [showAllQuotes, setShowAllQuotes] = useState(false);
  const [isDark, setIsDark] = useState(() => {
    const savedTheme = localStorage.getItem('theme');
    return savedTheme ? savedTheme === 'dark' : false; // Default to light theme
  });
  const [isAddSourceOpen, setIsAddSourceOpen] = useState(false);
  const [isGeminiConfigOpen, setIsGeminiConfigOpen] = useState(false);
  const [apiKey, setApiKey] = useState('');
  const [geminiApiKey, setGeminiApiKey] = useState('');
  const [geminiPrompt, setGeminiPrompt] = useState('');
  
  // Get universal API (works in both Electron and web)
  const api = getAPI();
  const [isLeftSidebarCollapsed, setIsLeftSidebarCollapsed] = useState(() => {
    return localStorage.getItem('leftSidebarCollapsed') === 'true';
  });
  const [isRightSidebarCollapsed, setIsRightSidebarCollapsed] = useState(() => {
    return localStorage.getItem('rightSidebarCollapsed') === 'true';
  });
  const [isPlayerLoading, setIsPlayerLoading] = useState(false);
  const [playerError, setPlayerError] = useState<string | null>(null);
  const [playerReadyState, setPlayerReadyState] = useState<{[key: string]: boolean}>({});
  const [lastSelectedSourceId, setLastSelectedSourceId] = useState<string | null>(null);
  const [preloadedSources, setPreloadedSources] = useState<Set<string>>(new Set());
  const playerRef = useRef<ReactPlayer>(null);
  const { toast } = useToast();

  // Load saved data on startup
  useEffect(() => {
    const loadSavedData = async () => {
      try {
        // Load API keys
        const savedKey = await api.loadApiKey();
        if (savedKey) {
          setApiKey(savedKey);
        }

        // Load Gemini configuration
        const geminiConfig = await api.loadGeminiConfig();
        if (geminiConfig) {
          setGeminiApiKey(geminiConfig.apiKey);
          setGeminiPrompt(geminiConfig.prompt);
        }

        // Load app data (sources, quotes, and speakers)
        const appData = await api.loadAppData();
        if (appData.sources) {
          setSources(appData.sources);
        }
        if (appData.quotes) {
          setQuotes(appData.quotes);
        }
        // Legacy speakers data migration - move to individual sources
        if (appData.speakers && Object.keys(appData.speakers).length > 0) {
          setSources(prev => prev.map(source => ({
            ...source,
            speakers: source.speakers || appData.speakers
          })));
        }

        toast({
          title: "Data restored",
          description: `Loaded ${appData.sources?.length || 0} sources and ${appData.quotes?.length || 0} quotes`,
        });
      } catch (error) {
        console.error('Failed to load saved data:', error);
      }
    };
    loadSavedData();
  }, []);

  // Theme management
  useEffect(() => {
    document.documentElement.classList.toggle('dark', isDark);
    localStorage.setItem('theme', isDark ? 'dark' : 'light');
  }, [isDark]);

  // Sidebar state persistence
  useEffect(() => {
    localStorage.setItem('leftSidebarCollapsed', isLeftSidebarCollapsed.toString());
  }, [isLeftSidebarCollapsed]);

  useEffect(() => {
    localStorage.setItem('rightSidebarCollapsed', isRightSidebarCollapsed.toString());
  }, [isRightSidebarCollapsed]);

  // Auto-save data when sources or quotes change
  useEffect(() => {
    const saveData = async () => {
      try {
        await api.saveAppData({ sources, quotes, speakers: {} });
      } catch (error) {
        console.error('Failed to save app data:', error);
      }
    };

    // Only save if we have data (avoid saving empty state on first load)
    if (sources.length > 0 || quotes.length > 0) {
      saveData();
    }
  }, [sources, quotes]);

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setIsAddSourceOpen(true);
      }
      if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key === 'c') {
        e.preventDefault();
        handleCopyQuotes();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedQuotes, quotes]);

  // Enterprise-level source change optimization
  useEffect(() => {
    if (selectedSourceId && selectedSourceId !== lastSelectedSourceId) {
      console.log('🔄 Source changed:', { from: lastSelectedSourceId, to: selectedSourceId });
      
      const selectedSource = sources.find(s => s.id === selectedSourceId);
      
      // If source is ready and has transcript, show INSTANTLY
      if (selectedSource?.status === 'ready' && selectedSource?.transcript) {
        console.log('⚡ INSTANT transcript display - source ready');
        setIsPlayerLoading(false);
        setPlayerError(null);
        setLastSelectedSourceId(selectedSourceId);
        return;
      }
      
      // Only show loading for sources that aren't ready yet
      setIsPlayerLoading(true);
      setPlayerError(null);
      
      // Optimistic loading timeout (shorter for better UX)
      const loadingTimeout = setTimeout(() => {
        if (isPlayerLoading) {
          console.log('📡 Still loading, but showing transcript anyway...');
          setIsPlayerLoading(false);
        }
      }, 1500);
      
      setLastSelectedSourceId(selectedSourceId);
      return () => clearTimeout(loadingTimeout);
    }
  }, [selectedSourceId, lastSelectedSourceId, sources, isPlayerLoading]);

  // Enterprise player ready handler with state tracking
  const handlePlayerReady = () => {
    setIsPlayerLoading(false);
    setPlayerError(null);
    
    // Mark this source as ready for future instant switching
    if (selectedSourceId) {
      setPlayerReadyState(prev => ({
        ...prev,
        [selectedSourceId]: true
      }));
    }
    
    if (playerRef.current) {
      // Smart reset - only if this is a fresh load (not a switch)
      const shouldReset = !playerReadyState[selectedSourceId || ''];
      
      if (shouldReset) {
        console.log('🔄 Fresh load - resetting to start');
        playerRef.current.seekTo(0, 'seconds');
        
        const internalPlayer = playerRef.current.getInternalPlayer();
        if (internalPlayer) {
          if (typeof internalPlayer.pauseVideo === 'function') {
            // YouTube player
            internalPlayer.pauseVideo();
          } else if (typeof internalPlayer.pause === 'function') {
            // HTML5 video
            internalPlayer.pause();
          }
        }
      } else {
        console.log('⚡ Source switch - maintaining current state');
      }
    }
    
    console.log('🎥 Player ready for:', selectedSource?.metadata?.title);
  };

  const handlePlayerError = (error: any) => {
    console.error('Player error:', error);
    setIsPlayerLoading(false);
    setPlayerError('Failed to load video');
  };

  const selectedSource = sources.find(s => s.id === selectedSourceId);
  
  // Filter quotes based on selected source (unless showing all quotes)
  const filteredQuotes = showAllQuotes 
    ? quotes 
    : (selectedSourceId ? quotes.filter(quote => quote.sourceId === selectedSourceId) : quotes);
    
  // Get the filtered source name for display
  const filteredSourceName = showAllQuotes 
    ? null
    : (selectedSourceId ? sources.find(s => s.id === selectedSourceId)?.metadata?.title || 'Unknown Source' : null);

  // Update speakers for a specific source
  const updateSourceSpeakers = (sourceId: string, speakers: {[key: string]: string}) => {
    setSources(prev => prev.map(source => 
      source.id === sourceId 
        ? { ...source, speakers } 
        : source
    ));
  };

  // Update transcript for a specific source (for Gemini reprocessing)
  const updateSourceTranscript = (sourceId: string, transcript: TranscriptionResult) => {
    setSources(prev => prev.map(source => 
      source.id === sourceId 
        ? { ...source, transcript, speakers: transcript.speakers || source.speakers } 
        : source
    ));
  };

  const handleAddSource = async (url: string, audioFile?: ArrayBuffer) => {
    if (!apiKey) {
      toast({
        title: "API Key Required",
        description: "Please add your OpenAI API key in settings",
        variant: "destructive",
      });
      return;
    }

    const newSource: Source = {
      id: `source-${Date.now()}`,
      url,
      status: 'scraping',
      progress: 0,
    };

    setSources(prev => [...prev, newSource]);

    try {
      // Scrape metadata
      const metadata = await api.scrapeMetadata(url);
      
      setSources(prev => prev.map(s => 
        s.id === newSource.id 
          ? { ...s, metadata, status: 'transcribing', progress: 50 } 
          : s
      ));

      let transcript;
      
      // Try different transcription methods based on environment and availability
      if (audioFile) {
        // Use uploaded file
        const audioBase64 = btoa(String.fromCharCode(...new Uint8Array(audioFile)));
        transcript = await api.transcribeFile({ 
          audioFile: audioBase64,
          apiKey, 
          geminiApiKey: geminiApiKey?.trim() || undefined, 
          geminiPrompt: geminiPrompt?.trim() || undefined 
        });
      } else {
        // Try URL-based transcription first
        try {
          transcript = await api.transcribeAudio({ 
            url, 
            apiKey, 
            geminiApiKey: geminiApiKey?.trim() || undefined, 
            geminiPrompt: geminiPrompt?.trim() || undefined 
          });
        } catch (urlError) {
          // If URL method fails, ask for file upload
          setSources(prev => prev.map(s => 
            s.id === newSource.id 
              ? { ...s, status: 'error', error: 'Please upload audio file manually' } 
              : s
          ));
          
          toast({
            title: "Audio extraction failed",
            description: "Please try uploading the audio file directly",
            variant: "destructive",
          });
          return;
        }
      }
      
      const cleanedTranscript = {
        ...transcript,
        words: cleanTranscript(transcript.words)
      };

      // If Gemini provided speakers, use them
      if (transcript.speakers && Object.keys(transcript.speakers).length > 0) {
        setSources(prev => prev.map(s => 
          s.id === newSource.id 
            ? { ...s, speakers: transcript.speakers } 
            : s
        ));
      }

      setSources(prev => prev.map(s => 
        s.id === newSource.id 
          ? { ...s, transcript: cleanedTranscript, status: 'ready', progress: 100 } 
          : s
      ));

      // Auto-select if first source
      if (sources.length === 0) {
        setSelectedSourceId(newSource.id);
      }

      toast({
        title: "Source added successfully",
        description: metadata.title,
      });

    } catch (error) {
      setSources(prev => prev.map(s => 
        s.id === newSource.id 
          ? { ...s, status: 'error', error: error.message } 
          : s
      ));
      
      toast({
        title: "Error processing source",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  const handleRemoveSource = (id: string) => {
    setSources(prev => prev.filter(s => s.id !== id));
    if (selectedSourceId === id) {
      setSelectedSourceId(null);
    }
  };

  const handleExtractQuote = (startTime: number, endTime: number) => {
    if (!selectedSource?.transcript || !selectedSource.metadata) return;
    
    try {
      const quote = createQuote(
        selectedSource.transcript.words,
        { start: startTime, end: endTime },
        selectedSource.url,
        selectedSource.metadata,
        selectedSource.speakers || {},
        selectedSource.id
      );
      
      setQuotes(prev => [...prev, quote]);
      
      toast({
        title: "Quote extracted",
        description: "Quote added to your collection",
      });
    } catch (error) {
      toast({
        title: "Error extracting quote",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  const handleCopyQuotes = async () => {
    const quotesToCopy = quotes.filter(q => selectedQuotes.has(q.id));
    if (quotesToCopy.length === 0) {
      toast({
        title: "No quotes selected",
        description: "Select quotes to copy",
        variant: "destructive",
      });
      return;
    }
    
    try {
      // Create both HTML and plain text versions
      const htmlContent = quotesToCopy.map(quote => {
        const speaker = quote.speaker;
        const citationMatch = quote.citation.match(/\((.+)\)/);
        const date = citationMatch ? citationMatch[1] : 'Unknown Date';
        
        // Keep curvy quotes for better typography
        return `${quote.text} <a href="${quote.deepLink}">${speaker} (${date})</a>`;
      }).join('<br><br>');
      
      const plainContent = formatQuotesForClipboard(quotesToCopy);
      
      // Try to write rich text (HTML) to clipboard
      if (navigator.clipboard && navigator.clipboard.write) {
        const clipboardItems = [
          new ClipboardItem({
            'text/html': new Blob([htmlContent], { type: 'text/html' }),
            'text/plain': new Blob([plainContent], { type: 'text/plain' })
          })
        ];
        
        await navigator.clipboard.write(clipboardItems);
      } else {
        // Fallback to plain text
        await navigator.clipboard.writeText(plainContent);
      }
      
      toast({
        title: "Quotes copied",
        description: `${quotesToCopy.length} quotes copied with clickable links`,
      });
    } catch (error) {
      // Fallback to simple text copy
      const formatted = formatQuotesForClipboard(quotesToCopy);
      navigator.clipboard.writeText(formatted);
      
      toast({
        title: "Quotes copied",
        description: `${quotesToCopy.length} quotes copied to clipboard`,
      });
    }
  };

  const handleExportQuotes = () => {
    const quotesToExport = quotes.filter(q => selectedQuotes.has(q.id));
    if (quotesToExport.length === 0) {
      toast({
        title: "No quotes selected",
        description: "Select quotes to export",
        variant: "destructive",
      });
      return;
    }
    
    // TODO: Implement Google Docs export
    toast({
      title: "Export coming soon",
      description: "Google Docs integration in development",
    });
  };

  const handleClearAllData = async () => {
    if (confirm('Are you sure you want to delete all sources and quotes? This cannot be undone.')) {
      setSources([]);
      setQuotes([]);
      setSelectedQuotes(new Set());
      setSelectedSourceId(null);
      
      // Save empty state
      await api.saveAppData({ sources: [], quotes: [], speakers: {} });
      
      toast({
        title: "All data cleared",
        description: "Sources and quotes have been deleted",
      });
    }
  };

  const toggleLeftSidebar = () => {
    setIsLeftSidebarCollapsed(!isLeftSidebarCollapsed);
  };

  const toggleRightSidebar = () => {
    setIsRightSidebarCollapsed(!isRightSidebarCollapsed);
  };

  // Enterprise pre-loading handler
  const handlePreloadSource = (sourceId: string) => {
    if (!preloadedSources.has(sourceId)) {
      console.log('🚀 Pre-loading source for instant switching:', sourceId);
      setPreloadedSources(prev => new Set([...prev, sourceId]));
      // Mark as ready for future instant switching
      setPlayerReadyState(prev => ({
        ...prev,
        [sourceId]: true
      }));
    }
  };

  // Dynamic grid layout based on sidebar states
  const getGridColumns = () => {
    const leftWidth = isLeftSidebarCollapsed ? '50px' : '280px';
    const rightWidth = isRightSidebarCollapsed ? '50px' : '420px';
    return `${leftWidth} minmax(0,1fr) ${rightWidth}`;
  };

  // Calculate video container height based on sidebar states
  const getVideoContainerHeight = () => {
    const bothSidebarsCollapsed = isLeftSidebarCollapsed && isRightSidebarCollapsed;
    const oneSidebarCollapsed = isLeftSidebarCollapsed || isRightSidebarCollapsed;
    
    if (bothSidebarsCollapsed) {
      // When both sidebars are collapsed, limit video height more aggressively
      return '40vh'; // 40% of viewport height
    } else if (oneSidebarCollapsed) {
      // When one sidebar is collapsed, use moderate height
      return '45vh'; // 45% of viewport height
    } else {
      // When both sidebars are expanded, use more flexible height
      return '50vh'; // 50% of viewport height
    }
  };

  return (
    <div className="h-screen bg-background">
      {/* Header */}
      <header className="border-b px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h1 className="text-xl font-bold">Quotify</h1>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setIsAddSourceOpen(true)}
          >
            <Plus className="h-4 w-4 mr-2" />
            Add Source
          </Button>
          
          {(sources.length > 0 || quotes.length > 0) && (
            <div className="text-xs text-muted-foreground bg-muted px-2 py-1 rounded">
              {sources.length} sources • {quotes.length} quotes saved
            </div>
          )}
        </div>
        
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setIsDark(!isDark)}
            title={isDark ? "Switch to light mode" : "Switch to dark mode"}
          >
            {isDark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
          </Button>
          
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setIsGeminiConfigOpen(true)}
            title="Configure Gemini AI"
          >
            <Settings className="h-4 w-4" />
          </Button>
          
          <Button
            variant="ghost"
            size="icon"
            onClick={handleClearAllData}
            title="Clear all data"
          >
            <Trash2 className="h-4 w-4" />
          </Button>
          
          <div className="flex items-center gap-1 text-xs text-muted-foreground">
            <Command className="h-3 w-3" />K
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main 
        className="h-[calc(100vh-57px)] grid overflow-hidden transition-all duration-300 ease-in-out"
        style={{ gridTemplateColumns: getGridColumns() }}
      >
        {/* Sources Column */}
        <aside className="border-r overflow-hidden flex flex-col">
          <div className="flex items-center justify-between p-4 border-b">
            <div className="flex items-center gap-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={toggleLeftSidebar}
                className="p-1 h-8 w-8"
                title={isLeftSidebarCollapsed ? "Expand sources sidebar" : "Collapse sources sidebar"}
              >
                {isLeftSidebarCollapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
              </Button>
              {!isLeftSidebarCollapsed && (
                <h2 className="text-sm font-semibold">Sources</h2>
              )}
            </div>
          </div>
          {!isLeftSidebarCollapsed && (
            <div className="flex-1 p-4 overflow-y-auto">
              <div className="space-y-3">
                <AnimatePresence>
                  {sources.map(source => (
                    <SourceCard
                      key={source.id}
                      source={source}
                      onRemove={handleRemoveSource}
                      onSelect={setSelectedSourceId}
                      isSelected={selectedSourceId === source.id}
                      onPreload={handlePreloadSource}
                    />
                  ))}
                </AnimatePresence>
              </div>
            </div>
          )}
        </aside>

        {/* Player & Transcript Column */}
        <div className="flex flex-col overflow-hidden">
          {selectedSource ? (
            <>
              {/* Video Container with Dynamic Height */}
              <div 
                className="bg-black rounded-lg overflow-hidden flex-shrink-0 video-container relative"
                style={{ 
                  height: getVideoContainerHeight(),
                  minHeight: '200px', // Minimum height to keep video usable
                  maxHeight: '60vh'   // Maximum height to prevent it from being too large
                }}
              >
                {/* Loading indicator */}
                {isPlayerLoading && (
                  <div className="absolute inset-0 bg-black/80 flex items-center justify-center z-10">
                    <div className="text-white text-center">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white mx-auto mb-2"></div>
                      <div className="text-sm">Loading video...</div>
                      <div className="text-xs text-gray-300 mt-1">
                        {selectedSource.metadata?.title}
                      </div>
                    </div>
                  </div>
                )}

                {/* Error state */}
                {playerError && (
                  <div className="absolute inset-0 bg-black/80 flex items-center justify-center z-10">
                    <div className="text-white text-center">
                      <div className="text-red-400 mb-2">⚠️</div>
                      <div className="text-sm">Failed to load video</div>
                      <div className="text-xs text-gray-300 mt-1">{playerError}</div>
                    </div>
                  </div>
                )}

                <ReactPlayer
                  ref={playerRef}
                  url={selectedSource.url}
                  width="100%"
                  height="100%"
                  controls
                  playing={false}
                  config={{
                    youtube: {
                      playerVars: {
                        controls: 1,
                        modestbranding: 1,
                        rel: 0,
                        iv_load_policy: 3,
                        disablekb: 0,
                        playsinline: 1,
                        enablejsapi: 1,
                        origin: window.location.origin,
                        // Performance optimizations for faster loading
                        html5: 1,
                        hd: 0, // Force lower quality for faster loading
                        vq: 'medium', // Medium quality for better seeking performance
                        autoplay: 0,
                        start: 0,
                        // Additional loading optimizations
                        fs: 1, // Enable fullscreen
                        cc_load_policy: 0, // Don't show captions by default
                        showinfo: 0,
                        ecver: 2, // Use newer embed version
                        hl: 'en' // Language hint for faster loading
                      },
                      // Preload options for better seeking
                      preload: true,
                      // Use light version for faster initial load
                      embedOptions: {
                        host: 'https://www.youtube-nocookie.com'
                      }
                    }
                  }}
                  onReady={handlePlayerReady}
                  onError={handlePlayerError}
                />
              </div>
              
              {/* Transcript Container - ENTERPRISE INSTANT RENDERING */}
              <div className="flex-1 overflow-hidden mt-4 transcript-container">
                {/* ALWAYS show transcript immediately - zero dependencies on video state */}
                <TranscriptPane
                  transcript={selectedSource.transcript}
                  playerRef={playerRef}
                  onExtractQuote={handleExtractQuote}
                  speakers={selectedSource.speakers || {}}
                  setSpeakers={(newSpeakers) => updateSourceSpeakers(selectedSource.id, newSpeakers)}
                  selectedSourceId={selectedSource.id}
                  onTranscriptUpdate={(newTranscript) => updateSourceTranscript(selectedSource.id, newTranscript)}
                  isPlayerLoading={false}
                />
              </div>
            </>
          ) : (
            <div className="flex-1 flex items-center justify-center text-muted-foreground">
              <p>Select a source to begin</p>
            </div>
          )}
        </div>

        {/* Quotes Column */}
        <aside className="border-l overflow-hidden flex flex-col">
          <div className="flex items-center justify-between p-4 border-b">
            <div className="flex items-center gap-2">
              {!isRightSidebarCollapsed && (
                <div className="flex-1">
                  <h2 className="text-sm font-semibold">
                    Quotes ({filteredQuotes.length}{filteredQuotes.length !== quotes.length ? ` of ${quotes.length}` : ''})
                  </h2>
                  {filteredSourceName && !showAllQuotes && (
                    <p className="text-xs text-muted-foreground mt-1">
                      Filtered by: {filteredSourceName}
                    </p>
                  )}
                </div>
              )}
              {!isRightSidebarCollapsed && (
                <div className="flex gap-2">
                  {selectedSourceId && (
                    <Button
                      variant={showAllQuotes ? "outline" : "default"}
                      size="sm"
                      onClick={() => setShowAllQuotes(!showAllQuotes)}
                      className="text-xs"
                    >
                      {showAllQuotes ? "Current Source" : "All Quotes"}
                    </Button>
                  )}
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={handleCopyQuotes}
                    disabled={selectedQuotes.size === 0}
                  >
                    <Copy className="h-4 w-4" />
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={handleExportQuotes}
                    disabled={selectedQuotes.size === 0}
                  >
                    <Download className="h-4 w-4" />
                  </Button>
                </div>
              )}
              <Button
                variant="ghost"
                size="sm"
                onClick={toggleRightSidebar}
                className="p-1 h-8 w-8"
                title={isRightSidebarCollapsed ? "Expand quotes sidebar" : "Collapse quotes sidebar"}
              >
                {isRightSidebarCollapsed ? <ChevronLeft className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
              </Button>
            </div>
          </div>
          
          {!isRightSidebarCollapsed && (
            <div className="flex-1 p-4 overflow-y-auto">
              <QuoteList
                quotes={filteredQuotes}
                selectedQuotes={selectedQuotes}
                onSelectQuote={(id) => {
                  setSelectedQuotes(prev => {
                    const next = new Set(prev);
                    if (next.has(id)) {
                      next.delete(id);
                    } else {
                      next.add(id);
                    }
                    return next;
                  });
                }}
                onDeleteQuote={(id) => {
                  setQuotes(prev => prev.filter(q => q.id !== id));
                  setSelectedQuotes(prev => {
                    const next = new Set(prev);
                    next.delete(id);
                    return next;
                  });
                }}
                onReorderQuotes={(newQuotes) => {
                  // Only update the order if we're not filtering
                  if (!selectedSourceId || showAllQuotes) {
                    setQuotes(newQuotes);
                  }
                }}
              />
            </div>
          )}
        </aside>
      </main>

      {/* Dialogs */}
      <AddSourceDialog
        open={isAddSourceOpen}
        onOpenChange={setIsAddSourceOpen}
        onAddSource={handleAddSource}
        apiKey={apiKey}
        onApiKeyChange={async (key) => {
          setApiKey(key);
          if (key) {
            await api.saveApiKey(key);
          }
        }}
      />

      <GeminiConfigDialog
        open={isGeminiConfigOpen}
        onOpenChange={setIsGeminiConfigOpen}
        apiKey={geminiApiKey}
        prompt={geminiPrompt}
        onConfigChange={async (config) => {
          setGeminiApiKey(config.apiKey);
          setGeminiPrompt(config.prompt);
        }}
      />

      <Toaster />
    </div>
  );
}

export default App;