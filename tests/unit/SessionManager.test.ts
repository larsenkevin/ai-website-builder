import { describe, it, expect, beforeEach, vi } from 'vitest';
import { SessionManager } from '../../app/services/SessionManager.js';
import { ConfigManager } from '../../app/services/ConfigManager.js';
import { PageConfig, TempConfig, Message } from '../../app/types/config.js';

// Mock ConfigManager
vi.mock('../../app/services/ConfigManager.js', () => {
  const mockConfigManager = {
    loadPageConfig: vi.fn(),
    saveTempConfig: vi.fn(),
    loadTempConfig: vi.fn(),
    copyTempToPage: vi.fn(),
    deleteTempConfig: vi.fn(),
    listTempConfigs: vi.fn(),
    getPublicTempConfigPath: vi.fn(),
    getFileStats: vi.fn(),
  };

  return {
    ConfigManager: vi.fn(() => mockConfigManager),
    configManager: mockConfigManager,
  };
});

describe('SessionManager', () => {
  let sessionManager: SessionManager;
  let mockConfigManager: any;

  const mockPageConfig: PageConfig = {
    id: 'test-page',
    title: 'Test Page',
    sections: [],
    metaDescription: 'Test description',
    keywords: ['test'],
    intent: {
      primaryGoal: 'Test goal',
      targetAudience: 'Test audience',
      callsToAction: [],
    },
    createdAt: '2024-01-01T00:00:00.000Z',
    lastModified: '2024-01-01T00:00:00.000Z',
    version: 1,
  };

  beforeEach(() => {
    // Reset mocks
    vi.clearAllMocks();

    // Create mock config manager
    mockConfigManager = {
      loadPageConfig: vi.fn(),
      saveTempConfig: vi.fn(),
      loadTempConfig: vi.fn(),
      copyTempToPage: vi.fn(),
      deleteTempConfig: vi.fn(),
      listTempConfigs: vi.fn(),
      getPublicTempConfigPath: vi.fn(),
      getFileStats: vi.fn(),
    };

    // Create session manager with mock
    sessionManager = new SessionManager(mockConfigManager);
  });

  describe('startEditing', () => {
    it('should create a new editing session', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      const session = await sessionManager.startEditing('test-page');

      expect(session.pageId).toBe('test-page');
      expect(session.sessionId).toBeDefined();
      expect(session.startedAt).toBeInstanceOf(Date);
      expect(session.tempConfig.conversationHistory).toEqual([]);
      expect(mockConfigManager.loadPageConfig).toHaveBeenCalledWith('test-page');
      expect(mockConfigManager.saveTempConfig).toHaveBeenCalled();
    });

    it('should throw error if session already exists', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('test-page');

      await expect(sessionManager.startEditing('test-page')).rejects.toThrow(
        'Page test-page is already being edited'
      );
    });

    it('should create temp config with session metadata', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('test-page');

      const savedTempConfig = mockConfigManager.saveTempConfig.mock.calls[0][0];
      expect(savedTempConfig.sessionId).toBeDefined();
      expect(savedTempConfig.startedAt).toBeDefined();
      expect(savedTempConfig.conversationHistory).toEqual([]);
      expect(savedTempConfig.id).toBe('test-page');
      expect(savedTempConfig.title).toBe('Test Page');
    });
  });

  describe('confirmChanges', () => {
    it('should copy temp config to page config and delete temp', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('test-page');
      await sessionManager.confirmChanges('test-page');

      expect(mockConfigManager.copyTempToPage).toHaveBeenCalledWith('test-page', undefined);
      expect(mockConfigManager.deleteTempConfig).toHaveBeenCalledWith('test-page', undefined);
      expect(sessionManager.hasActiveSession('test-page')).toBe(false);
    });

    it('should throw error if no active session', async () => {
      await expect(sessionManager.confirmChanges('test-page')).rejects.toThrow(
        'No active editing session for page: test-page'
      );
    });

    it('should remove session from memory after confirmation', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('test-page');
      expect(sessionManager.hasActiveSession('test-page')).toBe(true);

      await sessionManager.confirmChanges('test-page');
      expect(sessionManager.hasActiveSession('test-page')).toBe(false);
    });
  });

  describe('cancelChanges', () => {
    it('should delete temp config and preserve page config', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('test-page');
      await sessionManager.cancelChanges('test-page');

      expect(mockConfigManager.deleteTempConfig).toHaveBeenCalledWith('test-page', undefined);
      expect(mockConfigManager.copyTempToPage).not.toHaveBeenCalled();
      expect(sessionManager.hasActiveSession('test-page')).toBe(false);
    });

    it('should throw error if no active session', async () => {
      await expect(sessionManager.cancelChanges('test-page')).rejects.toThrow(
        'No active editing session for page: test-page'
      );
    });

    it('should remove session from memory after cancellation', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('test-page');
      expect(sessionManager.hasActiveSession('test-page')).toBe(true);

      await sessionManager.cancelChanges('test-page');
      expect(sessionManager.hasActiveSession('test-page')).toBe(false);
    });
  });

  describe('restoreSessions', () => {
    it('should restore sessions from temp config files', async () => {
      const mockTempConfig: TempConfig = {
        ...mockPageConfig,
        sessionId: 'restored-session-id',
        startedAt: '2024-01-01T00:00:00.000Z',
        conversationHistory: [],
      };

      mockConfigManager.listTempConfigs.mockResolvedValue(['test-page', 'another-page']);
      mockConfigManager.loadTempConfig.mockResolvedValue(mockTempConfig);

      await sessionManager.restoreSessions();

      expect(mockConfigManager.listTempConfigs).toHaveBeenCalled();
      expect(mockConfigManager.loadTempConfig).toHaveBeenCalledTimes(2);
      expect(sessionManager.hasActiveSession('test-page')).toBe(true);
      expect(sessionManager.hasActiveSession('another-page')).toBe(true);
    });

    it('should continue restoring even if one session fails', async () => {
      mockConfigManager.listTempConfigs.mockResolvedValue(['page1', 'page2', 'page3']);
      mockConfigManager.loadTempConfig
        .mockResolvedValueOnce({ ...mockPageConfig, id: 'page1', sessionId: 'session1', startedAt: '2024-01-01T00:00:00.000Z', conversationHistory: [] })
        .mockRejectedValueOnce(new Error('Failed to load page2'))
        .mockResolvedValueOnce({ ...mockPageConfig, id: 'page3', sessionId: 'session3', startedAt: '2024-01-01T00:00:00.000Z', conversationHistory: [] });

      await sessionManager.restoreSessions();

      expect(sessionManager.hasActiveSession('page1')).toBe(true);
      expect(sessionManager.hasActiveSession('page2')).toBe(false);
      expect(sessionManager.hasActiveSession('page3')).toBe(true);
    });
  });

  describe('getSession', () => {
    it('should return session if exists', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('test-page');
      const session = sessionManager.getSession('test-page');

      expect(session).toBeDefined();
      expect(session?.pageId).toBe('test-page');
    });

    it('should return undefined if session does not exist', () => {
      const session = sessionManager.getSession('non-existent');
      expect(session).toBeUndefined();
    });
  });

  describe('getAllSessions', () => {
    it('should return all active sessions', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('page1');
      await sessionManager.startEditing('page2');

      const sessions = sessionManager.getAllSessions();
      expect(sessions).toHaveLength(2);
      expect(sessions.map(s => s.pageId)).toContain('page1');
      expect(sessions.map(s => s.pageId)).toContain('page2');
    });

    it('should return empty array if no sessions', () => {
      const sessions = sessionManager.getAllSessions();
      expect(sessions).toEqual([]);
    });
  });

  describe('hasActiveSession', () => {
    it('should return true if session exists', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('test-page');
      expect(sessionManager.hasActiveSession('test-page')).toBe(true);
    });

    it('should return false if session does not exist', () => {
      expect(sessionManager.hasActiveSession('test-page')).toBe(false);
    });
  });

  describe('updateTempConfig', () => {
    it('should update temp config and save to file', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('test-page');

      const updates = {
        title: 'Updated Title',
        metaDescription: 'Updated description',
      };

      await sessionManager.updateTempConfig('test-page', updates);

      const session = sessionManager.getSession('test-page');
      expect(session?.tempConfig.title).toBe('Updated Title');
      expect(session?.tempConfig.metaDescription).toBe('Updated description');
      expect(mockConfigManager.saveTempConfig).toHaveBeenCalledTimes(2); // Once on start, once on update
    });

    it('should preserve required fields when updating', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('test-page');
      const originalSession = sessionManager.getSession('test-page');
      const originalSessionId = originalSession?.sessionId;
      const originalStartedAt = originalSession?.tempConfig.startedAt;

      await sessionManager.updateTempConfig('test-page', {
        title: 'New Title',
      });

      const updatedSession = sessionManager.getSession('test-page');
      expect(updatedSession?.sessionId).toBe(originalSessionId);
      expect(updatedSession?.tempConfig.startedAt).toBe(originalStartedAt);
      expect(updatedSession?.tempConfig.id).toBe('test-page');
    });

    it('should throw error if no active session', async () => {
      await expect(
        sessionManager.updateTempConfig('test-page', { title: 'New Title' })
      ).rejects.toThrow('No active editing session for page: test-page');
    });
  });

  describe('addMessage', () => {
    it('should add message to conversation history', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('test-page');

      const message: Message = {
        role: 'user',
        content: 'Hello AI',
        timestamp: '2024-01-01T00:00:00.000Z',
      };

      await sessionManager.addMessage('test-page', message);

      const session = sessionManager.getSession('test-page');
      expect(session?.tempConfig.conversationHistory).toHaveLength(1);
      expect(session?.tempConfig.conversationHistory[0]).toEqual(message);
    });

    it('should preserve existing messages when adding new ones', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      await sessionManager.startEditing('test-page');

      const message1: Message = {
        role: 'user',
        content: 'First message',
        timestamp: '2024-01-01T00:00:00.000Z',
      };

      const message2: Message = {
        role: 'assistant',
        content: 'Second message',
        timestamp: '2024-01-01T00:01:00.000Z',
      };

      await sessionManager.addMessage('test-page', message1);
      await sessionManager.addMessage('test-page', message2);

      const session = sessionManager.getSession('test-page');
      expect(session?.tempConfig.conversationHistory).toHaveLength(2);
      expect(session?.tempConfig.conversationHistory[0]).toEqual(message1);
      expect(session?.tempConfig.conversationHistory[1]).toEqual(message2);
    });

    it('should throw error if no active session', async () => {
      const message: Message = {
        role: 'user',
        content: 'Hello',
        timestamp: '2024-01-01T00:00:00.000Z',
      };

      await expect(sessionManager.addMessage('test-page', message)).rejects.toThrow(
        'No active editing session for page: test-page'
      );
    });
  });

  describe('session lifecycle', () => {
    it('should handle complete editing workflow', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      // Start editing
      const session = await sessionManager.startEditing('test-page');
      expect(sessionManager.hasActiveSession('test-page')).toBe(true);

      // Add messages
      await sessionManager.addMessage('test-page', {
        role: 'user',
        content: 'Create content',
        timestamp: new Date().toISOString(),
      });

      // Update content
      await sessionManager.updateTempConfig('test-page', {
        title: 'New Title',
      });

      // Confirm changes
      await sessionManager.confirmChanges('test-page');
      expect(sessionManager.hasActiveSession('test-page')).toBe(false);

      // Verify calls
      expect(mockConfigManager.loadPageConfig).toHaveBeenCalledWith('test-page');
      expect(mockConfigManager.saveTempConfig).toHaveBeenCalled();
      expect(mockConfigManager.copyTempToPage).toHaveBeenCalledWith('test-page', undefined);
      expect(mockConfigManager.deleteTempConfig).toHaveBeenCalledWith('test-page', undefined);
    });

    it('should handle cancellation workflow', async () => {
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);

      // Start editing
      await sessionManager.startEditing('test-page');

      // Make changes
      await sessionManager.updateTempConfig('test-page', {
        title: 'This will be discarded',
      });

      // Cancel
      await sessionManager.cancelChanges('test-page');
      expect(sessionManager.hasActiveSession('test-page')).toBe(false);

      // Verify temp was deleted but not copied
      expect(mockConfigManager.deleteTempConfig).toHaveBeenCalled();
      expect(mockConfigManager.copyTempToPage).not.toHaveBeenCalled();
    });
  });

  describe('cleanupAbandonedSessions', () => {
    it('should delete temp configs older than 24 hours', async () => {
      const now = Date.now();
      const twentyFiveHoursAgo = now - (25 * 60 * 60 * 1000);

      mockConfigManager.listTempConfigs.mockResolvedValue(['old-page', 'new-page']);
      mockConfigManager.getPublicTempConfigPath.mockImplementation((pageId: string) => `/config/pages/${pageId}.temp.json`);
      
      // Mock file stats - old-page is 25 hours old, new-page is 1 hour old
      mockConfigManager.getFileStats.mockImplementation((path: string) => {
        if (path.includes('old-page')) {
          return Promise.resolve({ mtimeMs: twentyFiveHoursAgo });
        } else {
          return Promise.resolve({ mtimeMs: now - (60 * 60 * 1000) });
        }
      });

      await sessionManager.cleanupAbandonedSessions();

      // Should only delete the old page
      expect(mockConfigManager.deleteTempConfig).toHaveBeenCalledTimes(1);
      expect(mockConfigManager.deleteTempConfig).toHaveBeenCalledWith('old-page', undefined);
    });

    it('should remove sessions from memory when cleaning up', async () => {
      const now = Date.now();
      const twentyFiveHoursAgo = now - (25 * 60 * 60 * 1000);

      // Start a session
      mockConfigManager.loadPageConfig.mockResolvedValue(mockPageConfig);
      await sessionManager.startEditing('old-page');
      expect(sessionManager.hasActiveSession('old-page')).toBe(true);

      // Mock cleanup
      mockConfigManager.listTempConfigs.mockResolvedValue(['old-page']);
      mockConfigManager.getPublicTempConfigPath.mockReturnValue('/config/pages/old-page.temp.json');
      mockConfigManager.getFileStats.mockResolvedValue({ mtimeMs: twentyFiveHoursAgo });

      await sessionManager.cleanupAbandonedSessions();

      // Session should be removed from memory
      expect(sessionManager.hasActiveSession('old-page')).toBe(false);
    });

    it('should not delete temp configs newer than 24 hours', async () => {
      const now = Date.now();
      const oneHourAgo = now - (60 * 60 * 1000);

      mockConfigManager.listTempConfigs.mockResolvedValue(['new-page']);
      mockConfigManager.getPublicTempConfigPath.mockReturnValue('/config/pages/new-page.temp.json');
      mockConfigManager.getFileStats.mockResolvedValue({ mtimeMs: oneHourAgo });

      await sessionManager.cleanupAbandonedSessions();

      // Should not delete anything
      expect(mockConfigManager.deleteTempConfig).not.toHaveBeenCalled();
    });

    it('should continue cleanup even if one file fails', async () => {
      const now = Date.now();
      const twentyFiveHoursAgo = now - (25 * 60 * 60 * 1000);

      mockConfigManager.listTempConfigs.mockResolvedValue(['page1', 'page2', 'page3']);
      mockConfigManager.getPublicTempConfigPath.mockImplementation((pageId: string) => `/config/pages/${pageId}.temp.json`);
      
      mockConfigManager.getFileStats.mockImplementation((path: string) => {
        if (path.includes('page2')) {
          return Promise.reject(new Error('File access error'));
        }
        return Promise.resolve({ mtimeMs: twentyFiveHoursAgo });
      });

      await sessionManager.cleanupAbandonedSessions();

      // Should delete page1 and page3, but skip page2
      expect(mockConfigManager.deleteTempConfig).toHaveBeenCalledTimes(2);
      expect(mockConfigManager.deleteTempConfig).toHaveBeenCalledWith('page1', undefined);
      expect(mockConfigManager.deleteTempConfig).toHaveBeenCalledWith('page3', undefined);
    });

    it('should handle missing temp config files gracefully', async () => {
      mockConfigManager.listTempConfigs.mockResolvedValue(['missing-page']);
      mockConfigManager.getPublicTempConfigPath.mockReturnValue('/config/pages/missing-page.temp.json');
      mockConfigManager.getFileStats.mockResolvedValue(null);

      await sessionManager.cleanupAbandonedSessions();

      // Should not attempt to delete
      expect(mockConfigManager.deleteTempConfig).not.toHaveBeenCalled();
    });
  });

  describe('startCleanupJob', () => {
    it('should return an interval ID', () => {
      const intervalId = sessionManager.startCleanupJob();
      expect(intervalId).toBeDefined();
      
      // Clean up
      sessionManager.stopCleanupJob(intervalId);
    });

    it('should run cleanup immediately on start', async () => {
      mockConfigManager.listTempConfigs.mockResolvedValue([]);
      
      const intervalId = sessionManager.startCleanupJob();
      
      // Wait a bit for the immediate cleanup to run
      await new Promise(resolve => setTimeout(resolve, 100));
      
      expect(mockConfigManager.listTempConfigs).toHaveBeenCalled();
      
      // Clean up
      sessionManager.stopCleanupJob(intervalId);
    });
  });

  describe('stopCleanupJob', () => {
    it('should stop the cleanup job', () => {
      const intervalId = sessionManager.startCleanupJob();
      
      // Should not throw
      expect(() => sessionManager.stopCleanupJob(intervalId)).not.toThrow();
    });
  });
});

