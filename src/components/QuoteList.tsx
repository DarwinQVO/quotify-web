import React from 'react';
import { motion, Reorder } from 'framer-motion';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Trash2, ExternalLink, GripVertical } from 'lucide-react';
import { Quote } from '@/types';
import { getAPI } from '@/lib/webAPI';

interface QuoteListProps {
  quotes: Quote[];
  selectedQuotes: Set<string>;
  onSelectQuote: (id: string) => void;
  onDeleteQuote: (id: string) => void;
  onReorderQuotes: (quotes: Quote[]) => void;
}

export function QuoteList({
  quotes,
  selectedQuotes,
  onSelectQuote,
  onDeleteQuote,
  onReorderQuotes
}: QuoteListProps) {
  return (
    <Reorder.Group
      axis="y"
      values={quotes}
      onReorder={onReorderQuotes}
      className="flex-1 overflow-y-auto space-y-3"
    >
      {quotes.map((quote) => (
        <Reorder.Item
          key={quote.id}
          value={quote}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.3 }}
        >
          <Card className="cursor-move">
            <CardContent className="p-4">
              <div className="flex items-start gap-3">
                <div className="pt-1">
                  <Checkbox
                    checked={selectedQuotes.has(quote.id)}
                    onCheckedChange={() => onSelectQuote(quote.id)}
                  />
                </div>
                
                <div className="flex-1 min-w-0">
                  <p className="text-sm mb-2">{quote.text}</p>
                  <p className="text-xs text-muted-foreground">
                    — {quote.citation}
                  </p>
                </div>
                
                <div className="flex items-center gap-1">
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-8 w-8 cursor-grab active:cursor-grabbing"
                  >
                    <GripVertical className="h-4 w-4" />
                  </Button>
                  
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-8 w-8"
                    onClick={() => getAPI().openExternal(quote.deepLink)}
                  >
                    <ExternalLink className="h-4 w-4" />
                  </Button>
                  
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-8 w-8"
                    onClick={() => onDeleteQuote(quote.id)}
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </Reorder.Item>
      ))}
    </Reorder.Group>
  );
}