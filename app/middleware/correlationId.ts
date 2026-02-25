import { Request, Response, NextFunction } from 'express';
import { logger } from '../services/Logger.js';

// Extend Express Request type to include correlationId
declare global {
  namespace Express {
    interface Request {
      correlationId?: string;
    }
  }
}

export function correlationIdMiddleware(req: Request, res: Response, next: NextFunction): void {
  // Generate or use existing correlation ID from header
  const correlationId = req.headers['x-correlation-id'] as string || logger.generateCorrelationId();
  
  // Attach to request
  req.correlationId = correlationId;
  
  // Add to response headers
  res.setHeader('X-Correlation-ID', correlationId);
  
  next();
}
