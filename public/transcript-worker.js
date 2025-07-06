// Web Worker for processing large transcripts without blocking UI
self.onmessage = function(e) {
  const { type, data } = e.data;
  
  if (type === 'PROCESS_TRANSCRIPT') {
    const { words, speakers } = data;
    
    try {
      console.log('🔄 Worker processing transcript with', words.length, 'words');
      
      // Get stable speaker mapping
      const getStableSpeakerMapping = (words) => {
        const uniqueSpeakerNames = [...new Set(words.map(w => w.speaker).filter(Boolean))];
        const mapping = {};
        
        uniqueSpeakerNames.forEach((name, index) => {
          // Check if this speaker name already has an ID in the saved speakers
          let existingId = null;
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
      
      const speakerMapping = getStableSpeakerMapping(words);
      
      const segments = [];
      let currentSegment = {
        speakerId: speakerMapping[words[0].speaker] || 'speaker_0',
        words: [words[0]],
        startTime: words[0].start,
        endTime: words[0].end
      };
      
      for (let i = 1; i < words.length; i++) {
        const word = words[i];
        const currentSpeakerName = word.speaker;
        const prevSpeakerName = words[i - 1].speaker;
        
        // If speaker changed, start new segment
        if (currentSpeakerName !== prevSpeakerName) {
          segments.push(currentSegment);
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
      
      segments.push(currentSegment);
      
      console.log('✅ Worker completed processing', segments.length, 'segments');
      
      // Send result back to main thread
      self.postMessage({
        type: 'TRANSCRIPT_PROCESSED',
        data: { segments }
      });
      
    } catch (error) {
      console.error('❌ Worker error:', error);
      self.postMessage({
        type: 'TRANSCRIPT_ERROR',
        data: { error: error.message }
      });
    }
  }
};