import React, { useRef, useEffect, useState, useCallback, useMemo } from 'react';
import { Word, TranscriptionResult } from '@/types';

interface CanvasTranscriptProps {
  transcript: TranscriptionResult;
  speakers: {[key: string]: string};
  currentTime: number;
  onWordClick: (word: Word) => void;
  onTextSelection: (startTime: number, endTime: number, text: string) => void;
  className?: string;
}

interface RenderedWord {
  word: Word;
  x: number;
  y: number;
  width: number;
  height: number;
  speakerId: string;
  segmentIndex: number;
}

interface SegmentLayout {
  speakerId: string;
  speakerName: string;
  startY: number;
  endY: number;
  words: RenderedWord[];
  startTime: number;
  endTime: number;
}

export function CanvasTranscript({ 
  transcript, 
  speakers, 
  currentTime, 
  onWordClick, 
  onTextSelection,
  className = ''
}: CanvasTranscriptProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [canvasSize, setCanvasSize] = useState({ width: 800, height: 600 });
  const [scrollY, setScrollY] = useState(0);
  const [hoveredWord, setHoveredWord] = useState<RenderedWord | null>(null);
  const [selectedRange, setSelectedRange] = useState<{ start: RenderedWord; end: RenderedWord } | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  
  // Canvas configuration
  const config = {
    padding: 20,
    lineHeight: 24,
    wordSpacing: 8,
    segmentSpacing: 40,
    speakerHeaderHeight: 30,
    fontSize: 14,
    fontFamily: 'system-ui, -apple-system, sans-serif',
    colors: {
      background: '#ffffff',
      text: '#1f2937',
      speaker: '#3b82f6',
      currentWord: '#fbbf24',
      hoveredWord: '#e5e7eb',
      selectedWord: '#bfdbfe',
      segmentBorder: '#d1d5db'
    }
  };

  // Compute segments with stable speaker mapping
  const segments = useMemo(() => {
    if (!transcript?.words?.length) return [];

    console.log('🎨 Computing canvas layout for', transcript.words.length, 'words');
    
    const getStableSpeakerMapping = (words: Word[]) => {
      const uniqueSpeakerNames = [...new Set(words.map(w => w.speaker).filter(Boolean))];
      const mapping: {[name: string]: string} = {};
      
      uniqueSpeakerNames.forEach((name, index) => {
        let existingId = null;
        for (const [id, savedName] of Object.entries(speakers)) {
          if (savedName === name) {
            existingId = id;
            break;
          }
        }
        mapping[name] = existingId || `speaker_${index}`;
      });
      
      return mapping;
    };

    const speakerMapping = getStableSpeakerMapping(transcript.words);
    const segments: SegmentLayout[] = [];
    
    let currentSegment = {
      speakerId: speakerMapping[transcript.words[0].speaker] || 'speaker_0',
      words: [transcript.words[0]],
      startTime: transcript.words[0].start,
      endTime: transcript.words[0].end
    };
    
    for (let i = 1; i < transcript.words.length; i++) {
      const word = transcript.words[i];
      const currentSpeakerName = word.speaker;
      const prevSpeakerName = transcript.words[i - 1].speaker;
      
      if (currentSpeakerName !== prevSpeakerName) {
        segments.push({
          speakerId: currentSegment.speakerId,
          speakerName: speakers[currentSegment.speakerId] || `Speaker ${parseInt(currentSegment.speakerId.split('_')[1]) + 1}`,
          startY: 0, // Will be calculated during layout
          endY: 0,
          words: [],
          startTime: currentSegment.startTime,
          endTime: currentSegment.endTime
        });
        
        currentSegment = {
          speakerId: speakerMapping[currentSpeakerName] || `speaker_${Object.keys(speakerMapping).indexOf(currentSpeakerName)}`,
          words: [word],
          startTime: word.start,
          endTime: word.end
        };
      } else {
        currentSegment.words.push(word);
        currentSegment.endTime = word.end;
      }
    }
    
    // Add final segment
    segments.push({
      speakerId: currentSegment.speakerId,
      speakerName: speakers[currentSegment.speakerId] || `Speaker ${parseInt(currentSegment.speakerId.split('_')[1]) + 1}`,
      startY: 0,
      endY: 0,
      words: [],
      startTime: currentSegment.startTime,
      endTime: currentSegment.endTime
    });
    
    console.log('✅ Computed', segments.length, 'segments for canvas');
    return segments;
  }, [transcript?.words, speakers]);

  // Layout calculation
  const layoutWords = useCallback((ctx: CanvasRenderingContext2D, segments: SegmentLayout[], canvasWidth: number) => {
    let currentY = config.padding;
    const renderedWords: RenderedWord[] = [];
    
    ctx.font = `${config.fontSize}px ${config.fontFamily}`;
    
    for (let segmentIndex = 0; segmentIndex < segments.length; segmentIndex++) {
      const segment = segments[segmentIndex];
      segment.startY = currentY;
      
      // Speaker header
      currentY += config.speakerHeaderHeight;
      
      // Layout words for this segment
      let x = config.padding;
      let lineY = currentY;
      const maxWidth = canvasWidth - (config.padding * 2);
      
      for (const word of segment.words) {
        const wordWidth = ctx.measureText(word.text).width;
        const wordWithSpace = wordWidth + config.wordSpacing;
        
        // Wrap to next line if needed
        if (x + wordWidth > maxWidth && x > config.padding) {
          x = config.padding;
          lineY += config.lineHeight;
        }
        
        const renderedWord: RenderedWord = {
          word,
          x,
          y: lineY,
          width: wordWidth,
          height: config.fontSize,
          speakerId: segment.speakerId,
          segmentIndex
        };
        
        renderedWords.push(renderedWord);
        segment.words.push(renderedWord);
        
        x += wordWithSpace;
      }
      
      currentY = lineY + config.lineHeight + config.segmentSpacing;
      segment.endY = currentY;
    }
    
    return { renderedWords, totalHeight: currentY };
  }, [config]);

  // Canvas rendering
  const renderCanvas = useCallback(() => {
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext('2d');
    if (!canvas || !ctx || segments.length === 0) return;

    // Set canvas size
    canvas.width = canvasSize.width * window.devicePixelRatio;
    canvas.height = canvasSize.height * window.devicePixelRatio;
    ctx.scale(window.devicePixelRatio, window.devicePixelRatio);
    
    canvas.style.width = `${canvasSize.width}px`;
    canvas.style.height = `${canvasSize.height}px`;

    // Clear canvas
    ctx.fillStyle = config.colors.background;
    ctx.fillRect(0, 0, canvasSize.width, canvasSize.height);

    // Calculate layout
    const { renderedWords, totalHeight } = layoutWords(ctx, segments, canvasSize.width);

    // Render segments
    ctx.save();
    ctx.translate(0, -scrollY);

    for (const segment of segments) {
      // Speaker header
      ctx.fillStyle = config.colors.speaker;
      ctx.font = `bold ${config.fontSize}px ${config.fontFamily}`;
      ctx.fillText(
        `${segment.speakerName} (${segment.startTime.toFixed(1)}s - ${segment.endTime.toFixed(1)}s)`,
        config.padding,
        segment.startY + config.speakerHeaderHeight - 8
      );

      // Segment border
      ctx.strokeStyle = config.colors.segmentBorder;
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(config.padding - 10, segment.startY);
      ctx.lineTo(config.padding - 10, segment.endY - config.segmentSpacing);
      ctx.stroke();
    }

    // Render words
    ctx.font = `${config.fontSize}px ${config.fontFamily}`;
    
    for (const renderedWord of renderedWords) {
      const { word, x, y, width, height } = renderedWord;
      
      // Word background
      let bgColor = null;
      
      // Current playing word
      if (currentTime >= word.start - 0.1 && currentTime <= word.end + 0.1) {
        bgColor = config.colors.currentWord;
      }
      // Hovered word
      else if (hoveredWord && hoveredWord.word === word) {
        bgColor = config.colors.hoveredWord;
      }
      // Selected range
      else if (selectedRange && 
               word.start >= selectedRange.start.word.start && 
               word.end <= selectedRange.end.word.end) {
        bgColor = config.colors.selectedWord;
      }
      
      if (bgColor) {
        ctx.fillStyle = bgColor;
        ctx.fillRect(x - 2, y - height + 2, width + 4, height + 4);
      }
      
      // Word text
      ctx.fillStyle = config.colors.text;
      ctx.fillText(word.text, x, y);
    }

    ctx.restore();

    // Store rendered words for hit testing
    (canvas as any)._renderedWords = renderedWords;
    (canvas as any)._totalHeight = totalHeight;
  }, [segments, canvasSize, scrollY, currentTime, hoveredWord, selectedRange, config, layoutWords]);

  // Handle canvas interactions
  const handleCanvasMouseMove = useCallback((e: React.MouseEvent) => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top + scrollY;

    const renderedWords = (canvas as any)._renderedWords as RenderedWord[];
    if (!renderedWords) return;

    // Hit test
    const hitWord = renderedWords.find(rw => 
      x >= rw.x && x <= rw.x + rw.width &&
      y >= rw.y - rw.height && y <= rw.y
    );

    setHoveredWord(hitWord || null);
    canvas.style.cursor = hitWord ? 'pointer' : 'default';
  }, [scrollY]);

  const handleCanvasClick = useCallback((e: React.MouseEvent) => {
    if (hoveredWord && !isDragging) {
      onWordClick(hoveredWord.word);
    }
  }, [hoveredWord, isDragging, onWordClick]);

  // Handle text selection
  const handleCanvasMouseDown = useCallback((e: React.MouseEvent) => {
    if (hoveredWord) {
      setSelectedRange({ start: hoveredWord, end: hoveredWord });
      setIsDragging(true);
    }
  }, [hoveredWord]);

  const handleCanvasMouseUp = useCallback(() => {
    if (selectedRange && isDragging) {
      const selectedText = segments
        .flatMap(s => s.words)
        .filter(w => w.word.start >= selectedRange.start.word.start && w.word.end <= selectedRange.end.word.end)
        .map(w => w.word.text)
        .join(' ');
      
      if (selectedText.trim()) {
        onTextSelection(selectedRange.start.word.start, selectedRange.end.word.end, selectedText);
      }
    }
    setIsDragging(false);
  }, [selectedRange, isDragging, segments, onTextSelection]);

  // Handle scrolling
  const handleScroll = useCallback((e: React.WheelEvent) => {
    e.preventDefault();
    const canvas = canvasRef.current;
    if (!canvas) return;

    const totalHeight = (canvas as any)._totalHeight || 0;
    const maxScroll = Math.max(0, totalHeight - canvasSize.height);
    
    setScrollY(prev => Math.max(0, Math.min(maxScroll, prev + e.deltaY)));
  }, [canvasSize.height]);

  // Resize handling
  useEffect(() => {
    const handleResize = () => {
      if (containerRef.current) {
        const { width, height } = containerRef.current.getBoundingClientRect();
        setCanvasSize({ width, height });
      }
    };

    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  // Render when dependencies change
  useEffect(() => {
    renderCanvas();
  }, [renderCanvas]);

  return (
    <div ref={containerRef} className={`w-full h-full ${className}`}>
      <canvas
        ref={canvasRef}
        onMouseMove={handleCanvasMouseMove}
        onClick={handleCanvasClick}
        onMouseDown={handleCanvasMouseDown}
        onMouseUp={handleCanvasMouseUp}
        onWheel={handleScroll}
        className="w-full h-full"
      />
    </div>
  );
}