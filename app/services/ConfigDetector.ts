/**
 * ConfigDetector Service
 * 
 * Monitors configuration files for changes and triggers HTML regeneration.
 * Implements debouncing to batch multiple simultaneous changes.
 */

import chokidar, { FSWatcher } from 'chokidar';
import * as path from 'path';
import { StaticGenerator } from './StaticGenerator.js';
import { Logger } from './Logger.js';

export interface ConfigDetectorConfig {
  configDir: string;
  debounceMs: number;
}

export class ConfigDetector {
  private watcher: FSWatcher | null = null;
  private generator: StaticGenerator;
  private logger: Logger;
  private config: ConfigDetectorConfig;
  private debounceTimer: NodeJS.Timeout | null = null;
  private isRunning: boolean = false;

  constructor(
    config: ConfigDetectorConfig,
    generator: StaticGenerator,
    logger: Logger
  ) {
    this.config = config;
    this.generator = generator;
    this.logger = logger;
  }

  /**
   * Start watching configuration files
   */
  start(): void {
    if (this.isRunning) {
      this.logger.warn('ConfigDetector already running');
      return;
    }

    const siteConfigPath = path.join(this.config.configDir, 'site.json');
    const pagesPattern = path.join(this.config.configDir, 'pages', '*.json');

    this.logger.info('Starting ConfigDetector', {
      siteConfigPath,
      pagesPattern,
    });

    this.watcher = chokidar.watch([siteConfigPath, pagesPattern], {
      ignored: /\.temp\.json$/, // Ignore temp files
      persistent: true,
      ignoreInitial: true, // Don't trigger on initial scan
    });

    this.watcher.on('change', (filePath) => {
      this.logger.debug('Configuration file changed', { filePath });
      this.scheduleRegeneration();
    });

    this.watcher.on('add', (filePath) => {
      this.logger.debug('Configuration file added', { filePath });
      this.scheduleRegeneration();
    });

    this.watcher.on('unlink', (filePath) => {
      this.logger.debug('Configuration file removed', { filePath });
      this.scheduleRegeneration();
    });

    this.watcher.on('error', (error: unknown) => {
      const err = error as Error;
      this.logger.error('ConfigDetector error', {
        error: err.message,
        stack: err.stack,
      });
    });

    this.isRunning = true;
    this.logger.info('ConfigDetector started successfully');
  }

  /**
   * Stop watching configuration files
   */
  stop(): void {
    if (!this.isRunning) {
      return;
    }

    this.logger.info('Stopping ConfigDetector');

    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = null;
    }

    if (this.watcher) {
      this.watcher.close();
      this.watcher = null;
    }

    this.isRunning = false;
    this.logger.info('ConfigDetector stopped');
  }

  /**
   * Schedule site regeneration with debouncing
   * Batches multiple changes within the debounce window
   */
  private scheduleRegeneration(): void {
    // Clear existing timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }

    // Schedule regeneration after debounce period
    this.debounceTimer = setTimeout(async () => {
      this.logger.info('Starting site regeneration');

      try {
        await this.generator.generateSite();
        this.logger.info('Site regeneration completed successfully');
      } catch (error: any) {
        this.logger.error('Site regeneration failed', {
          error: error.message,
          stack: error.stack,
        });
      }

      this.debounceTimer = null;
    }, this.config.debounceMs);

    this.logger.debug('Site regeneration scheduled', {
      debounceMs: this.config.debounceMs,
    });
  }

  /**
   * Check if detector is running
   */
  isActive(): boolean {
    return this.isRunning;
  }
}
