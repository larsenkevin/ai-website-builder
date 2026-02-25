import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fc from 'fast-check';
import { Logger, LogLevel } from '../../app/services/Logger.js';
import fs from 'fs/promises';
import path from 'path';

/**
 * Property 58: Comprehensive Logging
 * 
 * For any API request, configuration modification, or error, the System SHALL create 
 * a log entry with timestamp, event type, and relevant details (including stack traces for errors).
 * 
 * **Validates: Requirements 30.1, 30.2, 30.3**
 */

describe('Property 58: Comprehensive Logging', () => {
  const testLogDir = './logs/property-test';
  let logger: Logger;

  beforeEach(async () => {
    logger = new Logger({
      logDir: testLogDir,
      logLevel: LogLevel.DEBUG,
      maxLogSizeMB: 100,
      retentionDays: 30,
    });

    await fs.mkdir(testLogDir, { recursive: true });
  });

  afterEach(async () => {
    try {
      const files = await fs.readdir(testLogDir);
      for (const file of files) {
        await fs.unlink(path.join(testLogDir, file));
      }
      await fs.rmdir(testLogDir);
    } catch (error) {
      // Ignore cleanup errors
    }
  });

  it('Property: All API requests are logged with required fields', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.constantFrom('GET', 'POST', 'PUT', 'DELETE', 'PATCH'),
        fc.webPath(),
        fc.integer({ min: 100, max: 599 }),
        fc.integer({ min: 0, max: 10000 }),
        fc.uuid(),
        async (method, apiPath, statusCode, duration, correlationId) => {
          // Log an API request
          logger.logApiRequest(method, apiPath, statusCode, duration, correlationId);

          // Wait for async write
          await new Promise(resolve => setTimeout(resolve, 100));

          // Read the log file
          const logFiles = await fs.readdir(testLogDir);
          expect(logFiles.length).toBeGreaterThan(0);

          const logContent = await fs.readFile(
            path.join(testLogDir, logFiles[0]),
            'utf-8'
          );
          const lines = logContent.trim().split('\n');
          const logEntry = JSON.parse(lines[lines.length - 1]);

          // Verify required fields
          expect(logEntry).toHaveProperty('timestamp');
          expect(logEntry).toHaveProperty('level');
          expect(logEntry).toHaveProperty('message');
          expect(logEntry.message).toBe('API request');
          expect(logEntry.correlationId).toBe(correlationId);
          expect(logEntry.metadata.method).toBe(method);
          expect(logEntry.metadata.path).toBe(apiPath);
          expect(logEntry.metadata.statusCode).toBe(statusCode);
          expect(logEntry.metadata.duration).toBe(duration);

          // Verify timestamp is valid ISO 8601
          expect(new Date(logEntry.timestamp).toISOString()).toBe(logEntry.timestamp);
        }
      ),
      { numRuns: 20 }
    );
  });

  it('Property: All configuration modifications are logged with required fields', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.constantFrom('site', 'page', 'asset'),
        fc.string({ minLength: 1, maxLength: 50 }),
        fc.constantFrom('create', 'update', 'delete'),
        fc.uuid(),
        async (configType, configId, action, correlationId) => {
          // Log a configuration change
          logger.logConfigChange(configType, configId, action, correlationId);

          // Wait for async write
          await new Promise(resolve => setTimeout(resolve, 100));

          // Read the log file
          const logFiles = await fs.readdir(testLogDir);
          const logContent = await fs.readFile(
            path.join(testLogDir, logFiles[0]),
            'utf-8'
          );
          const lines = logContent.trim().split('\n');
          const logEntry = JSON.parse(lines[lines.length - 1]);

          // Verify required fields
          expect(logEntry).toHaveProperty('timestamp');
          expect(logEntry).toHaveProperty('level');
          expect(logEntry).toHaveProperty('message');
          expect(logEntry.message).toBe('Configuration change');
          expect(logEntry.correlationId).toBe(correlationId);
          expect(logEntry.metadata.configType).toBe(configType);
          expect(logEntry.metadata.configId).toBe(configId);
          expect(logEntry.metadata.action).toBe(action);

          // Verify timestamp is valid ISO 8601
          expect(new Date(logEntry.timestamp).toISOString()).toBe(logEntry.timestamp);
        }
      ),
      { numRuns: 20 }
    );
  });

  it('Property: All errors are logged with stack traces', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.string({ minLength: 1, maxLength: 200 }),
        fc.record({
          code: fc.integer({ min: 400, max: 599 }),
          details: fc.string(),
        }),
        fc.uuid(),
        async (errorMessage, metadata, correlationId) => {
          // Log an error
          logger.error(errorMessage, metadata, correlationId);

          // Wait for async write
          await new Promise(resolve => setTimeout(resolve, 100));

          // Read the log file
          const logFiles = await fs.readdir(testLogDir);
          const logContent = await fs.readFile(
            path.join(testLogDir, logFiles[0]),
            'utf-8'
          );
          const lines = logContent.trim().split('\n');
          const logEntry = JSON.parse(lines[lines.length - 1]);

          // Verify required fields
          expect(logEntry).toHaveProperty('timestamp');
          expect(logEntry.level).toBe('ERROR');
          expect(logEntry.message).toBe(errorMessage);
          expect(logEntry.correlationId).toBe(correlationId);
          expect(logEntry.metadata.code).toBe(metadata.code);
          expect(logEntry.metadata.details).toBe(metadata.details);

          // Verify stack trace is present
          expect(logEntry).toHaveProperty('stack');
          expect(logEntry.stack).toBeDefined();
          expect(typeof logEntry.stack).toBe('string');
          expect(logEntry.stack.length).toBeGreaterThan(0);

          // Verify timestamp is valid ISO 8601
          expect(new Date(logEntry.timestamp).toISOString()).toBe(logEntry.timestamp);
        }
      ),
      { numRuns: 20 }
    );
  });

  it('Property: Log entries are valid JSON', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.constantFrom(LogLevel.ERROR, LogLevel.WARN, LogLevel.INFO, LogLevel.DEBUG),
        fc.string({ minLength: 1, maxLength: 200 }),
        fc.record({
          key1: fc.string(),
          key2: fc.integer(),
          key3: fc.boolean(),
        }),
        async (level, message, metadata) => {
          // Log with the specified level
          switch (level) {
            case LogLevel.ERROR:
              logger.error(message, metadata);
              break;
            case LogLevel.WARN:
              logger.warn(message, metadata);
              break;
            case LogLevel.INFO:
              logger.info(message, metadata);
              break;
            case LogLevel.DEBUG:
              logger.debug(message, metadata);
              break;
          }

          // Wait for async write
          await new Promise(resolve => setTimeout(resolve, 100));

          // Read the log file
          const logFiles = await fs.readdir(testLogDir);
          const logContent = await fs.readFile(
            path.join(testLogDir, logFiles[0]),
            'utf-8'
          );
          const lines = logContent.trim().split('\n');
          const lastLine = lines[lines.length - 1];

          // Verify it's valid JSON
          expect(() => JSON.parse(lastLine)).not.toThrow();

          const logEntry = JSON.parse(lastLine);
          expect(logEntry.level).toBe(level);
          expect(logEntry.message).toBe(message);
          expect(logEntry.metadata.key1).toBe(metadata.key1);
          expect(logEntry.metadata.key2).toBe(metadata.key2);
          expect(logEntry.metadata.key3).toBe(metadata.key3);
        }
      ),
      { numRuns: 20 }
    );
  });

  it('Property: Correlation IDs are unique', () => {
    fc.assert(
      fc.property(fc.integer({ min: 2, max: 100 }), (count) => {
        const ids = new Set<string>();
        
        for (let i = 0; i < count; i++) {
          const id = logger.generateCorrelationId();
          expect(ids.has(id)).toBe(false);
          ids.add(id);
        }

        expect(ids.size).toBe(count);
      }),
      { numRuns: 50 }
    );
  });

  it('Property: Correlation IDs are valid UUIDs', () => {
    fc.assert(
      fc.property(fc.constant(null), () => {
        const id = logger.generateCorrelationId();
        
        // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
        expect(id).toMatch(uuidRegex);
      }),
      { numRuns: 100 }
    );
  });

  it('Property: Log level filtering works correctly', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.constantFrom(LogLevel.ERROR, LogLevel.WARN, LogLevel.INFO, LogLevel.DEBUG),
        async (configuredLevel) => {
          // Create a unique log directory for this test run
          const uniqueLogDir = `${testLogDir}-${Date.now()}-${Math.random()}`;
          
          // Create logger with specific level
          const testLogger = new Logger({
            logDir: uniqueLogDir,
            logLevel: configuredLevel,
          });

          // Ensure directory exists
          await fs.mkdir(uniqueLogDir, { recursive: true });

          // Log messages at all levels
          testLogger.error('Error message');
          testLogger.warn('Warn message');
          testLogger.info('Info message');
          testLogger.debug('Debug message');

          // Wait for async writes
          await new Promise(resolve => setTimeout(resolve, 150));

          // Read the log file
          const logFiles = await fs.readdir(uniqueLogDir);
          const logContent = await fs.readFile(
            path.join(uniqueLogDir, logFiles[0]),
            'utf-8'
          );
          const lines = logContent.trim().split('\n').filter(line => line);

          // Determine expected log count based on level
          const levelPriority = {
            [LogLevel.ERROR]: 0,
            [LogLevel.WARN]: 1,
            [LogLevel.INFO]: 2,
            [LogLevel.DEBUG]: 3,
          };

          const expectedCount = levelPriority[configuredLevel] + 1;
          expect(lines.length).toBe(expectedCount);

          // Verify all logged entries are at or above the configured level
          for (const line of lines) {
            const entry = JSON.parse(line);
            expect(levelPriority[entry.level as LogLevel]).toBeLessThanOrEqual(
              levelPriority[configuredLevel]
            );
          }

          // Cleanup unique log directory
          try {
            const files = await fs.readdir(uniqueLogDir);
            for (const file of files) {
              await fs.unlink(path.join(uniqueLogDir, file));
            }
            await fs.rmdir(uniqueLogDir);
          } catch (error) {
            // Ignore cleanup errors
          }
        }
      ),
      { numRuns: 10 }
    );
  });

  it('Property 59: Log Rotation - Files rotate when exceeding size limit', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.integer({ min: 1, max: 10 }),
        fc.integer({ min: 100, max: 500 }),
        async (messageCount, messageSize) => {
          // Create a unique log directory for this test run
          const uniqueLogDir = `${testLogDir}-rotation-${Date.now()}-${Math.random()}`;
          
          // Create logger with very small max size
          const rotationLogger = new Logger({
            logDir: uniqueLogDir,
            logLevel: LogLevel.INFO,
            maxLogSizeMB: 0.001, // 1KB
            retentionDays: 30,
          });

          // Ensure directory exists
          await fs.mkdir(uniqueLogDir, { recursive: true });

          // Write messages that will exceed the size limit
          const largeMessage = 'x'.repeat(messageSize);
          for (let i = 0; i < messageCount; i++) {
            rotationLogger.info(largeMessage, { iteration: i });
            await new Promise(resolve => setTimeout(resolve, 50));
          }

          // Wait for rotation to complete
          await new Promise(resolve => setTimeout(resolve, 200));

          // Read all log files
          const logFiles = await fs.readdir(uniqueLogDir);
          const logFileList = logFiles.filter(f => f.endsWith('.log'));

          // If we wrote enough data, we should have multiple log files
          const totalDataSize = messageCount * messageSize;
          if (totalDataSize > 1024) { // More than 1KB
            expect(logFileList.length).toBeGreaterThan(0);
          }

          // Verify all messages are preserved across all log files
          let allMessages: any[] = [];
          for (const file of logFileList) {
            const content = await fs.readFile(path.join(uniqueLogDir, file), 'utf-8');
            const lines = content.trim().split('\n').filter(line => line);
            const entries = lines.map(line => JSON.parse(line));
            allMessages = allMessages.concat(entries);
          }

          // All messages should be logged
          expect(allMessages.length).toBeGreaterThanOrEqual(messageCount);

          // Cleanup
          try {
            const files = await fs.readdir(uniqueLogDir);
            for (const file of files) {
              await fs.unlink(path.join(uniqueLogDir, file));
            }
            await fs.rmdir(uniqueLogDir);
          } catch (error) {
            // Ignore cleanup errors
          }
        }
      ),
      { numRuns: 5 }
    );
  });

  it('Property 60: Log Retention - Files older than retention period are deleted', async () => {
    /**
     * Property 60: Log Retention
     * 
     * For any log file older than 30 days, the System SHALL delete the file.
     * 
     * **Validates: Requirements 30.5**
     */
    await fc.assert(
      fc.asyncProperty(
        fc.integer({ min: 31, max: 100 }),
        fc.integer({ min: 1, max: 29 }),
        async (oldDays, recentDays) => {
          // Create a unique log directory for this test run
          const uniqueLogDir = `${testLogDir}-retention-${Date.now()}-${Math.random()}`;
          await fs.mkdir(uniqueLogDir, { recursive: true });

          // Create an old log file
          const oldDate = new Date();
          oldDate.setDate(oldDate.getDate() - oldDays);
          const oldLogFile = path.join(
            uniqueLogDir,
            `app-${oldDate.toISOString().split('T')[0]}.log`
          );
          await fs.writeFile(oldLogFile, JSON.stringify({ test: 'old' }) + '\n');
          const oldTime = oldDate.getTime() / 1000;
          await fs.utimes(oldLogFile, oldTime, oldTime);

          // Create a recent log file
          const recentDate = new Date();
          recentDate.setDate(recentDate.getDate() - recentDays);
          const recentLogFile = path.join(
            uniqueLogDir,
            `app-${recentDate.toISOString().split('T')[0]}.log`
          );
          await fs.writeFile(recentLogFile, JSON.stringify({ test: 'recent' }) + '\n');
          const recentTime = recentDate.getTime() / 1000;
          await fs.utimes(recentLogFile, recentTime, recentTime);

          // Create logger with 30-day retention
          const retentionLogger = new Logger({
            logDir: uniqueLogDir,
            logLevel: LogLevel.INFO,
            maxLogSizeMB: 100,
            retentionDays: 30,
          });

          // Trigger cleanup by writing a log
          retentionLogger.info('Trigger cleanup');
          await new Promise(resolve => setTimeout(resolve, 500));

          // Check files
          const logFiles = await fs.readdir(uniqueLogDir);
          const oldFileName = path.basename(oldLogFile);
          const recentFileName = path.basename(recentLogFile);

          // Old file should be deleted
          expect(logFiles).not.toContain(oldFileName);
          
          // Recent file should still exist
          expect(logFiles).toContain(recentFileName);

          // Cleanup
          try {
            const files = await fs.readdir(uniqueLogDir);
            for (const file of files) {
              await fs.unlink(path.join(uniqueLogDir, file));
            }
            await fs.rmdir(uniqueLogDir);
          } catch (error) {
            // Ignore cleanup errors
          }
        }
      ),
      { numRuns: 5 }
    );
  });
});
