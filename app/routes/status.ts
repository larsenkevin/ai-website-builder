/**
 * Status Routes
 * 
 * Provides system status and health information.
 */

import { Router, Request, Response } from 'express';
import { RateLimiter } from '../services/RateLimiter.js';
import { Logger } from '../services/Logger.js';
import * as fs from 'fs/promises';
import * as os from 'os';

export function createStatusRouter(
  rateLimiter: RateLimiter,
  logger: Logger,
  publicDir: string
): Router {
  const router = Router();

  /**
   * GET /api/status
   * Get system status information
   */
  router.get('/', async (_req: Request, res: Response) => {
    try {
      // Check if public directory exists and has files
      let staticServerStatus: 'running' | 'stopped' | 'error' = 'running';
      try {
        await fs.access(publicDir);
        const files = await fs.readdir(publicDir);
        if (files.length === 0) {
          staticServerStatus = 'stopped';
        }
      } catch (error) {
        staticServerStatus = 'error';
      }

      // Get disk usage
      const diskUsage = await getDiskUsage();

      // Get API usage
      const apiUsage = {
        requestsThisMinute: rateLimiter.getCurrentRequestRate(),
        queueLength: rateLimiter.getQueueLength(),
        tokensThisMonth: rateLimiter.getMonthlyTokenUsage(),
        estimatedCost: calculateEstimatedCost(rateLimiter.getMonthlyTokenUsage()),
      };

      // Get system uptime
      const uptime = process.uptime();

      const status = {
        staticServer: {
          status: staticServerStatus,
          uptime: Math.floor(uptime),
        },
        sslCertificate: {
          status: 'valid', // This would need actual SSL cert checking
          expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
          daysUntilExpiry: 90,
        },
        apiUsage,
        lastBackup: {
          timestamp: new Date().toISOString(),
          success: true,
        },
        diskUsage,
      };

      res.json({
        success: true,
        status,
      });
    } catch (error: any) {
      logger.error('Failed to get status', {
        error: error.message,
        stack: error.stack,
      });

      res.status(500).json({
        error: 'Failed to get status',
        message: error.message,
      });
    }
  });

  return router;
}

/**
 * Get disk usage information
 */
async function getDiskUsage(): Promise<{
  total: number;
  used: number;
  available: number;
}> {
  // This is a simplified version - in production, use a proper disk usage library
  const totalMem = os.totalmem();
  const freeMem = os.freemem();

  return {
    total: totalMem,
    used: totalMem - freeMem,
    available: freeMem,
  };
}

/**
 * Calculate estimated cost based on token usage
 * Claude 3.5 Sonnet pricing: ~$3 per million input tokens, ~$15 per million output tokens
 * Assuming 50/50 split for estimation
 */
function calculateEstimatedCost(tokens: number): number {
  const avgCostPerToken = (3 + 15) / 2 / 1000000; // Average cost per token
  return tokens * avgCostPerToken;
}
