/**
 * RateLimiter Service
 * 
 * Controls API request rate and queuing to manage Claude API costs.
 * Tracks monthly token usage and provides notifications when thresholds are exceeded.
 */

import { Logger } from './Logger.js';

interface QueuedRequest {
  resolve: () => void;
  timestamp: number;
}

export interface RateLimiterConfig {
  maxRequestsPerMinute: number;
  monthlyTokenThreshold: number;
}

export class RateLimiter {
  private requestQueue: QueuedRequest[] = [];
  private requestTimestamps: number[] = [];
  private monthlyTokens: number = 0;
  private config: RateLimiterConfig;
  private logger: Logger;
  private processingInterval: NodeJS.Timeout | null = null;

  constructor(config: RateLimiterConfig, logger: Logger) {
    this.config = config;
    this.logger = logger;
    this.startQueueProcessing();
  }

  /**
   * Acquire permission to make an API request
   * Returns immediately if under rate limit, otherwise queues the request
   */
  async acquire(): Promise<void> {
    const now = Date.now();

    // Remove timestamps older than 1 minute
    this.requestTimestamps = this.requestTimestamps.filter(
      (ts) => now - ts < 60000
    );

    // Check if under rate limit
    if (this.requestTimestamps.length < this.config.maxRequestsPerMinute) {
      this.requestTimestamps.push(now);
      this.logger.debug('API request acquired', {
        currentRequests: this.requestTimestamps.length,
        maxRequests: this.config.maxRequestsPerMinute,
      });
      return;
    }

    // Queue the request
    this.logger.info('API request queued due to rate limit', {
      queueLength: this.requestQueue.length + 1,
    });

    return new Promise((resolve) => {
      this.requestQueue.push({ resolve, timestamp: now });
    });
  }

  /**
   * Track token usage for monthly monitoring
   */
  trackTokenUsage(tokens: number): void {
    this.monthlyTokens += tokens;

    this.logger.debug('Token usage tracked', {
      tokensUsed: tokens,
      monthlyTotal: this.monthlyTokens,
      threshold: this.config.monthlyTokenThreshold,
    });

    // Check if threshold exceeded
    if (this.monthlyTokens > this.config.monthlyTokenThreshold) {
      this.notifyThresholdExceeded();
    }
  }

  /**
   * Get current monthly token usage
   */
  getMonthlyTokenUsage(): number {
    return this.monthlyTokens;
  }

  /**
   * Reset monthly token counter (should be called at start of each month)
   */
  resetMonthlyTokens(): void {
    this.logger.info('Resetting monthly token counter', {
      previousTotal: this.monthlyTokens,
    });
    this.monthlyTokens = 0;
  }

  /**
   * Get current queue length
   */
  getQueueLength(): number {
    return this.requestQueue.length;
  }

  /**
   * Get current requests per minute
   */
  getCurrentRequestRate(): number {
    const now = Date.now();
    this.requestTimestamps = this.requestTimestamps.filter(
      (ts) => now - ts < 60000
    );
    return this.requestTimestamps.length;
  }

  /**
   * Start processing queued requests
   */
  private startQueueProcessing(): void {
    this.processingInterval = setInterval(() => {
      this.processQueue();
    }, 1000); // Check every second
  }

  /**
   * Process queued requests when rate limit allows
   */
  private processQueue(): void {
    const now = Date.now();

    // Remove timestamps older than 1 minute
    this.requestTimestamps = this.requestTimestamps.filter(
      (ts) => now - ts < 60000
    );

    // Process as many requests as rate limit allows
    while (
      this.requestQueue.length > 0 &&
      this.requestTimestamps.length < this.config.maxRequestsPerMinute
    ) {
      const request = this.requestQueue.shift()!;
      this.requestTimestamps.push(Date.now());

      this.logger.debug('Processing queued API request', {
        queueLength: this.requestQueue.length,
        currentRequests: this.requestTimestamps.length,
      });

      request.resolve();
    }
  }

  /**
   * Notify when monthly token threshold is exceeded
   */
  private notifyThresholdExceeded(): void {
    this.logger.warn('Monthly token threshold exceeded', {
      monthlyTokens: this.monthlyTokens,
      threshold: this.config.monthlyTokenThreshold,
      percentageUsed: Math.round(
        (this.monthlyTokens / this.config.monthlyTokenThreshold) * 100
      ),
    });

    // In a production system, this would send an email or notification
    // For now, we just log the warning
  }

  /**
   * Stop queue processing (cleanup)
   */
  stop(): void {
    if (this.processingInterval) {
      clearInterval(this.processingInterval);
      this.processingInterval = null;
    }
  }
}
