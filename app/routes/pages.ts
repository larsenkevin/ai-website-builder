/**
 * Pages Routes
 * 
 * Handles page management, editing sessions, and AI chat.
 */

import { Router, Request, Response } from 'express';
import { ConfigManager } from '../services/ConfigManager.js';
import { SessionManager } from '../services/SessionManager.js';
import { AIAgent } from '../services/AIAgent.js';
import { VersionManager } from '../services/VersionManager.js';
import { Logger } from '../services/Logger.js';

export function createPagesRouter(
  configManager: ConfigManager,
  sessionManager: SessionManager,
  aiAgent: AIAgent,
  versionManager: VersionManager,
  logger: Logger
): Router {
  const router = Router();

  /**
   * GET /api/pages
   * List all pages
   */
  router.get('/', async (_req: Request, res: Response) => {
    try {
      const pages = await configManager.listPages();
      const pageConfigs = await Promise.all(
        pages.map((pageId) => configManager.loadPageConfig(pageId))
      );

      res.json({
        success: true,
        pages: pageConfigs,
      });
    } catch (error: any) {
      logger.error('Failed to list pages', {
        error: error.message,
        stack: error.stack,
      });

      res.status(500).json({
        error: 'Failed to list pages',
        message: error.message,
      });
    }
  });

  /**
   * POST /api/pages/:id/edit
   * Start editing session
   */
  router.post('/:id/edit', async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const pageId = Array.isArray(id) ? id[0] : id;
      logger.info('Starting editing session', { pageId });

      const session = await sessionManager.startEditing(pageId);

      res.json({
        success: true,
        session: {
          pageId: session.pageId,
          tempConfig: session.tempConfig,
          conversationHistory: session.tempConfig.conversationHistory,
          startedAt: session.startedAt,
        },
      });
    } catch (error: any) {
      logger.error('Failed to start editing session', {
        pageId: req.params.id,
        error: error.message,
        stack: error.stack,
      });

      res.status(500).json({
        error: 'Failed to start editing session',
        message: error.message,
      });
    }
  });

  /**
   * POST /api/pages/:id/ai-chat
   * Send message to AI and get response
   */
  router.post('/:id/ai-chat', async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;
      const pageId = Array.isArray(id) ? id[0] : id;
      const { message } = req.body;

      if (!message) {
        res.status(400).json({
          error: 'Message is required',
        });
        return;
      }

      logger.info('Processing AI chat message', { pageId });

      const session = sessionManager.getSession(pageId);
      if (!session) {
        res.status(404).json({
          error: 'No active editing session',
        });
        return;
      }

      const siteConfig = await configManager.loadSiteConfig();

      // Build page context
      const pageContext = {
        businessName: siteConfig.businessName,
        industry: siteConfig.industry,
        businessDescription: siteConfig.description,
        pageTitle: session.tempConfig.title,
        intent: session.tempConfig.intent,
      };

      // Get AI response
      const aiResponse = await aiAgent.generateContent(
        session.tempConfig.conversationHistory,
        message,
        pageContext
      );

      // Update conversation history
      session.tempConfig.conversationHistory.push({
        role: 'user',
        content: message,
        timestamp: new Date().toISOString(),
      });

      session.tempConfig.conversationHistory.push({
        role: 'assistant',
        content: aiResponse.content,
        timestamp: new Date().toISOString(),
      });

      // Save updated temp config
      await configManager.saveTempConfig(session.tempConfig);

      res.json({
        success: true,
        response: aiResponse.content,
        tokensUsed: aiResponse.tokensUsed,
        conversationHistory: session.tempConfig.conversationHistory,
      });
    } catch (error: any) {
      logger.error('AI chat failed', {
        pageId: req.params.id,
        error: error.message,
        stack: error.stack,
      });

      res.status(500).json({
        error: 'AI chat failed',
        message: error.message,
      });
    }
  });

  /**
   * POST /api/pages/:id/confirm
   * Confirm changes and publish
   */
  router.post('/:id/confirm', async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const pageId = Array.isArray(id) ? id[0] : id;
      logger.info('Confirming changes', { pageId });

      // Create version backup before confirming
      await versionManager.createBackup(pageId);

      // Confirm changes
      await sessionManager.confirmChanges(pageId);

      res.json({
        success: true,
        message: 'Changes confirmed and published',
      });
    } catch (error: any) {
      logger.error('Failed to confirm changes', {
        pageId: req.params.id,
        error: error.message,
        stack: error.stack,
      });

      res.status(500).json({
        error: 'Failed to confirm changes',
        message: error.message,
      });
    }
  });

  /**
   * POST /api/pages/:id/cancel
   * Cancel changes and discard temp config
   */
  router.post('/:id/cancel', async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const pageId = Array.isArray(id) ? id[0] : id;
      logger.info('Canceling changes', { pageId });

      await sessionManager.cancelChanges(pageId);

      res.json({
        success: true,
        message: 'Changes canceled',
      });
    } catch (error: any) {
      logger.error('Failed to cancel changes', {
        pageId: req.params.id,
        error: error.message,
        stack: error.stack,
      });

      res.status(500).json({
        error: 'Failed to cancel changes',
        message: error.message,
      });
    }
  });

  /**
   * GET /api/pages/:id/versions
   * List versions for a page
   */
  router.get('/:id/versions', async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const pageId = Array.isArray(id) ? id[0] : id;
      const versions = await versionManager.listVersions(pageId);

      res.json({
        success: true,
        versions,
      });
    } catch (error: any) {
      logger.error('Failed to list versions', {
        pageId: req.params.id,
        error: error.message,
        stack: error.stack,
      });

      res.status(500).json({
        error: 'Failed to list versions',
        message: error.message,
      });
    }
  });

  /**
   * POST /api/pages/:id/rollback
   * Restore a previous version
   */
  router.post('/:id/rollback', async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;
      const pageId = Array.isArray(id) ? id[0] : id;
      const { versionNumber } = req.body;

      if (!versionNumber) {
        res.status(400).json({
          error: 'Version number is required',
        });
        return;
      }

      logger.info('Rolling back to version', { pageId, versionNumber });

      await versionManager.restoreVersion(pageId, versionNumber);

      res.json({
        success: true,
        message: `Rolled back to version ${versionNumber}`,
      });
    } catch (error: any) {
      logger.error('Failed to rollback version', {
        pageId: req.params.id,
        error: error.message,
        stack: error.stack,
      });

      res.status(500).json({
        error: 'Failed to rollback version',
        message: error.message,
      });
    }
  });

  return router;
}
