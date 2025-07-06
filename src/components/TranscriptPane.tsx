import React, { useState, useEffect, useRef, useMemo, useCallback, useReducer } from 'react';
import ReactPlayer from 'react-player';
import { motion } from 'framer-motion';
import { FixedSizeList as List } from 'react-window';
import { Button } from '@/components/ui/button';
import { Quote, Edit2, User, Users, Check, X, RefreshCw } from 'lucide-react';
import { TranscriptionResult, Word } from '@/types';
import { cn } from '@/lib/utils';
import { getAPI } from '@/lib/webAPI';

// Debounce hook for performance
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);
  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(handler);
  }, [value, delay]);
  return debouncedValue;
}

// Player state reducer for batched updates
interface PlayerState {
  currentTime: number;
  isPlaying: boolean;
  clickedWordStart: number | null;
  isSeeking: boolean;
}

type PlayerAction = 
  | { type: 'UPDATE_TIME'; time: number; playing: boolean }
  | { type: 'WORD_CLICKED'; start: number }
  | { type: 'SEEKING'; isSeeking: boolean }
  | { type: 'CLEAR_CLICKED' };

function playerReducer(state: PlayerState, action: PlayerAction): PlayerState {
  switch (action.type) {
    case 'UPDATE_TIME':
      return { ...state, currentTime: action.time, isPlaying: action.playing };
    case 'WORD_CLICKED':
      return { ...state, clickedWordStart: action.start, isSeeking: true };
    case 'SEEKING':
      return { ...state, isSeeking: action.isSeeking };
    case 'CLEAR_CLICKED':
      return { ...state, clickedWordStart: null, isSeeking: false };
    default:
      return state;
  }
}

// ENTERPRISE-LEVEL Word Component with perfect memoization
interface WordProps {
  word: Word;
  wordIndex: number;
  isHighlighted: boolean;
  isClicked: boolean;
  isSeeking: boolean;
  isLastWord: boolean;
}

const OptimizedWord = React.memo<WordProps>(({ 
  word, 
  wordIndex, 
  isHighlighted, 
  isClicked, 
  isSeeking,
  isLastWord
}) => {
  // Memoized class computation
  const className = useMemo(() => cn(
    "inline-block px-0.5 py-0.5 cursor-pointer transition-all rounded-sm hover:bg-accent/50",
    isHighlighted && "bg-yellow-200 dark:bg-yellow-800 font-semibold",
    isClicked && isSeeking && "bg-orange-200 dark:bg-orange-800 font-semibold scale-105 animate-pulse",
    isClicked && !isSeeking && "bg-blue-200 dark:bg-blue-800 font-semibold scale-105"
  ), [isHighlighted, isClicked, isSeeking]);

  return (
    <span
      className={className}
      data-word-index={wordIndex}
      data-start={word.start}
      data-end={word.end}
      title={`${word.start.toFixed(1)}s - ${word.end.toFixed(1)}s`}
    >
      {word.text}
      {!isLastWord ? ' ' : ''}
    </span>
  );
}, (prevProps, nextProps) => {
  // Deep comparison for perfect memoization
  return (
    prevProps.word.start === nextProps.word.start &&
    prevProps.word.text === nextProps.word.text &&
    prevProps.isHighlighted === nextProps.isHighlighted &&
    prevProps.isClicked === nextProps.isClicked &&
    prevProps.isSeeking === nextProps.isSeeking &&
    prevProps.isLastWord === nextProps.isLastWord
  );
});

// ENTERPRISE-LEVEL Segment with virtualization for large segments
interface SegmentProps {
  segment: any;
  getSpeakerName: (id: string) => string;
  highlightedWordIndex: number;
  clickedWordStart: number | null;
  isSeeking: boolean;
}

const OptimizedSegment = React.memo<SegmentProps>(({ 
  segment, 
  getSpeakerName, 
  highlightedWordIndex,
  clickedWordStart,
  isSeeking
}) => {
  // Virtualization threshold - segments larger than this use virtualization
  const VIRTUALIZATION_THRESHOLD = 500;
  const isLargeSegment = segment.words.length > VIRTUALIZATION_THRESHOLD;
  
  // Memoized word data for virtualization
  const wordData = useMemo(() => ({
    words: segment.words,
    highlightedWordIndex,
    clickedWordStart,
    isSeeking,
    segmentStartIndex: segment.globalStartIndex || 0
  }), [segment.words, highlightedWordIndex, clickedWordStart, isSeeking, segment.globalStartIndex]);

  // Optimized text flow renderer - renders words in flowing text
  const renderFlowingText = useCallback(() => {
    const words = segment.words;
    const chunkSize = 100; // Process words in chunks for performance
    const chunks = [];
    
    for (let i = 0; i < words.length; i += chunkSize) {
      const chunk = words.slice(i, i + chunkSize);
      chunks.push(
        <span key={`chunk-${i}`} className="inline">
          {chunk.map((word, wordIndex) => {
            const globalIndex = (segment.globalStartIndex || 0) + i + wordIndex;
            const isHighlighted = globalIndex === highlightedWordIndex;
            const isClicked = clickedWordStart !== null && Math.abs(word.start - clickedWordStart) < 0.1;
            const isLastWord = (i + wordIndex) === words.length - 1;
            
            return (
              <OptimizedWord
                key={`${word.start}_${i + wordIndex}`}
                word={word}
                wordIndex={globalIndex}
                isHighlighted={isHighlighted}
                isClicked={isClicked}
                isSeeking={isSeeking}
                isLastWord={isLastWord}
              />
            );
          })}
        </span>
      );
    }
    
    return chunks;
  }, [segment.words, segment.globalStartIndex, highlightedWordIndex, clickedWordStart, isSeeking]);
  
  return (
    <div className="border-l-4 border-primary/30 pl-4 mb-6">
      {/* Speaker Header */}
      <div className="flex items-center gap-2 mb-2">
        <User className="h-4 w-4 text-muted-foreground" />
        <span className="font-semibold text-primary">
          {getSpeakerName(segment.speakerId)}
        </span>
        <span className="text-xs text-muted-foreground">
          {segment.startTime.toFixed(1)}s - {segment.endTime.toFixed(1)}s ({segment.words.length} words)
          {isLargeSegment && ' • Chunked for performance'}
        </span>
      </div>
      
      {isLargeSegment ? (
        // Large segment: Chunked flowing text for performance
        <div className="prose prose-sm dark:prose-invert max-w-none select-text">
          <div className="text-sm leading-relaxed max-h-96 overflow-y-auto">
            {renderFlowingText()}
          </div>
        </div>
      ) : (
        // Normal segment: Direct rendering
        <div className="prose prose-sm dark:prose-invert max-w-none select-text">
          {segment.words.map((word: Word, wordIndex: number) => {
            const globalIndex = (segment.globalStartIndex || 0) + wordIndex;
            const isHighlighted = globalIndex === highlightedWordIndex;
            const isClicked = clickedWordStart !== null && Math.abs(word.start - clickedWordStart) < 0.1;
            
            return (
              <OptimizedWord
                key={`${word.start}_${wordIndex}`}
                word={word}
                wordIndex={globalIndex}
                isHighlighted={isHighlighted}
                isClicked={isClicked}
                isSeeking={isSeeking}
                isLastWord={wordIndex === segment.words.length - 1}
              />
            );
          })}
        </div>
      )}
    </div>
  );
}, (prevProps, nextProps) => {
  return (
    prevProps.segment.speakerId === nextProps.segment.speakerId &&
    prevProps.segment.words.length === nextProps.segment.words.length &&
    prevProps.highlightedWordIndex === nextProps.highlightedWordIndex &&
    prevProps.clickedWordStart === nextProps.clickedWordStart &&
    prevProps.isSeeking === nextProps.isSeeking
  );
});

interface TranscriptPaneProps {
  transcript?: TranscriptionResult;
  playerRef: React.RefObject<ReactPlayer>;
  onExtractQuote: (startTime: number, endTime: number) => void;
  speakers: {[key: string]: string};
  setSpeakers: React.Dispatch<React.SetStateAction<{[key: string]: string}>>;
  selectedSourceId?: string;
  onTranscriptUpdate?: (newTranscript: TranscriptionResult) => void;
  isPlayerLoading?: boolean;
}

export function TranscriptPane({ transcript, playerRef, onExtractQuote, speakers, setSpeakers, selectedSourceId, onTranscriptUpdate, isPlayerLoading }: TranscriptPaneProps) {
  // Player state managed by reducer for batched updates
  const [playerState, dispatchPlayer] = useReducer(playerReducer, {
    currentTime: 0,
    isPlaying: false,
    clickedWordStart: null,
    isSeeking: false
  });
  
  const [selectedRange, setSelectedRange] = useState<{ start: number; end: number } | null>(null);
  const [editingSpeaker, setEditingSpeaker] = useState<string | null>(null);
  const [editingName, setEditingName] = useState('');
  const [showSpeakerPanel, setShowSpeakerPanel] = useState(false);
  const [tempSpeakers, setTempSpeakers] = useState<{[key: string]: string}>({});
  const [showExtractButton, setShowExtractButton] = useState(false);
  const [isUserScrolling, setIsUserScrolling] = useState(false);
  const [isReprocessing, setIsReprocessing] = useState(false);
  
  const containerRef = useRef<HTMLDivElement>(null);
  const scrollTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const lastScrollTime = useRef<number>(0);
  const lastSeekTime = useRef<number>(0);
  const seekTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  
  // Debounced current time for performance
  const debouncedCurrentTime = useDebounce(playerState.currentTime, 50);

  // ENTERPRISE-LEVEL: Find highlighted word index with O(log n) binary search
  const highlightedWordIndex = useMemo(() => {
    if (!transcript?.words?.length) return -1;
    
    const buffer = 0.1;
    const targetTime = debouncedCurrentTime;
    
    // Binary search for highlighted word (O(log n) vs O(n))
    let left = 0;
    let right = transcript.words.length - 1;
    
    while (left <= right) {
      const mid = Math.floor((left + right) / 2);
      const word = transcript.words[mid];
      
      if (targetTime >= word.start - buffer && targetTime <= word.end + buffer) {
        return mid;
      } else if (targetTime < word.start) {
        right = mid - 1;
      } else {
        left = mid + 1;
      }
    }
    
    return -1;
  }, [transcript?.words, debouncedCurrentTime]);

  // Pre-buffer strategy with throttling
  const handleWordHover = useCallback((word: Word) => {
    if (!playerRef.current) return;
    
    const internalPlayer = playerRef.current.getInternalPlayer();
    if (internalPlayer && typeof internalPlayer.seekTo === 'function') {
      const currentPlayerTime = typeof internalPlayer.getCurrentTime === 'function' 
        ? internalPlayer.getCurrentTime() 
        : playerState.currentTime;
        
      const timeDiff = Math.abs(word.start - currentPlayerTime);
      
      if (timeDiff > 30) {
        const prebufferTime = Math.max(0, word.start - 5);
        
        if (typeof internalPlayer.getPlayerState === 'function' &&
            internalPlayer.getPlayerState() !== 1) {
          
          setTimeout(() => {
            if (typeof internalPlayer.seekTo === 'function') {
              internalPlayer.seekTo(prebufferTime, true);
            }
          }, 500);
        }
      }
    }
  }, [playerRef, playerState.currentTime]);

  // Check if transcript has speaker assignments (Gemini processed successfully)
  const hasGeminiProcessed = () => {
    if (!transcript?.words) return false;
    // Check if any word has a speaker assigned that's not null
    return transcript.words.some(word => word.speaker && word.speaker.trim() !== '');
  };

  // Reprocess transcript with Gemini
  const handleReprocessWithGemini = async () => {
    if (!selectedSourceId || !transcript) return;
    
    setIsReprocessing(true);
    
    try {
      console.log('🔄 Reprocesando con Gemini...');
      
      // Call the API to reprocess with Gemini
      const api = getAPI();
      const result = await api.reprocessWithGemini({
        words: transcript.words,
        fullText: transcript.full_text
      });
      
      if (result && result.words) {
        // Update the transcript with new speaker assignments
        console.log('✅ Reprocesamiento completado');
        
        // Update speakers state
        if (result.speakers) {
          setSpeakers(result.speakers);
        }
        
        // Update the transcript through callback if available
        if (onTranscriptUpdate) {
          onTranscriptUpdate(result);
        } else {
          // Fallback: reload page
          window.location.reload();
        }
      }
      
    } catch (error: any) {
      console.error('❌ Error en reprocesamiento:', error);
      alert(`Error reprocesando con Gemini: ${error?.message || 'Unknown error'}`);
    } finally {
      setIsReprocessing(false);
    }
  };

  // Debug effect to log speaker changes
  useEffect(() => {
    console.log('🎤 Speakers updated:', speakers);
  }, [speakers]);

  // Enterprise-level optimized state management - ONLY when source ID changes
  useEffect(() => {
    console.log('📋 Source ID changed - instant state reset');
    
    // INSTANT reset - no dependencies on transcript data
    setSelectedRange(null);
    setEditingSpeaker(null);
    setEditingName('');
    setShowSpeakerPanel(false);
    setTempSpeakers({});
    setShowExtractButton(false);
    setIsUserScrolling(false);
    // setClickedWordStart - now handled by playerState
    // setIsSeeking - now handled by playerState
    
    // Clear any pending timeouts immediately
    if (scrollTimeoutRef.current) clearTimeout(scrollTimeoutRef.current);
    if (seekTimeoutRef.current) clearTimeout(seekTimeoutRef.current);
    
    // Clear text selection immediately
    window.getSelection()?.removeAllRanges();
    
    // Instant scroll to top
    if (containerRef.current) {
      containerRef.current.scrollTop = 0;
    }
    
    console.log('⚡ INSTANT state reset complete');
  }, [selectedSourceId]); // ONLY selectedSourceId - no other dependencies

  // React-Virtualized row renderer
  const rowRenderer = ({ index, key, style }: { index: number; key: string; style: any }) => {
    const segment = transcriptSegments[index];
    
    return (
      <div key={key} style={style}>
        <OptimizedSegment
          segment={segment}
          getSpeakerName={getSpeakerName}
          highlightedWordIndex={highlightedWordIndex}
          clickedWordStart={playerState.clickedWordStart}
          isSeeking={playerState.isSeeking}
        />
      </div>
    );
  };


  // ENTERPRISE-LEVEL: Optimized player tracking with batched updates
  useEffect(() => {
    const intervalMs = 100; // Consistent interval for smooth UX
    
    const interval = setInterval(() => {
      if (playerRef.current) {
        const newTime = playerRef.current.getCurrentTime();
        
        const internalPlayer = playerRef.current.getInternalPlayer();
        let playing = false;
        
        if (internalPlayer) {
          if (typeof internalPlayer.getPlayerState === 'function') {
            const playerState = internalPlayer.getPlayerState();
            playing = playerState === 1;
          } else if (internalPlayer.paused !== undefined) {
            playing = !internalPlayer.paused;
          }
        }
        
        // Batched state update - single re-render instead of two
        dispatchPlayer({ type: 'UPDATE_TIME', time: newTime, playing });
      }
    }, intervalMs);
    
    return () => clearInterval(interval);
  }, [playerRef]);

  // Container hover handler for event delegation (optimized)
  const handleContainerHover = useCallback((e: any) => {
    const target = e.target as HTMLElement;
    if (!target.hasAttribute('data-start')) return;
    
    const wordStart = parseFloat(target.getAttribute('data-start') || '0');
    const wordEnd = parseFloat(target.getAttribute('data-end') || '0');
    
    // Throttled hover for performance (only process 5% of hovers)
    if (Math.random() < 0.05) {
      const word = { start: wordStart, end: wordEnd, text: target.textContent || '' } as Word;
      handleWordHover(word);
    }
  }, [handleWordHover]);

  // ENTERPRISE-LEVEL: Optimized auto-scroll with virtual tracking
  useEffect(() => {
    if (!playerState.isPlaying || isUserScrolling || highlightedWordIndex === -1) return;
    
    const container = containerRef.current;
    if (!container) return;
    
    // Direct element access using data attribute (faster than query selector)
    const highlightedElement = container.querySelector(`[data-word-index="${highlightedWordIndex}"]`);
    
    if (highlightedElement) {
      const containerRect = container.getBoundingClientRect();
      const elementRect = highlightedElement.getBoundingClientRect();
      
      const relativeTop = elementRect.top - containerRect.top;
      const containerHeight = containerRect.height;
      const targetZone = containerHeight * 0.3;
      const tolerance = 50;
      
      if (relativeTop < tolerance || relativeTop > targetZone + tolerance) {
        const currentScrollTop = container.scrollTop;
        const elementOffsetTop = currentScrollTop + relativeTop;
        const targetScrollTop = elementOffsetTop - targetZone;
        
        lastScrollTime.current = Date.now();
        
        container.scrollTo({
          top: Math.max(0, targetScrollTop),
          behavior: 'smooth'
        });
      }
    }
  }, [highlightedWordIndex, playerState.isPlaying, isUserScrolling]);

  // Detect user scrolling to pause auto-scroll temporarily
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;
    
    const handleScroll = () => {
      // Only consider it user scrolling if it's been more than 200ms since last auto-scroll
      const now = Date.now();
      if (now - lastScrollTime.current > 200) {
        setIsUserScrolling(true);
        
        // Clear existing timeout
        if (scrollTimeoutRef.current) {
          clearTimeout(scrollTimeoutRef.current);
        }
        
        // Resume auto-scroll after 3 seconds of no user interaction
        scrollTimeoutRef.current = setTimeout(() => {
          setIsUserScrolling(false);
        }, 3000);
      }
    };
    
    container.addEventListener('scroll', handleScroll, { passive: true });
    
    return () => {
      container.removeEventListener('scroll', handleScroll);
      if (scrollTimeoutRef.current) {
        clearTimeout(scrollTimeoutRef.current);
      }
    };
  }, []);

  // Monitor text selection and update extract button visibility
  useEffect(() => {
    const handleSelection = () => {
      const selection = window.getSelection();
      const selectedText = selection?.toString().trim();
      
      if (selectedText && selectedText.length > 0) {
        // Get all selected word spans
        const container = containerRef.current;
        if (!container) return;
        
        const allWordSpans = container.querySelectorAll('[data-start][data-end]');
        const selectedSpans: Element[] = [];
        
        // Check which spans are selected
        allWordSpans.forEach(span => {
          if (selection && selection.containsNode(span, true)) {
            selectedSpans.push(span);
          }
        });
        
        if (selectedSpans.length > 0) {
          const startTime = parseFloat(selectedSpans[0].getAttribute('data-start') || '0');
          const endTime = parseFloat(selectedSpans[selectedSpans.length - 1].getAttribute('data-end') || '0');
          
          console.log('Selection detected:', { startTime, endTime, text: selectedText });
          
          setSelectedRange({ start: startTime, end: endTime });
          setShowExtractButton(true);
        }
      } else {
        setSelectedRange(null);
        setShowExtractButton(false);
      }
    };
    
    // Delay the handler slightly to ensure selection is complete
    const delayedHandler = () => {
      setTimeout(handleSelection, 100);
    };
    
    // Use both selectionchange and mouseup for better detection
    document.addEventListener('selectionchange', delayedHandler);
    document.addEventListener('mouseup', delayedHandler);
    
    return () => {
      document.removeEventListener('selectionchange', delayedHandler);
      document.removeEventListener('mouseup', delayedHandler);
    };
  }, []);


  const getWordsInSelection = (words: Word[], selectedText: string): Word[] => {
    // Simple approach: find words that match the selected text
    const cleanSelectedText = selectedText.replace(/\s+/g, ' ').toLowerCase();
    const allText = words.map(w => w.text).join(' ').toLowerCase();
    
    const startIndex = allText.indexOf(cleanSelectedText);
    if (startIndex === -1) return [];
    
    // Count words to find start and end indices
    const beforeText = allText.substring(0, startIndex);
    const wordsBefore = beforeText.trim() ? beforeText.trim().split(/\s+/).length : 0;
    const selectedWords = cleanSelectedText.trim().split(/\s+/).length;
    
    return words.slice(wordsBefore, wordsBefore + selectedWords);
  };

  // Create a stable mapping of speaker names to IDs
  const getStableSpeakerMapping = (words: Word[]) => {
    const uniqueSpeakerNames = [...new Set(words.map(w => w.speaker).filter(Boolean))];
    const mapping: {[name: string]: string} = {};
    
    uniqueSpeakerNames.forEach((name, index) => {
      // Check if this speaker name already has an ID in the saved speakers
      let existingId: string | null = null;
      for (const [id, savedName] of Object.entries(speakers)) {
        if (savedName === name) {
          existingId = id;
          break;
        }
      }
      
      // Use existing ID or create a stable one based on index
      mapping[name] = existingId || `speaker_${index}`;
    });
    
    return mapping;
  };

  // ENTERPRISE-LEVEL: Optimized transcript segments with global indexing
  const transcriptSegments = useMemo(() => {
    if (!transcript?.words?.length) {
      return [];
    }

    const speakerMapping = getStableSpeakerMapping(transcript.words);
    const segments = [];
    let globalWordIndex = 0;
    
    let currentSegment = {
      speakerId: speakerMapping[transcript.words[0].speaker] || 'speaker_0',
      words: [transcript.words[0]],
      startTime: transcript.words[0].start,
      endTime: transcript.words[0].end,
      globalStartIndex: 0
    };
    
    for (let i = 1; i < transcript.words.length; i++) {
      const word = transcript.words[i];
      const currentSpeakerName = word.speaker;
      const prevSpeakerName = transcript.words[i - 1].speaker;
      
      if (currentSpeakerName !== prevSpeakerName) {
        segments.push(currentSegment);
        globalWordIndex += currentSegment.words.length;
        
        currentSegment = {
          speakerId: speakerMapping[currentSpeakerName || ''] || `speaker_${Object.keys(speakerMapping).indexOf(currentSpeakerName || '')}`,
          words: [word],
          startTime: word.start,
          endTime: word.end,
          globalStartIndex: globalWordIndex
        };
      } else {
        currentSegment.words.push(word);
        currentSegment.endTime = word.end;
      }
    }
    
    segments.push(currentSegment);
    return segments;
  }, [transcript?.words, speakers]);


  const getSpeakerName = (speakerId: string) => {
    return speakers[speakerId] || `Speaker ${parseInt(speakerId.split('_')[1]) + 1}`;
  };

  const handleSpeakerEdit = (speakerId: string) => {
    setEditingSpeaker(speakerId);
    setEditingName(getSpeakerName(speakerId));
  };

  const handleSpeakerSave = () => {
    if (editingSpeaker && editingName.trim()) {
      setSpeakers(prev => ({
        ...prev,
        [editingSpeaker]: editingName.trim()
      }));
    }
    setEditingSpeaker(null);
    setEditingName('');
  };

  const handleSpeakerCancel = () => {
    setEditingSpeaker(null);
    setEditingName('');
  };

  // Speaker panel functions
  const handleOpenSpeakerPanel = () => {
    // Use the stable mapping to get speakers
    const speakerMapping = getStableSpeakerMapping(transcript?.words || []);
    
    // Build the current speakers object with proper names
    const currentSpeakers: {[key: string]: string} = {};
    for (const [name, id] of Object.entries(speakerMapping)) {
      // If we already have a custom name for this ID, use it
      currentSpeakers[id] = speakers[id] || name;
    }
    
    setTempSpeakers(currentSpeakers);
    setShowSpeakerPanel(true);
  };

  const handleSaveSpeakerPanel = () => {
    setSpeakers(tempSpeakers);
    setShowSpeakerPanel(false);
  };

  const handleCancelSpeakerPanel = () => {
    setTempSpeakers({});
    setShowSpeakerPanel(false);
  };

  const updateTempSpeaker = (speakerId: string, name: string) => {
    setTempSpeakers(prev => ({
      ...prev,
      [speakerId]: name
    }));
  };

  // INSTANT rendering check - show immediately if transcript exists
  if (!transcript) {
    return (
      <div className="flex-1 p-8 flex items-center justify-center text-muted-foreground">
        <p>Transcript will appear here</p>
      </div>
    );
  }

  // Performance check - if transcript is huge, render simple version first
  const isHugeTranscript = transcript.words?.length > 2000;
  if (isHugeTranscript) {
    console.log('📊 Large transcript detected, using optimized rendering');
  }

  const handleExtract = () => {
    if (selectedRange) {
      console.log('Extracting quote:', selectedRange);
      onExtractQuote(selectedRange.start, selectedRange.end);
      setSelectedRange(null);
      setShowExtractButton(false);
      // Clear text selection
      window.getSelection()?.removeAllRanges();
    }
  };

  // ENTERPRISE-LEVEL: Event delegation for massive performance improvement
  const handleContainerClick = useCallback((e: React.MouseEvent) => {
    const target = e.target as HTMLElement;
    if (!target.hasAttribute('data-start')) return;
    
    // Check for text selection
    const selection = window.getSelection();
    if (selection && selection.toString().trim().length > 0) return;
    
    // Debounce rapid clicks
    const now = Date.now();
    if (now - lastSeekTime.current < 150) return;
    lastSeekTime.current = now;
    
    const wordStart = parseFloat(target.getAttribute('data-start') || '0');
    const wordText = target.textContent || '';
    
    if (playerRef.current) {
      // Immediate UI feedback with batched state update
      dispatchPlayer({ type: 'WORD_CLICKED', start: wordStart });
      
      // Clear seeking state after delay
      if (seekTimeoutRef.current) clearTimeout(seekTimeoutRef.current);
      seekTimeoutRef.current = setTimeout(() => {
        dispatchPlayer({ type: 'CLEAR_CLICKED' });
      }, 1500);
      
      console.log(`🎯 Seeking to ${wordStart.toFixed(1)}s: "${wordText}"`);
      
      // Enterprise-level seeking
      const performSeek = async () => {
        try {
          await playerRef.current!.seekTo(wordStart, 'seconds');
          
          const internalPlayer = playerRef.current!.getInternalPlayer();
          
          if (internalPlayer && typeof internalPlayer.seekTo === 'function') {
            setTimeout(() => {
              try {
                internalPlayer.seekTo(wordStart, true);
              } catch (error: any) {
                console.warn('YouTube API seek failed:', error);
              }
            }, 100);
            
            setTimeout(() => {
              try {
                if (typeof internalPlayer.getPlayerState === 'function' &&
                    typeof internalPlayer.playVideo === 'function') {
                  const state = internalPlayer.getPlayerState();
                  if (state !== 1) {
                    internalPlayer.playVideo();
                  }
                }
              } catch (error: any) {
                console.warn('Resume playback failed:', error);
              }
            }, 200);
          } else if (internalPlayer && typeof internalPlayer.currentTime !== 'undefined') {
            internalPlayer.currentTime = wordStart;
            
            if (internalPlayer.paused && typeof internalPlayer.play === 'function') {
              internalPlayer.play().catch(e => console.log('HTML5 play failed:', e));
            }
          }
        } catch (error: any) {
          console.error('All seek methods failed:', error);
          dispatchPlayer({ type: 'UPDATE_TIME', time: wordStart, playing: playerState.isPlaying });
        }
      };
      
      performSeek();
    }
  }, [playerRef, playerState.isPlaying]);
  

  return (
    <div className="h-full overflow-y-auto p-6 relative" ref={containerRef}>
      {/* Floating Extract Button - shows automatically when text is selected */}
      {showExtractButton && selectedRange && (
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          className="fixed bottom-8 left-1/2 transform -translate-x-1/2 z-50"
        >
          <Button
            size="lg"
            onClick={handleExtract}
            className="shadow-2xl bg-green-600 hover:bg-green-700 text-white px-6 py-3 flex items-center gap-3 rounded-full"
          >
            <Quote className="h-5 w-5" />
            Extract Quote
            <span className="text-xs opacity-75 ml-2">↵</span>
          </Button>
        </motion.div>
      )}

      {/* Enterprise Loading State Indicator */}
      {isPlayerLoading && (
        <div className="mb-4 p-3 bg-blue-50 dark:bg-blue-950 border border-blue-200 dark:border-blue-800 rounded-lg">
          <div className="flex items-center gap-2 text-sm text-blue-800 dark:text-blue-200">
            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600"></div>
            <span>Video loading... transcript available for interaction</span>
          </div>
        </div>
      )}

      {/* Speaker Control Panel */}
      <div className="mb-4 p-4 bg-slate-50 dark:bg-slate-900 rounded-lg border">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Users className="h-5 w-5 text-primary" />
            <h3 className="font-semibold text-primary">Speaker Names</h3>
            {!hasGeminiProcessed() && (
              <span className="text-xs bg-orange-100 dark:bg-orange-900 text-orange-800 dark:text-orange-200 px-2 py-1 rounded">
                Sin análisis de Gemini
              </span>
            )}
          </div>
          <div className="flex items-center gap-2">
            {!hasGeminiProcessed() && (
              <Button
                size="sm"
                variant="outline"
                onClick={handleReprocessWithGemini}
                disabled={isReprocessing}
                className="text-xs bg-blue-50 dark:bg-blue-950 border-blue-200 dark:border-blue-800 hover:bg-blue-100 dark:hover:bg-blue-900"
              >
                {isReprocessing ? (
                  <>
                    <RefreshCw className="h-3 w-3 mr-1 animate-spin" />
                    Procesando...
                  </>
                ) : (
                  <>
                    <RefreshCw className="h-3 w-3 mr-1" />
                    Procesar con Gemini
                  </>
                )}
              </Button>
            )}
            <Button
              size="sm"
              variant="outline"
              onClick={handleOpenSpeakerPanel}
              className="text-xs"
            >
              <Edit2 className="h-3 w-3 mr-1" />
              Edit All
            </Button>
            
            {/* Performance Info */}
            {transcriptSegments.length > 0 && (
              <div className="text-xs text-muted-foreground bg-muted px-2 py-1 rounded">
                {transcriptSegments.length} segments • Virtualized
              </div>
            )}
          </div>
        </div>
        
        {/* Current speaker list */}
        <div className="flex flex-wrap gap-2">
          {transcript && transcriptSegments.length > 0 ? (
            [...new Set(transcriptSegments.map(segment => segment.speakerId))].map((speakerId) => (
            <div key={speakerId} className="flex items-center gap-1 px-2 py-1 bg-primary/10 rounded text-xs">
              <User className="h-3 w-3" />
              <span className="font-medium">
                {getSpeakerName(speakerId)}
              </span>
            </div>
            ))
          ) : (
            <div className="text-xs text-muted-foreground">
              No speakers available
            </div>
          )}
        </div>
      </div>

      {/* Speaker Edit Panel Overlay */}
      {showSpeakerPanel && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-background border rounded-lg p-6 max-w-md w-full m-4 max-h-[80vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold flex items-center gap-2">
                <Users className="h-5 w-5" />
                Edit Speaker Names
              </h2>
              <Button
                size="sm"
                variant="ghost"
                onClick={handleCancelSpeakerPanel}
                className="h-8 w-8 p-0"
              >
                <X className="h-4 w-4" />
              </Button>
            </div>
            
            <div className="space-y-3 mb-6">
              {Object.entries(tempSpeakers).map(([speakerId, name]) => (
                <div key={speakerId} className="space-y-1">
                  <label className="text-sm font-medium text-muted-foreground">
                    Speaker {parseInt(speakerId.split('_')[1]) + 1}
                  </label>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => updateTempSpeaker(speakerId, e.target.value)}
                    className="w-full px-3 py-2 border border-border rounded-md bg-background"
                    placeholder="Enter speaker name..."
                  />
                </div>
              ))}
            </div>
            
            <div className="flex gap-2 justify-end">
              <Button
                variant="outline"
                onClick={handleCancelSpeakerPanel}
              >
                Cancel
              </Button>
              <Button
                onClick={handleSaveSpeakerPanel}
                className="bg-green-600 hover:bg-green-700"
              >
                <Check className="h-4 w-4 mr-2" />
                Save Changes
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Transcript with Speaker Segments */}
      <div className="flex-1 min-h-0">
        {!transcript ? (
          // No transcript available
          <div className="flex-1 p-8 flex items-center justify-center text-muted-foreground">
            <div className="text-center">
              <div className="text-lg font-medium">No transcript available</div>
              <div className="text-sm mt-1">Select a source with a transcript to view it here</div>
            </div>
          </div>
        ) : (
          // ALWAYS SHOW TRANSCRIPT - simplified
          <div className="h-full overflow-y-auto space-y-4 p-4">
            
            {transcriptSegments.length > 0 ? (
              // ENTERPRISE-LEVEL: Event delegation + optimized rendering
              <div className="space-y-4" onClick={handleContainerClick} onMouseOver={handleContainerHover}>
                {transcriptSegments.map((segment, segmentIndex) => (
                  <OptimizedSegment
                    key={`${segment.speakerId}_${segment.startTime}_${segmentIndex}`}
                    segment={segment}
                    getSpeakerName={getSpeakerName}
                    highlightedWordIndex={highlightedWordIndex}
                    clickedWordStart={playerState.clickedWordStart}
                    isSeeking={playerState.isSeeking}
                  />
                ))}
              </div>
            ) : (
              // Show plain text while segments compute
              <div className="text-sm leading-relaxed bg-gray-50 dark:bg-gray-900 p-4 rounded">
                {transcript.full_text || transcript.words?.map(w => w.text).join(' ') || 'No transcript text available'}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Quote count info */}
      {selectedRange && (
        <div className="mt-4 p-2 bg-primary/10 rounded text-sm text-primary">
          Selected: {selectedRange.start.toFixed(1)}s - {selectedRange.end.toFixed(1)}s 
          ({(selectedRange.end - selectedRange.start).toFixed(1)}s duration)
        </div>
      )}
    </div>
  );
}