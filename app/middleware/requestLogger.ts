import { Request, Response, NextFunction } from 'express';
import { logger } from '../services/Logger.js';

export function requestLoggerMiddleware(req: Request, res: Response, next: NextFunction): void {
  const startTime = Date.now();
  
  // Log when response finishes
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    
    logger.logApiRequest(
      req.method,
      req.path,
      res.statusCode,
      duration,
      req.correlationId || 'unknown',
      {
        query: req.query,
        userAgent: req.headers['user-agent'],
      }
    );
  });
  
  next();
}
