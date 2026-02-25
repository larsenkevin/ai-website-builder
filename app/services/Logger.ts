import fs from 'fs/promises';
import path from 'path';
import { randomUUID } from 'crypto';

export enum LogLevel {
  ERROR = 'ERROR',
  WARN = 'WARN',
  INFO = 'INFO',
  DEBUG = 'DEBUG',
}

const LOG_LEVEL_PRIORITY: Record<LogLevel, number> = {
  [LogLevel.ERROR]: 0,
  [LogLevel.WARN]: 1,
  [LogLevel.INFO]: 2,
  [LogLevel.DEBUG]: 3,
};

export interface LogEntry {
  timestamp: string;
  level: LogLevel;
  message: string;
  correlationId?: string;
  metadata?: Record<string, any>;
  stack?: string;
}

export interface LoggerConfig {
  logDir: string;
  logLevel: LogLevel;
  maxLogSizeMB: number;
  retentionDays: number;
}

export class Logger {
  private config: LoggerConfig;
  private currentLogFile: string;
  private writeQueue: Promise<void> = Promise.resolve();

  constructor(config?: Partial<LoggerConfig>) {
    this.config = {
      logDir: config?.logDir || process.env.LOG_DIR || './logs',
      logLevel: config?.logLevel || this.parseLogLevel(process.env.LOG_LEVEL) || LogLevel.INFO,
      maxLogSizeMB: config?.maxLogSizeMB || this.parseLogSize(process.env.LOG_ROTATION_SIZE) || 100,
      retentionDays: config?.retentionDays || parseInt(process.env.LOG_RETENTION_DAYS || '30'),
    };

    this.currentLogFile = this.getLogFilePath();
    this.ensureLogDirectory();
    this.startRetentionCleanup();
  }

  private parseLogLevel(level?: string): LogLevel | undefined {
    if (!level) return undefined;
    const upperLevel = level.toUpperCase();
    return Object.values(LogLevel).includes(upperLevel as LogLevel) 
      ? (upperLevel as LogLevel) 
      : undefined;
  }

  private parseLogSize(size?: string): number | undefined {
    if (!size) return undefined;
    const match = size.match(/^(\d+)(MB|GB)?$/i);
    if (!match) return undefined;
    const value = parseInt(match[1]);
    const unit = match[2]?.toUpperCase();
    return unit === 'GB' ? value * 1024 : value;
  }

  private async ensureLogDirectory(): Promise<void> {
    try {
      await fs.mkdir(this.config.logDir, { recursive: true });
    } catch (error) {
      console.error('Failed to create log directory:', error);
    }
  }

  private getLogFilePath(date: Date = new Date()): string {
    const dateStr = date.toISOString().split('T')[0];
    return path.join(this.config.logDir, `app-${dateStr}.log`);
  }

  private shouldLog(level: LogLevel): boolean {
    return LOG_LEVEL_PRIORITY[level] <= LOG_LEVEL_PRIORITY[this.config.logLevel];
  }

  private async writeLog(entry: LogEntry): Promise<void> {
    if (!this.shouldLog(entry.level)) {
      return;
    }

    // Queue writes to prevent race conditions
    this.writeQueue = this.writeQueue.then(async () => {
      try {
        // Check if we need to rotate the log file
        await this.checkAndRotateLog();

        // Write the log entry
        const logLine = JSON.stringify(entry) + '\n';
        await fs.appendFile(this.currentLogFile, logLine, 'utf-8');
      } catch (error) {
        console.error('Failed to write log:', error);
      }
    });

    await this.writeQueue;
  }

  private async checkAndRotateLog(): Promise<void> {
    try {
      const stats = await fs.stat(this.currentLogFile);
      const sizeMB = stats.size / (1024 * 1024);

      if (sizeMB >= this.config.maxLogSizeMB) {
        // Rotate the log file
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const rotatedFile = this.currentLogFile.replace('.log', `-${timestamp}.log`);
        await fs.rename(this.currentLogFile, rotatedFile);
        
        // Update current log file path (might be a new day)
        this.currentLogFile = this.getLogFilePath();
      }
    } catch (error: any) {
      // If file doesn't exist, that's fine - it will be created on first write
      if (error.code !== 'ENOENT') {
        console.error('Failed to check log file size:', error);
      }
    }
  }

  private startRetentionCleanup(): void {
    // Run cleanup daily
    const cleanupInterval = 24 * 60 * 60 * 1000; // 24 hours
    
    const cleanup = async () => {
      try {
        const files = await fs.readdir(this.config.logDir);
        const now = Date.now();
        const retentionMs = this.config.retentionDays * 24 * 60 * 60 * 1000;

        for (const file of files) {
          if (!file.endsWith('.log')) continue;

          const filePath = path.join(this.config.logDir, file);
          const stats = await fs.stat(filePath);
          const age = now - stats.mtime.getTime();

          if (age > retentionMs) {
            await fs.unlink(filePath);
            this.info('Deleted old log file', { file, ageInDays: age / (24 * 60 * 60 * 1000) });
          }
        }
      } catch (error) {
        console.error('Failed to cleanup old logs:', error);
      }
    };

    // Run cleanup on startup and then daily
    cleanup();
    setInterval(cleanup, cleanupInterval);
  }

  public generateCorrelationId(): string {
    return randomUUID();
  }

  public error(message: string, metadata?: Record<string, any>, correlationId?: string): void {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level: LogLevel.ERROR,
      message,
      correlationId,
      metadata,
      stack: metadata?.error?.stack || new Error().stack,
    };
    this.writeLog(entry);
  }

  public warn(message: string, metadata?: Record<string, any>, correlationId?: string): void {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level: LogLevel.WARN,
      message,
      correlationId,
      metadata,
    };
    this.writeLog(entry);
  }

  public info(message: string, metadata?: Record<string, any>, correlationId?: string): void {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level: LogLevel.INFO,
      message,
      correlationId,
      metadata,
    };
    this.writeLog(entry);
  }

  public debug(message: string, metadata?: Record<string, any>, correlationId?: string): void {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level: LogLevel.DEBUG,
      message,
      correlationId,
      metadata,
    };
    this.writeLog(entry);
  }

  // Helper method to log API requests
  public logApiRequest(
    method: string,
    path: string,
    statusCode: number,
    duration: number,
    correlationId: string,
    metadata?: Record<string, any>
  ): void {
    this.info('API request', {
      method,
      path,
      statusCode,
      duration,
      ...metadata,
    }, correlationId);
  }

  // Helper method to log configuration changes
  public logConfigChange(
    configType: string,
    configId: string,
    action: string,
    correlationId?: string,
    metadata?: Record<string, any>
  ): void {
    this.info('Configuration change', {
      configType,
      configId,
      action,
      ...metadata,
    }, correlationId);
  }
}

// Export singleton instance
export const logger = new Logger();
