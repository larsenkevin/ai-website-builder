import { ConfigManager } from './ConfigManager.js';
import { TempConfig, Message } from '../types/config.js';
import { logger } from './Logger.js';
import { v4 as uuidv4 } from 'uuid';

export interface EditingSession {
  pageId: string;
  sessionId: string;
  tempConfig: TempConfig;
  startedAt: Date;
}

export class SessionManager {
  private configManager: ConfigManager;
  private sessions: Map<string, EditingSession> = new Map();

  constructor(configManager: ConfigManager) {
    this.configManager = configManager;
  }

  /**
   * Start an editing session for a page
   * Creates a temp config file and stores session in memory
   */
  async startEditing(pageId: string, correlationId?: string): Promise<EditingSession> {
    try {
      // Check if session already exists
      if (this.sessions.has(pageId)) {
        logger.warn('Editing session already exists', { pageId }, correlationId);
        throw new Error(`Page ${pageId} is already being edited`);
      }

      // Load current page config
      const pageConfig = await this.configManager.loadPageConfig(pageId);

      // Generate session ID
      const sessionId = uuidv4();
      const startedAt = new Date();

      // Create temp config from page config
      const tempConfig: TempConfig = {
        ...pageConfig,
        sessionId,
        startedAt: startedAt.toISOString(),
        conversationHistory: [],
      };

      // Save temp config to file
      await this.configManager.saveTempConfig(tempConfig, correlationId);

      // Create session object
      const session: EditingSession = {
        pageId,
        sessionId,
        tempConfig,
        startedAt,
      };

      // Store in memory
      this.sessions.set(pageId, session);

      logger.info('Editing session started', { pageId, sessionId }, correlationId);

      return session;
    } catch (error) {
      logger.error('Failed to start editing session', { pageId, error }, correlationId);
      throw error;
    }
  }

  /**
   * Confirm changes and copy temp config to page config
   * Deletes the temp config file after successful copy
   */
  async confirmChanges(pageId: string, correlationId?: string): Promise<void> {
    try {
      const session = this.sessions.get(pageId);
      if (!session) {
        logger.warn('No active session to confirm', { pageId }, correlationId);
        throw new Error(`No active editing session for page: ${pageId}`);
      }

      // Copy temp config to page config
      await this.configManager.copyTempToPage(pageId, correlationId);

      // Delete temp config
      await this.configManager.deleteTempConfig(pageId, correlationId);

      // Remove session from memory
      this.sessions.delete(pageId);

      logger.info('Changes confirmed', { pageId, sessionId: session.sessionId }, correlationId);
    } catch (error) {
      logger.error('Failed to confirm changes', { pageId, error }, correlationId);
      throw error;
    }
  }

  /**
   * Cancel changes and delete temp config
   * Preserves the original page config
   */
  async cancelChanges(pageId: string, correlationId?: string): Promise<void> {
    try {
      const session = this.sessions.get(pageId);
      if (!session) {
        logger.warn('No active session to cancel', { pageId }, correlationId);
        throw new Error(`No active editing session for page: ${pageId}`);
      }

      // Delete temp config (preserves page config)
      await this.configManager.deleteTempConfig(pageId, correlationId);

      // Remove session from memory
      this.sessions.delete(pageId);

      logger.info('Changes cancelled', { pageId, sessionId: session.sessionId }, correlationId);
    } catch (error) {
      logger.error('Failed to cancel changes', { pageId, error }, correlationId);
      throw error;
    }
  }

  /**
   * Restore sessions from existing temp files on startup
   * This allows sessions to persist across server restarts
   */
  async restoreSessions(correlationId?: string): Promise<void> {
    try {
      const tempConfigIds = await this.configManager.listTempConfigs();

      logger.info('Restoring sessions from temp configs', { count: tempConfigIds.length }, correlationId);

      for (const pageId of tempConfigIds) {
        try {
          const tempConfig = await this.configManager.loadTempConfig(pageId);

          const session: EditingSession = {
            pageId,
            sessionId: tempConfig.sessionId,
            tempConfig,
            startedAt: new Date(tempConfig.startedAt),
          };

          this.sessions.set(pageId, session);

          logger.debug('Session restored', { pageId, sessionId: tempConfig.sessionId }, correlationId);
        } catch (error) {
          logger.error('Failed to restore session', { pageId, error }, correlationId);
          // Continue with other sessions even if one fails
        }
      }

      logger.info('Session restoration complete', { restoredCount: this.sessions.size }, correlationId);
    } catch (error) {
      logger.error('Failed to restore sessions', { error }, correlationId);
      throw error;
    }
  }

  /**
   * Get an active session
   */
  getSession(pageId: string): EditingSession | undefined {
    return this.sessions.get(pageId);
  }

  /**
   * Get all active sessions
   */
  getAllSessions(): EditingSession[] {
    return Array.from(this.sessions.values());
  }

  /**
   * Check if a page has an active session
   */
  hasActiveSession(pageId: string): boolean {
    return this.sessions.has(pageId);
  }

  /**
   * Update the temp config for an active session
   */
  async updateTempConfig(pageId: string, updates: Partial<TempConfig>, correlationId?: string): Promise<void> {
    try {
      const session = this.sessions.get(pageId);
      if (!session) {
        throw new Error(`No active editing session for page: ${pageId}`);
      }

      // Merge updates into temp config
      const updatedTempConfig: TempConfig = {
        ...session.tempConfig,
        ...updates,
        // Preserve required fields
        id: session.tempConfig.id,
        sessionId: session.tempConfig.sessionId,
        startedAt: session.tempConfig.startedAt,
      };

      // Save updated temp config
      await this.configManager.saveTempConfig(updatedTempConfig, correlationId);

      // Update session in memory
      session.tempConfig = updatedTempConfig;

      logger.debug('Temp config updated', { pageId, sessionId: session.sessionId }, correlationId);
    } catch (error) {
      logger.error('Failed to update temp config', { pageId, error }, correlationId);
      throw error;
    }
  }

  /**
   * Add a message to the conversation history
   */
  async addMessage(pageId: string, message: Message, correlationId?: string): Promise<void> {
    try {
      const session = this.sessions.get(pageId);
      if (!session) {
        throw new Error(`No active editing session for page: ${pageId}`);
      }

      // Add message to conversation history
      const conversationHistory = [...session.tempConfig.conversationHistory, message];

      // Update temp config with new conversation history
      await this.updateTempConfig(pageId, { conversationHistory }, correlationId);

      logger.debug('Message added to conversation', { 
        pageId, 
        sessionId: session.sessionId,
        role: message.role 
      }, correlationId);
    } catch (error) {
      logger.error('Failed to add message', { pageId, error }, correlationId);
      throw error;
    }
  }

  /**
   * Clean up abandoned sessions older than 24 hours
   * Identifies temp configs older than 24 hours and deletes them
   * Also removes corresponding sessions from memory
   */
  async cleanupAbandonedSessions(correlationId?: string): Promise<void> {
    try {
      const tempConfigIds = await this.configManager.listTempConfigs();
      const now = Date.now();
      const twentyFourHours = 24 * 60 * 60 * 1000;

      logger.info('Starting session cleanup', { tempConfigCount: tempConfigIds.length }, correlationId);

      let cleanedCount = 0;

      for (const pageId of tempConfigIds) {
        try {
          // Get temp config file stats to check age
          const tempConfigPath = this.configManager.getPublicTempConfigPath(pageId);
          const stats = await this.configManager.getFileStats(tempConfigPath);

          if (!stats) {
            logger.warn('Temp config file not found during cleanup', { pageId }, correlationId);
            continue;
          }

          // Calculate age in milliseconds
          const age = now - stats.mtimeMs;

          // If older than 24 hours, delete it
          if (age > twentyFourHours) {
            logger.info('Cleaning up abandoned session', {
              pageId,
              ageHours: Math.round(age / (60 * 60 * 1000))
            }, correlationId);

            // Delete temp config file
            await this.configManager.deleteTempConfig(pageId, correlationId);

            // Remove from memory if present
            if (this.sessions.has(pageId)) {
              this.sessions.delete(pageId);
            }

            cleanedCount++;
          }
        } catch (error) {
          logger.error('Failed to cleanup session', { pageId, error }, correlationId);
          // Continue with other sessions even if one fails
        }
      }

      logger.info('Session cleanup complete', { cleanedCount }, correlationId);
    } catch (error) {
      logger.error('Failed to cleanup abandoned sessions', { error }, correlationId);
      throw error;
    }
  }

  /**
   * Start the cleanup job that runs every hour
   * Returns the interval ID so it can be stopped if needed
   */
  startCleanupJob(): NodeJS.Timeout {
    logger.info('Starting session cleanup job (runs every hour)');

    // Run cleanup immediately on start
    this.cleanupAbandonedSessions().catch(error => {
      logger.error('Initial cleanup failed', { error });
    });

    // Schedule to run every hour (3600000 ms)
    const intervalId = setInterval(() => {
      this.cleanupAbandonedSessions().catch(error => {
        logger.error('Scheduled cleanup failed', { error });
      });
    }, 60 * 60 * 1000);

    return intervalId;
  }

  /**
   * Stop the cleanup job
   */
  stopCleanupJob(intervalId: NodeJS.Timeout): void {
    clearInterval(intervalId);
    logger.info('Session cleanup job stopped');
  }

}

// Export singleton instance
export const sessionManager = new SessionManager(
  // Import configManager from ConfigManager module
  await import('./ConfigManager.js').then(m => m.configManager)
);
