/**
 * VersionManager Service
 * 
 * Manages version history and rollback functionality for page configurations.
 * Maintains the last 10 versions of each page.
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import { PageConfig } from '../types/config.js';
import { ConfigManager } from './ConfigManager.js';
import { Logger } from './Logger.js';

export interface Version {
  filename: string;
  timestamp: Date;
  number: number;
}

export interface VersionManagerConfig {
  versionsDir: string;
  maxVersions: number;
}

export class VersionManager {
  private config: VersionManagerConfig;
  private configManager: ConfigManager;
  private logger: Logger;

  constructor(
    config: VersionManagerConfig,
    configManager: ConfigManager,
    logger: Logger
  ) {
    this.config = config;
    this.configManager = configManager;
    this.logger = logger;
  }

  /**
   * Create a backup of the current page configuration
   */
  async createBackup(pageId: string): Promise<void> {
    this.logger.debug('Creating backup', { pageId });

    try {
      const pageConfig = await this.configManager.loadPageConfig(pageId);
      const versionDir = path.join(this.config.versionsDir, 'pages', pageId);

      // Ensure directory exists
      await fs.mkdir(versionDir, { recursive: true });

      // Get existing versions
      const versions = await this.listVersions(pageId);

      // Create new version
      const versionNumber = versions.length > 0 ? versions[0].number + 1 : 1;
      const versionPath = path.join(versionDir, `v${versionNumber}.json`);
      await fs.writeFile(versionPath, JSON.stringify(pageConfig, null, 2), 'utf-8');

      this.logger.info('Backup created', {
        pageId,
        versionNumber,
        versionPath,
      });

      // Cleanup old versions if exceeding limit
      if (versions.length >= this.config.maxVersions) {
        const oldestVersion = versions[versions.length - 1];
        const oldestPath = path.join(versionDir, oldestVersion.filename);
        await fs.unlink(oldestPath);

        this.logger.debug('Old version deleted', {
          pageId,
          versionNumber: oldestVersion.number,
        });
      }
    } catch (error: any) {
      this.logger.error('Failed to create backup', {
        pageId,
        error: error.message,
        stack: error.stack,
      });
      throw error;
    }
  }

  /**
   * List all versions for a page
   */
  async listVersions(pageId: string): Promise<Version[]> {
    const versionDir = path.join(this.config.versionsDir, 'pages', pageId);

    try {
      const files = await fs.readdir(versionDir);
      const versions = await Promise.all(
        files
          .filter((f) => f.endsWith('.json'))
          .map(async (file) => {
            const filePath = path.join(versionDir, file);
            const stat = await fs.stat(filePath);
            const match = file.match(/v(\d+)\.json/);
            const number = match ? parseInt(match[1], 10) : 0;

            return {
              filename: file,
              timestamp: stat.mtime,
              number,
            };
          })
      );

      // Sort by version number descending (newest first)
      return versions.sort((a, b) => b.number - a.number);
    } catch (error: any) {
      if (error.code === 'ENOENT') {
        // Directory doesn't exist yet
        return [];
      }
      throw error;
    }
  }

  /**
   * Restore a specific version
   */
  async restoreVersion(pageId: string, versionNumber: number): Promise<void> {
    this.logger.info('Restoring version', { pageId, versionNumber });

    try {
      const versionPath = path.join(
        this.config.versionsDir,
        'pages',
        pageId,
        `v${versionNumber}.json`
      );

      // Check if version exists
      try {
        await fs.access(versionPath);
      } catch (error) {
        throw new VersionManagerError(
          `Version ${versionNumber} not found for page ${pageId}`
        );
      }

      // Create backup of current version first
      await this.createBackup(pageId);

      // Read version content
      const versionContent = await fs.readFile(versionPath, 'utf-8');
      const versionConfig: PageConfig = JSON.parse(versionContent);

      // Update lastModified timestamp
      versionConfig.lastModified = new Date().toISOString();

      // Save as current page config
      await this.configManager.savePageConfig(versionConfig);

      this.logger.info('Version restored successfully', {
        pageId,
        versionNumber,
      });
    } catch (error: any) {
      this.logger.error('Failed to restore version', {
        pageId,
        versionNumber,
        error: error.message,
        stack: error.stack,
      });
      throw error;
    }
  }

  /**
   * Get a specific version content
   */
  async getVersion(pageId: string, versionNumber: number): Promise<PageConfig> {
    const versionPath = path.join(
      this.config.versionsDir,
      'pages',
      pageId,
      `v${versionNumber}.json`
    );

    try {
      const content = await fs.readFile(versionPath, 'utf-8');
      return JSON.parse(content);
    } catch (error: any) {
      if (error.code === 'ENOENT') {
        throw new VersionManagerError(
          `Version ${versionNumber} not found for page ${pageId}`
        );
      }
      throw error;
    }
  }

  /**
   * Delete all versions for a page
   */
  async deleteAllVersions(pageId: string): Promise<void> {
    this.logger.info('Deleting all versions', { pageId });

    const versionDir = path.join(this.config.versionsDir, 'pages', pageId);

    try {
      await fs.rm(versionDir, { recursive: true, force: true });
      this.logger.info('All versions deleted', { pageId });
    } catch (error: any) {
      this.logger.error('Failed to delete versions', {
        pageId,
        error: error.message,
      });
      throw error;
    }
  }
}

/**
 * Custom error class for VersionManager errors
 */
export class VersionManagerError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'VersionManagerError';
  }
}
