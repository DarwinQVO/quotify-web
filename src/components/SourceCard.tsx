import React from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Button } from '@/components/ui/button';
import { X, AlertCircle, CheckCircle, Clock } from 'lucide-react';
import { Source } from '@/types';

interface SourceCardProps {
  source: Source;
  onRemove: (id: string) => void;
  onSelect: (id: string) => void;
  isSelected: boolean;
  onPreload?: (id: string) => void;
}

export function SourceCard({ source, onRemove, onSelect, isSelected, onPreload }: SourceCardProps) {
  const getStatusIcon = () => {
    switch (source.status) {
      case 'error':
        return <AlertCircle className="h-4 w-4 text-destructive" />;
      case 'ready':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'scraping':
      case 'transcribing':
        return <Clock className="h-4 w-4 text-primary animate-pulse" />;
      default:
        return null;
    }
  };

  const getStatusText = () => {
    switch (source.status) {
      case 'scraping':
        return 'Fetching metadata...';
      case 'transcribing':
        return 'Transcribing audio...';
      case 'ready':
        return 'Ready';
      case 'error':
        return source.error || 'Error occurred';
      default:
        return 'Idle';
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      transition={{ duration: 0.3 }}
    >
      <Card 
        className={cn(
          "cursor-pointer transition-all hover:shadow-md",
          isSelected && "ring-2 ring-primary"
        )}
        onClick={() => source.status === 'ready' && onSelect(source.id)}
        onMouseEnter={() => {
          // Enterprise pre-loading on hover
          if (source.status === 'ready' && !isSelected && onPreload) {
            onPreload(source.id);
          }
        }}
      >
        <CardHeader className="p-4 pb-2">
          <div className="flex items-start justify-between gap-2">
            <div className="flex-1 min-w-0">
              {source.metadata ? (
                <>
                  <h3 className="font-semibold text-sm truncate">
                    {source.metadata.title}
                  </h3>
                  <p className="text-xs text-muted-foreground truncate">
                    {source.metadata.channel}
                  </p>
                </>
              ) : (
                <p className="text-sm text-muted-foreground truncate">
                  {source.url}
                </p>
              )}
            </div>
            <Button
              variant="ghost"
              size="icon"
              className="h-6 w-6"
              onClick={(e) => {
                e.stopPropagation();
                onRemove(source.id);
              }}
            >
              <X className="h-3 w-3" />
            </Button>
          </div>
        </CardHeader>
        
        <CardContent className="p-4 pt-2">
          {source.metadata?.thumbnail && (
            <div className="mb-3 rounded-md overflow-hidden">
              <img 
                src={source.metadata.thumbnail} 
                alt={source.metadata.title}
                className="w-full h-32 object-cover"
              />
            </div>
          )}
          
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-xs">
                {getStatusIcon()}
                <span className="text-muted-foreground">{getStatusText()}</span>
              </div>
            </div>
            
            {(source.status === 'scraping' || source.status === 'transcribing') && (
              <Progress value={source.progress} className="h-2" />
            )}
            
            {source.metadata && (
              <div className="text-xs text-muted-foreground space-y-1">
                <p>{Math.floor(source.metadata.duration / 60)} min</p>
                <p>{source.metadata.views.toLocaleString()} views</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}

// Helper function
function cn(...classes: (string | boolean | undefined)[]) {
  return classes.filter(Boolean).join(' ');
}