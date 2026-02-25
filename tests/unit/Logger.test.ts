import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { Logger, LogLevel } from '../../app/services/Logger.js';
import fs from 'fs/promises';
import path from 'path';

describe('Logger', () => {
  const testLogDir = './logs/test';
  let logger: Logger;

  beforeEach(async () => {
    // Create a test logger with custom config
    logger = new Logger({
      logDir: testLogDir,
      logLevel: LogLevel.DEBUG,
      maxLogSizeMB: 1, // Small size for testing rotation
      retentionDays: 1,
    });

    // Ensure test log directory exists
    await fs.mkdir(testLogDir, { recursive: true });
  });

  afterEach(async () => {
    // Clean up test logs
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

  describe('Log Levels', () => {
    it('should log ERROR messages', async () => {
      logger.error('Test error', { code: 500 });
      
      // Wait for async write
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      expect(logFiles.length).toBeGreaterThan(0);
      
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const logEntry = JSON.parse(logContent.trim());
      
      expect(logEntry.level).toBe('ERROR');
      expect(logEntry.message).toBe('Test error');
      expect(logEntry.metadata.code).toBe(500);
      expect(logEntry.stack).toBeDefined();
    });

    it('should log WARN messages', async () => {
      logger.warn('Test warning', { reason: 'test' });
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const logEntry = JSON.parse(logContent.trim());
      
      expect(logEntry.level).toBe('WARN');
      expect(logEntry.message).toBe('Test warning');
      expect(logEntry.metadata.reason).toBe('test');
    });

    it('should log INFO messages', async () => {
      logger.info('Test info', { action: 'test' });
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const logEntry = JSON.parse(logContent.trim());
      
      expect(logEntry.level).toBe('INFO');
      expect(logEntry.message).toBe('Test info');
      expect(logEntry.metadata.action).toBe('test');
    });

    it('should log DEBUG messages', async () => {
      logger.debug('Test debug', { detail: 'test' });
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const logEntry = JSON.parse(logContent.trim());
      
      expect(logEntry.level).toBe('DEBUG');
      expect(logEntry.message).toBe('Test debug');
      expect(logEntry.metadata.detail).toBe('test');
    });
  });

  describe('Correlation IDs', () => {
    it('should generate unique correlation IDs', () => {
      const id1 = logger.generateCorrelationId();
      const id2 = logger.generateCorrelationId();
      
      expect(id1).toBeDefined();
      expect(id2).toBeDefined();
      expect(id1).not.toBe(id2);
      expect(id1).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
    });

    it('should include correlation ID in log entries', async () => {
      const correlationId = logger.generateCorrelationId();
      logger.info('Test with correlation', {}, correlationId);
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const logEntry = JSON.parse(logContent.trim());
      
      expect(logEntry.correlationId).toBe(correlationId);
    });
  });

  describe('Structured Logging', () => {
    it('should create JSON-formatted log entries', async () => {
      logger.info('Test message', { key: 'value', number: 42 });
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const logEntry = JSON.parse(logContent.trim());
      
      expect(logEntry).toHaveProperty('timestamp');
      expect(logEntry).toHaveProperty('level');
      expect(logEntry).toHaveProperty('message');
      expect(logEntry).toHaveProperty('metadata');
      expect(logEntry.metadata.key).toBe('value');
      expect(logEntry.metadata.number).toBe(42);
    });

    it('should include timestamp in ISO format', async () => {
      logger.info('Test timestamp');
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const logEntry = JSON.parse(logContent.trim());
      
      expect(logEntry.timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/);
      expect(new Date(logEntry.timestamp).toISOString()).toBe(logEntry.timestamp);
    });
  });

  describe('Helper Methods', () => {
    it('should log API requests with proper structure', async () => {
      const correlationId = logger.generateCorrelationId();
      logger.logApiRequest('GET', '/api/test', 200, 150, correlationId, { userId: '123' });
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const logEntry = JSON.parse(logContent.trim());
      
      expect(logEntry.level).toBe('INFO');
      expect(logEntry.message).toBe('API request');
      expect(logEntry.metadata.method).toBe('GET');
      expect(logEntry.metadata.path).toBe('/api/test');
      expect(logEntry.metadata.statusCode).toBe(200);
      expect(logEntry.metadata.duration).toBe(150);
      expect(logEntry.metadata.userId).toBe('123');
      expect(logEntry.correlationId).toBe(correlationId);
    });

    it('should log configuration changes with proper structure', async () => {
      const correlationId = logger.generateCorrelationId();
      logger.logConfigChange('page', 'home', 'update', correlationId, { field: 'title' });
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const logEntry = JSON.parse(logContent.trim());
      
      expect(logEntry.level).toBe('INFO');
      expect(logEntry.message).toBe('Configuration change');
      expect(logEntry.metadata.configType).toBe('page');
      expect(logEntry.metadata.configId).toBe('home');
      expect(logEntry.metadata.action).toBe('update');
      expect(logEntry.metadata.field).toBe('title');
      expect(logEntry.correlationId).toBe(correlationId);
    });
  });

  describe('Log Level Filtering', () => {
    it('should respect log level configuration', async () => {
      // Create logger with INFO level (should not log DEBUG)
      const infoLogger = new Logger({
        logDir: testLogDir,
        logLevel: LogLevel.INFO,
      });

      infoLogger.debug('This should not be logged');
      infoLogger.info('This should be logged');
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const lines = logContent.trim().split('\n');
      
      expect(lines.length).toBe(1);
      const logEntry = JSON.parse(lines[0]);
      expect(logEntry.level).toBe('INFO');
      expect(logEntry.message).toBe('This should be logged');
    });

    it('should log ERROR when level is ERROR', async () => {
      const errorLogger = new Logger({
        logDir: testLogDir,
        logLevel: LogLevel.ERROR,
      });

      errorLogger.debug('Not logged');
      errorLogger.info('Not logged');
      errorLogger.warn('Not logged');
      errorLogger.error('Logged');
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const lines = logContent.trim().split('\n').filter(line => line);
      
      expect(lines.length).toBe(1);
      const logEntry = JSON.parse(lines[0]);
      expect(logEntry.level).toBe('ERROR');
    });
  });

  describe('Error Stack Traces', () => {
    it('should include stack trace for ERROR level', async () => {
      logger.error('Error with stack');
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const logEntry = JSON.parse(logContent.trim());
      
      expect(logEntry.stack).toBeDefined();
      expect(logEntry.stack).toContain('Error');
    });

    it('should include error stack from metadata if provided', async () => {
      const error = new Error('Test error');
      logger.error('Error occurred', { error });
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const logFiles = await fs.readdir(testLogDir);
      const logContent = await fs.readFile(path.join(testLogDir, logFiles[0]), 'utf-8');
      const logEntry = JSON.parse(logContent.trim());
      
      expect(logEntry.stack).toBeDefined();
      expect(logEntry.stack).toContain('Test error');
    });
  });

  describe('Log Rotation', () => {
    it('should rotate log file when size exceeds maxLogSizeMB', async () => {
      // Create a logger with very small max size for testing
      const rotationLogger = new Logger({
        logDir: testLogDir,
        logLevel: LogLevel.INFO,
        maxLogSizeMB: 0.001, // 1KB for testing
        retentionDays: 30,
      });

      // Write enough logs to exceed the size limit
      const largeMessage = 'x'.repeat(500); // 500 bytes per message
      for (let i = 0; i < 5; i++) {
        rotationLogger.info(largeMessage, { iteration: i });
        await new Promise(resolve => setTimeout(resolve, 50));
      }

      // Wait for rotation to complete
      await new Promise(resolve => setTimeout(resolve, 200));

      // Check that multiple log files exist (original + rotated)
      const logFiles = await fs.readdir(testLogDir);
      const logFileCount = logFiles.filter(f => f.endsWith('.log')).length;
      
      expect(logFileCount).toBeGreaterThan(1);
    });

    it('should preserve log entries after rotation', async () => {
      const rotationLogger = new Logger({
        logDir: testLogDir,
        logLevel: LogLevel.INFO,
        maxLogSizeMB: 0.001, // 1KB
        retentionDays: 30,
      });

      const testMessages = ['Message 1', 'Message 2', 'Message 3'];
      const largeMetadata = { data: 'x'.repeat(400) };

      for (const msg of testMessages) {
        rotationLogger.info(msg, largeMetadata);
        await new Promise(resolve => setTimeout(resolve, 50));
      }

      await new Promise(resolve => setTimeout(resolve, 200));

      // Read all log files and verify messages are preserved
      const logFiles = await fs.readdir(testLogDir);
      let allMessages: string[] = [];

      for (const file of logFiles.filter(f => f.endsWith('.log'))) {
        const content = await fs.readFile(path.join(testLogDir, file), 'utf-8');
        const lines = content.trim().split('\n').filter(line => line);
        const messages = lines.map(line => JSON.parse(line).message);
        allMessages = allMessages.concat(messages);
      }

      for (const msg of testMessages) {
        expect(allMessages).toContain(msg);
      }
    });
  });

  describe('Log Retention', () => {
    it('should delete log files older than retention period', async () => {
      // Create some old log files manually
      const oldDate = new Date();
      oldDate.setDate(oldDate.getDate() - 35); // 35 days ago
      
      const oldLogFile = path.join(testLogDir, `app-${oldDate.toISOString().split('T')[0]}.log`);
      await fs.writeFile(oldLogFile, JSON.stringify({ test: 'old log' }) + '\n');

      // Set the file's modification time to 35 days ago
      const oldTime = oldDate.getTime() / 1000;
      await fs.utimes(oldLogFile, oldTime, oldTime);

      // Create a logger with 30-day retention
      const retentionLogger = new Logger({
        logDir: testLogDir,
        logLevel: LogLevel.INFO,
        maxLogSizeMB: 100,
        retentionDays: 30,
      });

      // Write a current log to trigger cleanup
      retentionLogger.info('Current log');
      
      // Wait for cleanup to run (it runs on startup)
      await new Promise(resolve => setTimeout(resolve, 500));

      // Check that old file was deleted
      const logFiles = await fs.readdir(testLogDir);
      const oldFileName = path.basename(oldLogFile);
      
      expect(logFiles).not.toContain(oldFileName);
    });

    it('should keep log files within retention period', async () => {
      // Create a recent log file
      const recentDate = new Date();
      recentDate.setDate(recentDate.getDate() - 10); // 10 days ago
      
      const recentLogFile = path.join(testLogDir, `app-${recentDate.toISOString().split('T')[0]}.log`);
      await fs.writeFile(recentLogFile, JSON.stringify({ test: 'recent log' }) + '\n');

      // Set the file's modification time to 10 days ago
      const recentTime = recentDate.getTime() / 1000;
      await fs.utimes(recentLogFile, recentTime, recentTime);

      // Create a logger with 30-day retention
      const retentionLogger = new Logger({
        logDir: testLogDir,
        logLevel: LogLevel.INFO,
        maxLogSizeMB: 100,
        retentionDays: 30,
      });

      // Write a current log to trigger cleanup
      retentionLogger.info('Current log');
      
      // Wait for cleanup to run
      await new Promise(resolve => setTimeout(resolve, 500));

      // Check that recent file still exists
      const logFiles = await fs.readdir(testLogDir);
      const recentFileName = path.basename(recentLogFile);
      
      expect(logFiles).toContain(recentFileName);
    });
  });
});
