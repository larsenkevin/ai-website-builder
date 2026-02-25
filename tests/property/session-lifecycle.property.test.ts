import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fc from 'fast-check';
import { SessionManager } from '../../app/services/SessionManager.js';
import { ConfigManager } from '../../app/services/ConfigManager.js';
import { PageConfig, TempConfig, Message } from '../../app/types/config.js';
import fs from 'fs/promises';
import path from 'path';

/**
 * Property-Based Tests for Session Lifecycle
 * 
 * These tests validate the session management system using property-based testing
 * to ensure correctness across a wide range of inputs and scenarios.
 */

describe('Session Lifecycle Property Tests', () => {
  const testConfigDir = './test-session-property';
  let configManager: ConfigManager;
  let sessionManager: SessionManager;

  beforeEach(async () => {
    // Clean up any existing test directory first
    try {
      await fs.rm(testConfigDir, { recursive: true, force: true });
    } catch (error) {
      // Ignore cleanup errors
    }
    
    await fs.mkdir(testConfigDir, { recursive: true });
    await fs.mkdir(path.join(testConfigDir, 'pages'), { recursive: true });
    configManager = new ConfigManager({ configDir: testConfigDir });
    sessionManager = new SessionManager(configManager);
  });

  afterEach(async () => {
    try {
      await fs.rm(testConfigDir, { recursive: true, force: true });
    } catch (error) {
      // Ignore cleanup errors
    }
  });

  // Custom arbitraries for generating valid config objects
  const pageIntentArbitrary = fc.record({
    primaryGoal: fc.string({ minLength: 1, maxLength: 200 }),
    targetAudience: fc.string({ minLength: 1, maxLength: 200 }),
    callsToAction: fc.array(fc.string({ minLength: 1, maxLength: 100 }), { minLength: 0, maxLength: 5 }),
  });

  const contentSectionArbitrary = fc.record({
    type: fc.constantFrom('hero', 'text', 'image', 'gallery', 'contact-form', 'cta'),
    id: fc.string({ minLength: 1, maxLength: 50 }),
    order: fc.integer({ min: 1, max: 100 }),
    content: fc.record({
      headline: fc.string({ minLength: 0, maxLength: 200 }),
      body: fc.string({ minLength: 0, maxLength: 1000 }),
    }),
  });

  const pageConfigArbitrary = fc.record({
    id: fc.string({ minLength: 1, maxLength: 50 }).map(s => s.replace(/[^a-z0-9-]/gi, '-').toLowerCase()),
    title: fc.string({ minLength: 1, maxLength: 200 }),
    sections: fc.array(contentSectionArbitrary, { minLength: 0, maxLength: 10 }),
    metaDescription: fc.string({ minLength: 1, maxLength: 500 }),
    keywords: fc.array(fc.string({ minLength: 1, maxLength: 50 }), { minLength: 0, maxLength: 20 }),
    featuredImage: fc.option(fc.constant('/assets/featured.jpg'), { nil: undefined }),
    intent: pageIntentArbitrary,
    createdAt: fc.date().map(d => d.toISOString()),
    lastModified: fc.date().map(d => d.toISOString()),
    version: fc.integer({ min: 1, max: 100 }),
  });

  const messageArbitrary = fc.record({
    role: fc.constantFrom('user', 'assistant'),
    content: fc.string({ minLength: 1, maxLength: 1000 }),
    timestamp: fc.date().map(d => d.toISOString()),
  });

  /**
   * Property 2: Temp Config Preserves Original
   * 
   * For any page, when editing begins, the original Page_Config SHALL remain 
   * unchanged while modifications are saved to Temp_Config.
   * 
   * **Validates: Requirements 4.5, 11.3**
   */
  describe('Property 2: Temp Config Preserves Original', () => {
    it('Property: Starting editing preserves original page config', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (originalConfig) => {
          // Make ID unique for this test iteration
          const uniqueId = `${originalConfig.id}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
          const config = { ...originalConfig, id: uniqueId } as PageConfig;
          
          // Save the original page config
          await configManager.savePageConfig(config);

          // Load it to get the actual saved version
          const savedOriginal = await configManager.loadPageConfig(config.id);

          // Start editing session
          await sessionManager.startEditing(config.id);

          // Load the original page config again
          const afterEditStart = await configManager.loadPageConfig(config.id);

          // Original page config should be unchanged
          expect(afterEditStart).toEqual(savedOriginal);
          
          // Cleanup
          await sessionManager.cancelChanges(config.id);
        }),
        { numRuns: 20 }
      );
    });

    it('Property: Modifications during editing do not affect original page config', async () => {
      await fc.assert(
        fc.asyncProperty(
          pageConfigArbitrary,
          fc.string({ minLength: 1, maxLength: 200 }),
          async (originalConfig, newTitle) => {
            // Make ID unique for this test iteration
            const uniqueId = `${originalConfig.id}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
            const config = { ...originalConfig, id: uniqueId } as PageConfig;
            
            // Save the original page config
            await configManager.savePageConfig(config);
            const savedOriginal = await configManager.loadPageConfig(config.id);

            // Start editing session
            await sessionManager.startEditing(config.id);

            // Modify the temp config
            await sessionManager.updateTempConfig(config.id, { title: newTitle });

            // Load the original page config
            const afterModification = await configManager.loadPageConfig(config.id);

            // Original should still be unchanged
            expect(afterModification).toEqual(savedOriginal);
            expect(afterModification.title).toBe(savedOriginal.title);
            expect(afterModification.title).not.toBe(newTitle);
            
            // Cleanup
            await sessionManager.cancelChanges(config.id);
          }
        ),
        { numRuns: 20 }
      );
    });
  });

  /**
   * Property 13: Session Lifecycle - Start
   * 
   * For any page, starting an editing session SHALL create a Temp_Config file 
   * and preserve the original Page_Config.
   * 
   * **Validates: Requirements 11.1, 11.3**
   */
  describe('Property 13: Session Lifecycle - Start', () => {
    it('Property: Starting session creates temp config file', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (originalConfig) => {
          // Make ID unique for this test iteration
          const uniqueId = `${originalConfig.id}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
          const config = { ...originalConfig, id: uniqueId } as PageConfig;
          
          // Save the original page config
          await configManager.savePageConfig(config);

          // Start editing session
          const session = await sessionManager.startEditing(config.id);

          // Verify temp config file exists
          const tempConfigPath = path.join(testConfigDir, 'pages', `${config.id}.temp.json`);
          const tempConfigExists = await fs.access(tempConfigPath).then(() => true).catch(() => false);
          expect(tempConfigExists).toBe(true);

          // Verify session was created
          expect(session.pageId).toBe(config.id);
          expect(session.sessionId).toBeDefined();
          expect(session.startedAt).toBeInstanceOf(Date);
          
          // Cleanup
          await sessionManager.cancelChanges(config.id);
        }),
        { numRuns: 20 }
      );
    });

    it('Property: Temp config contains all original page data', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (originalConfig) => {
          // Make ID unique for this test iteration
          const uniqueId = `${originalConfig.id}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
          const config = { ...originalConfig, id: uniqueId } as PageConfig;
          
          // Save the original page config
          await configManager.savePageConfig(config);
          const savedOriginal = await configManager.loadPageConfig(config.id);

          // Start editing session
          await sessionManager.startEditing(config.id);

          // Load temp config
          const tempConfig = await configManager.loadTempConfig(config.id);

          // Temp config should contain all original data
          expect(tempConfig.id).toBe(savedOriginal.id);
          expect(tempConfig.title).toBe(savedOriginal.title);
          expect(tempConfig.sections).toEqual(savedOriginal.sections);
          expect(tempConfig.metaDescription).toBe(savedOriginal.metaDescription);
          expect(tempConfig.keywords).toEqual(savedOriginal.keywords);
          expect(tempConfig.intent).toEqual(savedOriginal.intent);
          
          // Cleanup
          await sessionManager.cancelChanges(config.id);
        }),
        { numRuns: 20 }
      );
    });

    it('Property: Cannot start session if one already exists', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (originalConfig) => {
          // Make ID unique for this test iteration
          const uniqueId = `${originalConfig.id}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
          const config = { ...originalConfig, id: uniqueId } as PageConfig;
          
          // Save the original page config
          await configManager.savePageConfig(config);

          // Start first session
          await sessionManager.startEditing(config.id);

          // Attempting to start second session should fail
          await expect(sessionManager.startEditing(config.id)).rejects.toThrow();
          
          // Cleanup
          await sessionManager.cancelChanges(config.id);
        }),
        { numRuns: 20 }
      );
    });
  });

  /**
   * Property 14: Session Lifecycle - Modification
   * 
   * For any editing session, all content modifications SHALL be saved to 
   * Temp_Config and NOT to Page_Config.
   * 
   * **Validates: Requirements 11.2**
   */
  describe('Property 14: Session Lifecycle - Modification', () => {
    it('Property: Modifications are saved to temp config only', async () => {
      await fc.assert(
        fc.asyncProperty(
          pageConfigArbitrary,
          fc.record({
            title: fc.string({ minLength: 1, maxLength: 200 }),
            metaDescription: fc.string({ minLength: 1, maxLength: 500 }),
          }),
          async (originalConfig, updates) => {
            // Make ID unique for this test iteration
            const uniqueId = `${originalConfig.id}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
            const config = { ...originalConfig, id: uniqueId } as PageConfig;
            
            // Save the original page config
            await configManager.savePageConfig(config);
            const savedOriginal = await configManager.loadPageConfig(config.id);

            // Start editing session
            await sessionManager.startEditing(config.id);

            // Make modifications
            await sessionManager.updateTempConfig(config.id, updates);

            // Load both configs
            const pageConfig = await configManager.loadPageConfig(config.id);
            const tempConfig = await configManager.loadTempConfig(config.id);

            // Page config should be unchanged
            expect(pageConfig.title).toBe(savedOriginal.title);
            expect(pageConfig.metaDescription).toBe(savedOriginal.metaDescription);

            // Temp config should have updates
            expect(tempConfig.title).toBe(updates.title);
            expect(tempConfig.metaDescription).toBe(updates.metaDescription);
            
            // Cleanup
            await sessionManager.cancelChanges(config.id);
          }
        ),
        { numRuns: 20 }
      );
    });

    it('Property: Multiple modifications accumulate in temp config', async () => {
      await fc.assert(
        fc.asyncProperty(
          pageConfigArbitrary,
          fc.array(fc.string({ minLength: 1, maxLength: 200 }), { minLength: 2, maxLength: 5 }),
          async (originalConfig, titles) => {
            // Make ID unique for this test iteration
            const uniqueId = `${originalConfig.id}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
            const config = { ...originalConfig, id: uniqueId } as PageConfig;
            
            // Save the original page config
            await configManager.savePageConfig(config);

            // Start editing session
            await sessionManager.startEditing(config.id);

            // Apply multiple modifications
            for (const title of titles) {
              await sessionManager.updateTempConfig(config.id, { title });
            }

            // Load temp config
            const tempConfig = await configManager.loadTempConfig(config.id);

            // Should have the last modification
            expect(tempConfig.title).toBe(titles[titles.length - 1]);
            
            // Cleanup
            await sessionManager.cancelChanges(config.id);
          }
        ),
        { numRuns: 20 }
      );
    });
  });

  /**
   * Property 15: Session Lifecycle - Cleanup
   * 
   * For any Temp_Config file older than 24 hours without an active session, 
   * the cleanup process SHALL delete the file.
   * 
   * **Validates: Requirements 11.4**
   */
  describe('Property 15: Session Lifecycle - Cleanup', () => {
    it('Property: Cleanup deletes temp configs older than 24 hours', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.array(pageConfigArbitrary, { minLength: 1, maxLength: 5 }),
          async (configs) => {
            // Create temp configs with old timestamps
            for (const config of configs) {
              await configManager.savePageConfig(config as PageConfig);
              await sessionManager.startEditing(config.id);
              
              // Manually set file modification time to 25 hours ago
              const tempConfigPath = path.join(testConfigDir, 'pages', `${config.id}.temp.json`);
              const twentyFiveHoursAgo = new Date(Date.now() - 25 * 60 * 60 * 1000);
              await fs.utimes(tempConfigPath, twentyFiveHoursAgo, twentyFiveHoursAgo);
            }

            // Run cleanup
            await sessionManager.cleanupAbandonedSessions();

            // All temp configs should be deleted
            for (const config of configs) {
              const tempConfigPath = path.join(testConfigDir, 'pages', `${config.id}.temp.json`);
              const exists = await fs.access(tempConfigPath).then(() => true).catch(() => false);
              expect(exists).toBe(false);
            }
          }
        ),
        { numRuns: 10 }
      );
    });

    it('Property: Cleanup preserves temp configs newer than 24 hours', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.array(pageConfigArbitrary, { minLength: 1, maxLength: 5 }),
          async (configs) => {
            // Create temp configs with recent timestamps
            const uniqueConfigs = configs.map((config, idx) => ({
              ...config,
              id: `${config.id}-${Date.now()}-${idx}-${Math.random().toString(36).substr(2, 9)}`
            }));
            
            for (const config of uniqueConfigs) {
              await configManager.savePageConfig(config as PageConfig);
              await sessionManager.startEditing(config.id);
            }

            // Run cleanup
            await sessionManager.cleanupAbandonedSessions();

            // All temp configs should still exist
            for (const config of uniqueConfigs) {
              const tempConfigPath = path.join(testConfigDir, 'pages', `${config.id}.temp.json`);
              const exists = await fs.access(tempConfigPath).then(() => true).catch(() => false);
              expect(exists).toBe(true);
              
              // Cleanup
              await sessionManager.cancelChanges(config.id);
            }
          }
        ),
        { numRuns: 10 }
      );
    });
  });

  /**
   * Property 16: Session Lifecycle - Restoration
   * 
   * For any page with an existing Temp_Config file, starting an editing session 
   * SHALL load the Temp_Config content.
   * 
   * **Validates: Requirements 11.5**
   */
  describe('Property 16: Session Lifecycle - Restoration', () => {
    it('Property: Restoring sessions loads temp config content', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.array(pageConfigArbitrary, { minLength: 1, maxLength: 5 }),
          async (configs) => {
            // Create sessions and temp configs with unique IDs
            const uniqueConfigs = configs.map((config, idx) => ({
              ...config,
              id: `${config.id}-${Date.now()}-${idx}-${Math.random().toString(36).substr(2, 9)}`
            }));
            
            const sessionIds: string[] = [];
            for (const config of uniqueConfigs) {
              await configManager.savePageConfig(config as PageConfig);
              const session = await sessionManager.startEditing(config.id);
              sessionIds.push(session.sessionId);
            }

            // Clear in-memory sessions (simulating server restart)
            const newSessionManager = new SessionManager(configManager);

            // Restore sessions
            await newSessionManager.restoreSessions();

            // All sessions should be restored
            for (let i = 0; i < uniqueConfigs.length; i++) {
              const config = uniqueConfigs[i];
              const restoredSession = newSessionManager.getSession(config.id);
              expect(restoredSession).toBeDefined();
              expect(restoredSession?.pageId).toBe(config.id);
              expect(restoredSession?.sessionId).toBe(sessionIds[i]);
              
              // Cleanup
              await newSessionManager.cancelChanges(config.id);
            }
          }
        ),
        { numRuns: 10 }
      );
    });

    it('Property: Restored session contains conversation history', async () => {
      await fc.assert(
        fc.asyncProperty(
          pageConfigArbitrary,
          fc.array(messageArbitrary, { minLength: 1, maxLength: 10 }),
          async (originalConfig, messages) => {
            // Make ID unique for this test iteration
            const uniqueId = `${originalConfig.id}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
            const config = { ...originalConfig, id: uniqueId } as PageConfig;
            
            // Create session and add messages
            await configManager.savePageConfig(config);
            await sessionManager.startEditing(config.id);
            
            for (const message of messages) {
              await sessionManager.addMessage(config.id, message as Message);
            }

            // Clear in-memory sessions
            const newSessionManager = new SessionManager(configManager);

            // Restore sessions
            await newSessionManager.restoreSessions();

            // Restored session should have conversation history
            const restoredSession = newSessionManager.getSession(config.id);
            expect(restoredSession?.tempConfig.conversationHistory).toHaveLength(messages.length);
            expect(restoredSession?.tempConfig.conversationHistory).toEqual(messages);
            
            // Cleanup
            await newSessionManager.cancelChanges(config.id);
          }
        ),
        { numRuns: 10 }
      );
    });
  });

  /**
   * Property 17: Session Lifecycle - Confirmation
   * 
   * For any editing session, confirming changes SHALL copy Temp_Config to 
   * Page_Config and delete the Temp_Config file.
   * 
   * **Validates: Requirements 12.3, 12.4**
   */
  describe('Property 17: Session Lifecycle - Confirmation', () => {
    it('Property: Confirming changes copies temp to page config', async () => {
      await fc.assert(
        fc.asyncProperty(
          pageConfigArbitrary,
          fc.record({
            title: fc.string({ minLength: 1, maxLength: 200 }),
            metaDescription: fc.string({ minLength: 1, maxLength: 500 }),
          }),
          async (originalConfig, updates) => {
            // Save the original page config
            await configManager.savePageConfig(originalConfig as PageConfig);

            // Start editing and make changes
            await sessionManager.startEditing(originalConfig.id);
            await sessionManager.updateTempConfig(originalConfig.id, updates);

            // Confirm changes
            await sessionManager.confirmChanges(originalConfig.id);

            // Load page config
            const pageConfig = await configManager.loadPageConfig(originalConfig.id);

            // Page config should have the updates
            expect(pageConfig.title).toBe(updates.title);
            expect(pageConfig.metaDescription).toBe(updates.metaDescription);
          }
        ),
        { numRuns: 20 }
      );
    });

    it('Property: Confirming changes deletes temp config file', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (originalConfig) => {
          // Save the original page config
          await configManager.savePageConfig(originalConfig as PageConfig);

          // Start editing
          await sessionManager.startEditing(originalConfig.id);

          // Confirm changes
          await sessionManager.confirmChanges(originalConfig.id);

          // Temp config should not exist
          const tempConfigPath = path.join(testConfigDir, 'pages', `${originalConfig.id}.temp.json`);
          const exists = await fs.access(tempConfigPath).then(() => true).catch(() => false);
          expect(exists).toBe(false);
        }),
        { numRuns: 20 }
      );
    });

    it('Property: Confirming changes removes session from memory', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (originalConfig) => {
          // Save the original page config
          await configManager.savePageConfig(originalConfig as PageConfig);

          // Start editing
          await sessionManager.startEditing(originalConfig.id);
          expect(sessionManager.hasActiveSession(originalConfig.id)).toBe(true);

          // Confirm changes
          await sessionManager.confirmChanges(originalConfig.id);

          // Session should not exist in memory
          expect(sessionManager.hasActiveSession(originalConfig.id)).toBe(false);
        }),
        { numRuns: 20 }
      );
    });
  });

  /**
   * Property 18: Session Lifecycle - Cancellation
   * 
   * For any editing session, canceling changes SHALL delete the Temp_Config file 
   * and preserve the original Page_Config unchanged.
   * 
   * **Validates: Requirements 12.5**
   */
  describe('Property 18: Session Lifecycle - Cancellation', () => {
    it('Property: Canceling changes preserves original page config', async () => {
      await fc.assert(
        fc.asyncProperty(
          pageConfigArbitrary,
          fc.record({
            title: fc.string({ minLength: 1, maxLength: 200 }),
            metaDescription: fc.string({ minLength: 1, maxLength: 500 }),
          }),
          async (originalConfig, updates) => {
            // Save the original page config
            await configManager.savePageConfig(originalConfig as PageConfig);
            const savedOriginal = await configManager.loadPageConfig(originalConfig.id);

            // Start editing and make changes
            await sessionManager.startEditing(originalConfig.id);
            await sessionManager.updateTempConfig(originalConfig.id, updates);

            // Cancel changes
            await sessionManager.cancelChanges(originalConfig.id);

            // Load page config
            const pageConfig = await configManager.loadPageConfig(originalConfig.id);

            // Page config should be unchanged
            expect(pageConfig.title).toBe(savedOriginal.title);
            expect(pageConfig.metaDescription).toBe(savedOriginal.metaDescription);
            expect(pageConfig).toEqual(savedOriginal);
          }
        ),
        { numRuns: 20 }
      );
    });

    it('Property: Canceling changes deletes temp config file', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (originalConfig) => {
          // Save the original page config
          await configManager.savePageConfig(originalConfig as PageConfig);

          // Start editing
          await sessionManager.startEditing(originalConfig.id);

          // Cancel changes
          await sessionManager.cancelChanges(originalConfig.id);

          // Temp config should not exist
          const tempConfigPath = path.join(testConfigDir, 'pages', `${originalConfig.id}.temp.json`);
          const exists = await fs.access(tempConfigPath).then(() => true).catch(() => false);
          expect(exists).toBe(false);
        }),
        { numRuns: 20 }
      );
    });

    it('Property: Canceling changes removes session from memory', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (originalConfig) => {
          // Save the original page config
          await configManager.savePageConfig(originalConfig as PageConfig);

          // Start editing
          await sessionManager.startEditing(originalConfig.id);
          expect(sessionManager.hasActiveSession(originalConfig.id)).toBe(true);

          // Cancel changes
          await sessionManager.cancelChanges(originalConfig.id);

          // Session should not exist in memory
          expect(sessionManager.hasActiveSession(originalConfig.id)).toBe(false);
        }),
        { numRuns: 20 }
      );
    });
  });

  /**
   * Additional Property: Complete Session Lifecycle
   * 
   * Tests the entire lifecycle from start to finish with various paths
   */
  describe('Complete Session Lifecycle', () => {
    it('Property: Complete workflow with confirmation preserves changes', async () => {
      await fc.assert(
        fc.asyncProperty(
          pageConfigArbitrary,
          fc.array(messageArbitrary, { minLength: 1, maxLength: 5 }),
          fc.string({ minLength: 1, maxLength: 200 }),
          async (originalConfig, messages, newTitle) => {
            // Save original
            await configManager.savePageConfig(originalConfig as PageConfig);

            // Start editing
            await sessionManager.startEditing(originalConfig.id);

            // Add messages
            for (const message of messages) {
              await sessionManager.addMessage(originalConfig.id, message as Message);
            }

            // Update content
            await sessionManager.updateTempConfig(originalConfig.id, { title: newTitle });

            // Confirm
            await sessionManager.confirmChanges(originalConfig.id);

            // Verify final state
            const finalConfig = await configManager.loadPageConfig(originalConfig.id);
            expect(finalConfig.title).toBe(newTitle);
            expect(sessionManager.hasActiveSession(originalConfig.id)).toBe(false);
          }
        ),
        { numRuns: 15 }
      );
    });

    it('Property: Complete workflow with cancellation discards changes', async () => {
      await fc.assert(
        fc.asyncProperty(
          pageConfigArbitrary,
          fc.array(messageArbitrary, { minLength: 1, maxLength: 5 }),
          fc.string({ minLength: 1, maxLength: 200 }),
          async (originalConfig, messages, newTitle) => {
            // Save original
            await configManager.savePageConfig(originalConfig as PageConfig);
            const savedOriginal = await configManager.loadPageConfig(originalConfig.id);

            // Start editing
            await sessionManager.startEditing(originalConfig.id);

            // Add messages
            for (const message of messages) {
              await sessionManager.addMessage(originalConfig.id, message as Message);
            }

            // Update content
            await sessionManager.updateTempConfig(originalConfig.id, { title: newTitle });

            // Cancel
            await sessionManager.cancelChanges(originalConfig.id);

            // Verify final state
            const finalConfig = await configManager.loadPageConfig(originalConfig.id);
            expect(finalConfig).toEqual(savedOriginal);
            expect(finalConfig.title).toBe(savedOriginal.title);
            expect(sessionManager.hasActiveSession(originalConfig.id)).toBe(false);
          }
        ),
        { numRuns: 15 }
      );
    });
  });
});
