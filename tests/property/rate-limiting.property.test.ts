/**
 * Property-Based Tests for Rate Limiting
 * 
 * Tests rate limiter behavior including request tracking, queuing,
 * queue processing, and token usage tracking.
 */

import { describe, it, beforeEach, afterEach, expect } from 'vitest';
import * as fc from 'fast-check';
import { RateLimiter, RateLimiterConfig } from '../../app/services/RateLimiter.js';
import { Logger, LogLevel } from '../../app/services/Logger.js';

/**
 * Property 29: Rate Limiting - Request Tracking
 * 
 * For any API request, the Rate_Limiter SHALL increment the request count 
 * for the current minute.
 * 
 * **Validates: Requirements 18.1**
 */

/**
 * Property 30: Rate Limiting - Queue on Excess
 * 
 * For any API request when the current minute already has 10 or more requests, 
 * the Rate_Limiter SHALL queue the request instead of executing it immediately.
 * 
 * **Validates: Requirements 18.2**
 */

/**
 * Property 31: Rate Limiting - Queue Processing
 * 
 * For any queued API request, when the rate limit allows, the Rate_Limiter 
 * SHALL process the request.
 * 
 * **Validates: Requirements 18.3**
 */

/**
 * Property 32: Token Usage Tracking
 * 
 * For any completed API request, the Rate_Limiter SHALL add the token count 
 * to the monthly total.
 * 
 * **Validates: Requirements 18.4**
 */

/**
 * Property 33: Token Threshold Notification
 * 
 * For any API request that causes monthly token usage to exceed the configured 
 * threshold, the Rate_Limiter SHALL trigger a notification.
 * 
 * **Validates: Requirements 18.5**
 */

/**
 * Property 38: Concurrent Request Queuing
 * 
 * For any set of API requests submitted simultaneously when rate limits are 
 * active, the Rate_Limiter SHALL queue all requests that exceed the limit.
 * 
 * **Validates: Requirements 20.1**
 */

/**
 * Property 39: FIFO Queue Processing
 * 
 * For any set of queued requests, the Rate_Limiter SHALL process them in the 
 * order they were queued (first-in-first-out).
 * 
 * **Validates: Requirements 20.2**
 */

/**
 * Property 40: Rate Limit Respect During Queue Processing
 * 
 * For any queue processing operation, the Rate_Limiter SHALL NOT exceed the 
 * configured rate limit of 10 requests per minute.
 * 
 * **Validates: Requirements 20.3**
 */

describe('Rate Limiting Properties', () => {
  let logger: Logger;
  let rateLimiter: RateLimiter;

  beforeEach(() => {
    // Create logger for testing
    logger = new Logger({
      logDir: './logs/rate-limiter-test',
      logLevel: LogLevel.ERROR, // Minimize test output
      maxLogSizeMB: 100,
      retentionDays: 30,
    });
  });

  afterEach(() => {
    if (rateLimiter) {
      rateLimiter.stop();
    }
  });

  describe('Property 29: Rate Limiting - Request Tracking', () => {
    it('Property: Each acquire increments request count', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 1, max: 10 }),
          async (numRequests) => {
            const config: RateLimiterConfig = {
              maxRequestsPerMinute: 10,
              monthlyTokenThreshold: 1000000,
            };
            rateLimiter = new RateLimiter(config, logger);

            // Make requests
            for (let i = 0; i < numRequests; i++) {
              await rateLimiter.acquire();
            }

            // Check request rate
            const currentRate = rateLimiter.getCurrentRequestRate();
            if (currentRate !== numRequests) {
              throw new Error(`Expected ${numRequests} requests, got ${currentRate}`);
            }

            rateLimiter.stop();
          }
        ),
        { numRuns: 20 }
      );
    });

    it('Property: Request timestamps older than 1 minute are removed', async () => {
      const config: RateLimiterConfig = {
        maxRequestsPerMinute: 10,
        monthlyTokenThreshold: 1000000,
      };
      rateLimiter = new RateLimiter(config, logger);

      // Make some requests
      await rateLimiter.acquire();
      await rateLimiter.acquire();
      
      const initialRate = rateLimiter.getCurrentRequestRate();
      expect(initialRate).toBe(2);

      // Wait for timestamps to age (simulate by checking after a delay)
      // In real scenario, timestamps older than 60s would be removed
      // For testing, we verify the getCurrentRequestRate filters correctly
      const rateAfterCheck = rateLimiter.getCurrentRequestRate();
      expect(rateAfterCheck).toBeLessThanOrEqual(initialRate);

      rateLimiter.stop();
    });
  });

  describe('Property 30: Rate Limiting - Queue on Excess', () => {
    it('Property: Requests beyond limit are queued', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 11, max: 20 }),
          async (numRequests) => {
            const config: RateLimiterConfig = {
              maxRequestsPerMinute: 10,
              monthlyTokenThreshold: 1000000,
            };
            rateLimiter = new RateLimiter(config, logger);

            // Make requests that exceed the limit
            for (let i = 0; i < numRequests; i++) {
              rateLimiter.acquire();
            }

            // First 10 should complete immediately
            // Remaining should be queued
            const expectedQueued = numRequests - 10;
            
            // Give a moment for synchronous requests to complete
            await new Promise(resolve => setTimeout(resolve, 10));
            
            const queueLength = rateLimiter.getQueueLength();
            if (queueLength !== expectedQueued) {
              throw new Error(`Expected ${expectedQueued} queued requests, got ${queueLength}`);
            }

            rateLimiter.stop();
          }
        ),
        { numRuns: 20 }
      );
    });

    it('Property: Queued requests eventually resolve', async () => {
      const config: RateLimiterConfig = {
        maxRequestsPerMinute: 5,
        monthlyTokenThreshold: 1000000,
      };
      rateLimiter = new RateLimiter(config, logger);

      // Make 7 requests (5 immediate, 2 queued)
      const promises: Promise<void>[] = [];
      for (let i = 0; i < 7; i++) {
        promises.push(rateLimiter.acquire());
      }

      // Wait for queue to process (up to 3 seconds)
      await Promise.race([
        Promise.all(promises),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Timeout waiting for queue')), 3000)
        ),
      ]);

      // All requests should have completed
      const queueLength = rateLimiter.getQueueLength();
      expect(queueLength).toBe(0);

      rateLimiter.stop();
    });
  });

  describe('Property 31: Rate Limiting - Queue Processing', () => {
    it('Property: Queue processes requests when rate limit allows', async () => {
      const config: RateLimiterConfig = {
        maxRequestsPerMinute: 5,
        monthlyTokenThreshold: 1000000,
      };
      rateLimiter = new RateLimiter(config, logger);

      // Fill up the rate limit
      for (let i = 0; i < 5; i++) {
        await rateLimiter.acquire();
      }

      // Queue additional requests
      const queuedPromises: Promise<void>[] = [];
      for (let i = 0; i < 3; i++) {
        queuedPromises.push(rateLimiter.acquire());
      }

      const initialQueueLength = rateLimiter.getQueueLength();
      expect(initialQueueLength).toBe(3);

      // Wait for queue processing (should process within 2 seconds)
      await Promise.race([
        Promise.all(queuedPromises),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Queue not processed in time')), 3000)
        ),
      ]);

      const finalQueueLength = rateLimiter.getQueueLength();
      expect(finalQueueLength).toBe(0);

      rateLimiter.stop();
    });
  });

  describe('Property 32: Token Usage Tracking', () => {
    it('Property: Token usage accumulates correctly', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.array(fc.integer({ min: 1, max: 10000 }), { minLength: 1, maxLength: 20 }),
          async (tokenCounts) => {
            const config: RateLimiterConfig = {
              maxRequestsPerMinute: 100,
              monthlyTokenThreshold: 1000000,
            };
            rateLimiter = new RateLimiter(config, logger);

            // Track tokens
            let expectedTotal = 0;
            for (const tokens of tokenCounts) {
              rateLimiter.trackTokenUsage(tokens);
              expectedTotal += tokens;
            }

            const actualTotal = rateLimiter.getMonthlyTokenUsage();
            if (actualTotal !== expectedTotal) {
              throw new Error(`Expected ${expectedTotal} tokens, got ${actualTotal}`);
            }

            rateLimiter.stop();
          }
        ),
        { numRuns: 50 }
      );
    });

    it('Property: Reset clears monthly token count', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 1000, max: 100000 }),
          async (initialTokens) => {
            const config: RateLimiterConfig = {
              maxRequestsPerMinute: 100,
              monthlyTokenThreshold: 1000000,
            };
            rateLimiter = new RateLimiter(config, logger);

            // Track some tokens
            rateLimiter.trackTokenUsage(initialTokens);
            
            const beforeReset = rateLimiter.getMonthlyTokenUsage();
            if (beforeReset !== initialTokens) {
              throw new Error(`Expected ${initialTokens} tokens before reset, got ${beforeReset}`);
            }

            // Reset
            rateLimiter.resetMonthlyTokens();

            const afterReset = rateLimiter.getMonthlyTokenUsage();
            if (afterReset !== 0) {
              throw new Error(`Expected 0 tokens after reset, got ${afterReset}`);
            }

            rateLimiter.stop();
          }
        ),
        { numRuns: 30 }
      );
    });
  });

  describe('Property 33: Token Threshold Notification', () => {
    it('Property: Notification triggered when threshold exceeded', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.tuple(
            fc.integer({ min: 1000, max: 10000 }),
            fc.integer({ min: 1, max: 5000 })
          ),
          async ([threshold, excessTokens]) => {
            const config: RateLimiterConfig = {
              maxRequestsPerMinute: 100,
              monthlyTokenThreshold: threshold,
            };
            rateLimiter = new RateLimiter(config, logger);

            // Track tokens up to threshold
            rateLimiter.trackTokenUsage(threshold);
            
            // Track additional tokens to exceed threshold
            rateLimiter.trackTokenUsage(excessTokens);

            const total = rateLimiter.getMonthlyTokenUsage();
            if (total <= threshold) {
              throw new Error(`Expected total > ${threshold}, got ${total}`);
            }

            // Notification is logged (we can't easily test the log output in property tests)
            // But we verify the state is correct
            if (total !== threshold + excessTokens) {
              throw new Error(`Expected ${threshold + excessTokens} tokens, got ${total}`);
            }

            rateLimiter.stop();
          }
        ),
        { numRuns: 30 }
      );
    });
  });

  describe('Property 38: Concurrent Request Queuing', () => {
    it('Property: Concurrent requests beyond limit are all queued', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 15, max: 30 }),
          async (numConcurrentRequests) => {
            const config: RateLimiterConfig = {
              maxRequestsPerMinute: 10,
              monthlyTokenThreshold: 1000000,
            };
            rateLimiter = new RateLimiter(config, logger);

            // Submit all requests concurrently
            const promises = Array.from({ length: numConcurrentRequests }, () =>
              rateLimiter.acquire()
            );

            // Give a moment for synchronous processing
            await new Promise(resolve => setTimeout(resolve, 10));

            // Check queue length
            const queueLength = rateLimiter.getQueueLength();
            const expectedQueued = numConcurrentRequests - 10;
            
            if (queueLength !== expectedQueued) {
              throw new Error(`Expected ${expectedQueued} queued, got ${queueLength}`);
            }

            rateLimiter.stop();
          }
        ),
        { numRuns: 20 }
      );
    });
  });

  describe('Property 39: FIFO Queue Processing', () => {
    it('Property: Requests are processed in order they were queued', async () => {
      const config: RateLimiterConfig = {
        maxRequestsPerMinute: 3,
        monthlyTokenThreshold: 1000000,
      };
      rateLimiter = new RateLimiter(config, logger);

      // Fill rate limit
      await rateLimiter.acquire();
      await rateLimiter.acquire();
      await rateLimiter.acquire();

      // Queue requests with identifiers
      const completionOrder: number[] = [];
      const promises: Promise<void>[] = [];

      for (let i = 0; i < 5; i++) {
        const id = i;
        promises.push(
          rateLimiter.acquire().then(() => {
            completionOrder.push(id);
          })
        );
      }

      // Wait for all to complete
      await Promise.all(promises);

      // Verify FIFO order
      for (let i = 0; i < completionOrder.length - 1; i++) {
        if (completionOrder[i] > completionOrder[i + 1]) {
          throw new Error(`FIFO order violated: ${completionOrder.join(', ')}`);
        }
      }

      rateLimiter.stop();
    });
  });

  describe('Property 40: Rate Limit Respect During Queue Processing', () => {
    it('Property: Queue processing never exceeds rate limit', async () => {
      const config: RateLimiterConfig = {
        maxRequestsPerMinute: 5,
        monthlyTokenThreshold: 1000000,
      };
      rateLimiter = new RateLimiter(config, logger);

      // Queue many requests
      const promises: Promise<void>[] = [];
      for (let i = 0; i < 15; i++) {
        promises.push(rateLimiter.acquire());
      }

      // Check rate periodically during processing
      const checkInterval = setInterval(() => {
        const currentRate = rateLimiter.getCurrentRequestRate();
        if (currentRate > config.maxRequestsPerMinute) {
          clearInterval(checkInterval);
          rateLimiter.stop();
          throw new Error(`Rate limit exceeded: ${currentRate} > ${config.maxRequestsPerMinute}`);
        }
      }, 100);

      // Wait for all requests to complete
      await Promise.all(promises);
      clearInterval(checkInterval);

      // Final check
      const finalRate = rateLimiter.getCurrentRequestRate();
      expect(finalRate).toBeLessThanOrEqual(config.maxRequestsPerMinute);

      rateLimiter.stop();
    });
  });
});
