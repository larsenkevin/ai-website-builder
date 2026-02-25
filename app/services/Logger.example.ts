/**
 * Logger Usage Examples
 * 
 * This file demonstrates how to use the Logger service throughout the application.
 */

import { logger } from './Logger.js';

// Example 1: Basic logging at different levels
export function basicLoggingExample() {
  logger.debug('Detailed debug information', { step: 1, data: 'processing' });
  logger.info('Operation completed successfully', { operation: 'backup', duration: 1500 });
  logger.warn('Approaching rate limit', { current: 9, limit: 10 });
  logger.error('Failed to connect to database', { 
    error: 'Connection timeout',
    host: 'localhost',
    port: 5432 
  });
}

// Example 2: Using correlation IDs for request tracing
export function correlationIdExample() {
  const correlationId = logger.generateCorrelationId();
  
  logger.info('Starting user registration', { email: 'user@example.com' }, correlationId);
  logger.info('Validating user data', { fields: ['email', 'password'] }, correlationId);
  logger.info('Creating user record', { userId: '123' }, correlationId);
  logger.info('User registration complete', { userId: '123' }, correlationId);
  
  // All these logs will have the same correlationId, making it easy to trace the entire flow
}

// Example 3: Logging API requests
export function apiRequestLoggingExample(correlationId: string) {
  const startTime = Date.now();
  
  // ... handle request ...
  
  const duration = Date.now() - startTime;
  logger.logApiRequest(
    'POST',
    '/api/pages/home/edit',
    200,
    duration,
    correlationId,
    {
      userId: '123',
      pageId: 'home',
    }
  );
}

// Example 4: Logging configuration changes
export function configChangeLoggingExample(correlationId: string) {
  logger.logConfigChange(
    'page',           // configType
    'home',           // configId
    'update',         // action
    correlationId,
    {
      field: 'title',
      oldValue: 'Welcome',
      newValue: 'Welcome to Our Site',
    }
  );
}

// Example 5: Error logging with stack traces
export function errorLoggingExample() {
  try {
    // Some operation that might fail
    throw new Error('Database connection failed');
  } catch (error: any) {
    logger.error('Operation failed', {
      error: error.message,
      operation: 'fetchUserData',
      userId: '123',
    });
    // Stack trace is automatically captured
  }
}

// Example 6: Structured metadata for complex operations
export function structuredLoggingExample() {
  logger.info('Image processing started', {
    imageId: 'img-123',
    originalSize: 5242880, // 5MB
    format: 'jpeg',
    variants: [320, 768, 1920],
  });
  
  logger.info('Image processing complete', {
    imageId: 'img-123',
    outputFormat: 'webp',
    variants: [
      { width: 320, size: 45000 },
      { width: 768, size: 120000 },
      { width: 1920, size: 350000 },
    ],
    totalDuration: 2500,
  });
}

// Example 7: Using logger in Express middleware
export function expressMiddlewareExample() {
  return (req: any, _res: any, next: any) => {
    const correlationId = req.correlationId;
    
    logger.info('Processing request', {
      method: req.method,
      path: req.path,
      query: req.query,
      ip: req.ip,
    }, correlationId);
    
    next();
  };
}

// Example 8: Logging with different contexts
export function contextualLoggingExample() {
  // AI Agent context
  logger.info('AI request sent', {
    context: 'ai-agent',
    model: 'claude-3-5-sonnet',
    tokens: 1500,
    conversationLength: 5,
  });
  
  // Session management context
  logger.info('Session created', {
    context: 'session-manager',
    pageId: 'home',
    sessionId: 'sess-123',
  });
  
  // Asset processing context
  logger.info('Asset uploaded', {
    context: 'asset-processor',
    assetId: 'asset-456',
    type: 'image',
    size: 2048000,
  });
}
