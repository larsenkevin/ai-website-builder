import fs from 'fs/promises';
import path from 'path';
import { SiteConfig, PageConfig, TempConfig } from '../types/config.js';
import { logger } from './Logger.js';

export interface ConfigManagerConfig {
  configDir: string;
}

export class ConfigValidationError extends Error {
  constructor(
    message: string,
    public field?: string,
    public value?: any
  ) {
    super(message);
    this.name = 'ConfigValidationError';
  }
}

/**
 * Validation helper functions
 */
class Validators {
  /**
   * Validate email format
   */
  static isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * Validate phone format (supports various formats)
   * Accepts: +1-234-567-8900, (123) 456-7890, 123-456-7890, 1234567890, etc.
   */
  static isValidPhone(phone: string): boolean {
    // Remove all non-digit characters for validation
    const digitsOnly = phone.replace(/\D/g, '');
    // Must have at least 10 digits (US/international format)
    return digitsOnly.length >= 10 && digitsOnly.length <= 15;
  }

  /**
   * Validate URL format
   */
  static isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Validate domain format (without protocol)
   */
  static isValidDomain(domain: string): boolean {
    const domainRegex = /^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$/i;
    return domainRegex.test(domain);
  }

  /**
   * Validate hex color format
   */
  static isValidHexColor(color: string): boolean {
    const hexColorRegex = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/;
    return hexColorRegex.test(color);
  }
}

export class ConfigManager {
  private config: ConfigManagerConfig;
  private siteConfigPath: string;
  private pagesDir: string;

  constructor(config?: Partial<ConfigManagerConfig>) {
    this.config = {
      configDir: config?.configDir || process.env.CONFIG_DIR || './config',
    };

    this.siteConfigPath = path.join(this.config.configDir, 'site.json');
    this.pagesDir = path.join(this.config.configDir, 'pages');
    this.ensureDirectories();
  }

  private async ensureDirectories(): Promise<void> {
    try {
      await fs.mkdir(this.config.configDir, { recursive: true });
      await fs.mkdir(this.pagesDir, { recursive: true });
    } catch (error) {
      logger.error('Failed to create config directories', { error });
    }
  }

  /**
   * Atomic file write operation
   * Writes to a temporary file first, then renames to prevent partial writes
   */
  private async atomicWrite(filePath: string, content: string): Promise<void> {
    const tempPath = `${filePath}.tmp`;

    try {
      // Write to temporary file
      await fs.writeFile(tempPath, content, 'utf-8');

      // Atomic rename
      await fs.rename(tempPath, filePath);

      logger.debug('Atomic write completed', { filePath });
    } catch (error) {
      // Clean up temp file if it exists
      try {
        await fs.unlink(tempPath);
      } catch {
        // Ignore cleanup errors
      }

      logger.error('Atomic write failed', { filePath, error });
      throw error;
    }
  }

  /**
   * Validate SiteConfig object
   */
  private validateSiteConfig(config: any): void {
    const errors: ConfigValidationError[] = [];

    // Required string fields
    const requiredStringFields: (keyof SiteConfig)[] = [
      'businessName',
      'legalName',
      'industry',
      'description',
      'email',
      'phone',
      'domain',
    ];

    for (const field of requiredStringFields) {
      if (!config[field] || typeof config[field] !== 'string') {
        errors.push(
          new ConfigValidationError(
            `${field} is required and must be a string`,
            field,
            config[field]
          )
        );
      }
    }

    // Validate email format
    if (config.email && typeof config.email === 'string') {
      if (!Validators.isValidEmail(config.email)) {
        errors.push(
          new ConfigValidationError(
            'email must be a valid email address (e.g., user@example.com)',
            'email',
            config.email
          )
        );
      }
    }

    // Validate phone format
    if (config.phone && typeof config.phone === 'string') {
      if (!Validators.isValidPhone(config.phone)) {
        errors.push(
          new ConfigValidationError(
            'phone must be a valid phone number with at least 10 digits',
            'phone',
            config.phone
          )
        );
      }
    }

    // Validate domain format
    if (config.domain && typeof config.domain === 'string') {
      if (!Validators.isValidDomain(config.domain)) {
        errors.push(
          new ConfigValidationError(
            'domain must be a valid domain name (e.g., example.com)',
            'domain',
            config.domain
          )
        );
      }
    }

    // Validate hex colors if present
    if (config.primaryColor && typeof config.primaryColor === 'string') {
      if (!Validators.isValidHexColor(config.primaryColor)) {
        errors.push(
          new ConfigValidationError(
            'primaryColor must be a valid hex color (e.g., #FF5733 or #F57)',
            'primaryColor',
            config.primaryColor
          )
        );
      }
    }

    if (config.secondaryColor && typeof config.secondaryColor === 'string') {
      if (!Validators.isValidHexColor(config.secondaryColor)) {
        errors.push(
          new ConfigValidationError(
            'secondaryColor must be a valid hex color (e.g., #FF5733 or #F57)',
            'secondaryColor',
            config.secondaryColor
          )
        );
      }
    }

    // Validate address
    if (!config.address || typeof config.address !== 'object') {
      errors.push(
        new ConfigValidationError('address is required and must be an object', 'address', config.address)
      );
    } else {
      const addressFields = ['street', 'city', 'state', 'zip', 'country'];
      for (const field of addressFields) {
        if (!config.address[field] || typeof config.address[field] !== 'string') {
          errors.push(
            new ConfigValidationError(
              `address.${field} is required and must be a string`,
              `address.${field}`,
              config.address[field]
            )
          );
        }
      }
    }

    // Validate navigation array
    if (!Array.isArray(config.navigation)) {
      errors.push(
        new ConfigValidationError('navigation must be an array', 'navigation', config.navigation)
      );
    }

    if (errors.length > 0) {
      const errorMessage = errors.map((e) => e.message).join('; ');
      throw new ConfigValidationError(`Site configuration validation failed: ${errorMessage}`);
    }
  }

  /**
   * Validate PageConfig object
   */
  private validatePageConfig(config: any): void {
    const errors: ConfigValidationError[] = [];

    // Required fields
    if (!config.id || typeof config.id !== 'string') {
      errors.push(new ConfigValidationError('id is required and must be a string', 'id', config.id));
    }

    if (!config.title || typeof config.title !== 'string') {
      errors.push(
        new ConfigValidationError('title is required and must be a string', 'title', config.title)
      );
    }

    if (!Array.isArray(config.sections)) {
      errors.push(
        new ConfigValidationError('sections must be an array', 'sections', config.sections)
      );
    }

    if (!config.metaDescription || typeof config.metaDescription !== 'string') {
      errors.push(
        new ConfigValidationError(
          'metaDescription is required and must be a string',
          'metaDescription',
          config.metaDescription
        )
      );
    }

    if (!Array.isArray(config.keywords)) {
      errors.push(
        new ConfigValidationError('keywords must be an array', 'keywords', config.keywords)
      );
    }

    if (!config.intent || typeof config.intent !== 'object') {
      errors.push(
        new ConfigValidationError('intent is required and must be an object', 'intent', config.intent)
      );
    } else {
      // Validate intent fields
      if (!config.intent.primaryGoal || typeof config.intent.primaryGoal !== 'string') {
        errors.push(
          new ConfigValidationError(
            'intent.primaryGoal is required and must be a string',
            'intent.primaryGoal',
            config.intent.primaryGoal
          )
        );
      }

      if (!config.intent.targetAudience || typeof config.intent.targetAudience !== 'string') {
        errors.push(
          new ConfigValidationError(
            'intent.targetAudience is required and must be a string',
            'intent.targetAudience',
            config.intent.targetAudience
          )
        );
      }

      if (!Array.isArray(config.intent.callsToAction)) {
        errors.push(
          new ConfigValidationError(
            'intent.callsToAction must be an array',
            'intent.callsToAction',
            config.intent.callsToAction
          )
        );
      }
    }

    // Validate featuredImage URL if present
    if (config.featuredImage && typeof config.featuredImage === 'string') {
      if (!Validators.isValidUrl(config.featuredImage) && !config.featuredImage.startsWith('/')) {
        errors.push(
          new ConfigValidationError(
            'featuredImage must be a valid URL or path',
            'featuredImage',
            config.featuredImage
          )
        );
      }
    }

    if (errors.length > 0) {
      const errorMessage = errors.map((e) => e.message).join('; ');
      throw new ConfigValidationError(`Page configuration validation failed: ${errorMessage}`);
    }
  }

  /**
   * Load site configuration
   */
  async loadSiteConfig(): Promise<SiteConfig> {
    try {
      const content = await fs.readFile(this.siteConfigPath, 'utf-8');
      const config = JSON.parse(content);
      this.validateSiteConfig(config);
      logger.debug('Site config loaded', { path: this.siteConfigPath });
      return config as SiteConfig;
    } catch (error: any) {
      if (error.code === 'ENOENT') {
        logger.warn('Site config not found', { path: this.siteConfigPath });
        throw new Error('Site configuration not found');
      }
      if (error instanceof SyntaxError) {
        logger.error('Invalid JSON in site config', { path: this.siteConfigPath, error });
        throw new ConfigValidationError('Site configuration contains invalid JSON');
      }
      logger.error('Failed to load site config', { path: this.siteConfigPath, error });
      throw error;
    }
  }

  /**
   * Save site configuration
   */
  async saveSiteConfig(config: SiteConfig, correlationId?: string): Promise<void> {
    try {
      this.validateSiteConfig(config);

      // Update lastModified timestamp
      config.lastModified = new Date().toISOString();

      const content = JSON.stringify(config, null, 2);
      await this.atomicWrite(this.siteConfigPath, content);

      logger.logConfigChange('site', 'site', 'save', correlationId, {
        path: this.siteConfigPath,
      });
    } catch (error) {
      logger.error('Failed to save site config', { path: this.siteConfigPath, error }, correlationId);
      throw error;
    }
  }

  /**
   * Get page config file path
   */
  private getPageConfigPath(pageId: string): string {
    return path.join(this.pagesDir, `${pageId}.json`);
  }

  /**
   * Get temp config file path
   */
  private getTempConfigPath(pageId: string): string {
    return path.join(this.pagesDir, `${pageId}.temp.json`);
  }

  /**
   * Load page configuration
   */
  async loadPageConfig(pageId: string): Promise<PageConfig> {
    const filePath = this.getPageConfigPath(pageId);

    try {
      const content = await fs.readFile(filePath, 'utf-8');
      const config = JSON.parse(content);
      this.validatePageConfig(config);
      logger.debug('Page config loaded', { pageId, path: filePath });
      return config as PageConfig;
    } catch (error: any) {
      if (error.code === 'ENOENT') {
        logger.warn('Page config not found', { pageId, path: filePath });
        throw new Error(`Page configuration not found: ${pageId}`);
      }
      if (error instanceof SyntaxError) {
        logger.error('Invalid JSON in page config', { pageId, path: filePath, error });
        throw new ConfigValidationError(`Page configuration contains invalid JSON: ${pageId}`);
      }
      logger.error('Failed to load page config', { pageId, path: filePath, error });
      throw error;
    }
  }

  /**
   * Save page configuration
   */
  async savePageConfig(config: PageConfig, correlationId?: string): Promise<void> {
    const filePath = this.getPageConfigPath(config.id);

    try {
      this.validatePageConfig(config);

      // Update lastModified timestamp and increment version
      config.lastModified = new Date().toISOString();
      config.version = (config.version || 0) + 1;

      const content = JSON.stringify(config, null, 2);
      await this.atomicWrite(filePath, content);

      logger.logConfigChange('page', config.id, 'save', correlationId, {
        path: filePath,
        version: config.version,
      });
    } catch (error) {
      logger.error('Failed to save page config', { pageId: config.id, path: filePath, error }, correlationId);
      throw error;
    }
  }

  /**
   * Load temp configuration
   */
  async loadTempConfig(pageId: string): Promise<TempConfig> {
    const filePath = this.getTempConfigPath(pageId);

    try {
      const content = await fs.readFile(filePath, 'utf-8');
      const config = JSON.parse(content);
      // Validate base page config fields
      this.validatePageConfig(config);
      logger.debug('Temp config loaded', { pageId, path: filePath });
      return config as TempConfig;
    } catch (error: any) {
      if (error.code === 'ENOENT') {
        logger.warn('Temp config not found', { pageId, path: filePath });
        throw new Error(`Temp configuration not found: ${pageId}`);
      }
      if (error instanceof SyntaxError) {
        logger.error('Invalid JSON in temp config', { pageId, path: filePath, error });
        throw new ConfigValidationError(`Temp configuration contains invalid JSON: ${pageId}`);
      }
      logger.error('Failed to load temp config', { pageId, path: filePath, error });
      throw error;
    }
  }

  /**
   * Save temp configuration
   */
  async saveTempConfig(config: TempConfig, correlationId?: string): Promise<void> {
    const filePath = this.getTempConfigPath(config.id);

    try {
      // Validate base page config fields
      this.validatePageConfig(config);

      const content = JSON.stringify(config, null, 2);
      await this.atomicWrite(filePath, content);

      logger.logConfigChange('temp', config.id, 'save', correlationId, {
        path: filePath,
        sessionId: config.sessionId,
      });
    } catch (error) {
      logger.error('Failed to save temp config', { pageId: config.id, path: filePath, error }, correlationId);
      throw error;
    }
  }

  /**
   * Copy temp config to page config
   */
  async copyTempToPage(pageId: string, correlationId?: string): Promise<void> {
    try {
      const tempConfig = await this.loadTempConfig(pageId);

      // Remove temp-specific fields
      const { sessionId, startedAt, conversationHistory, ...pageConfig } = tempConfig;

      // Save as page config
      await this.savePageConfig(pageConfig as PageConfig, correlationId);

      logger.logConfigChange('temp', pageId, 'copy-to-page', correlationId);
    } catch (error) {
      logger.error('Failed to copy temp to page', { pageId, error }, correlationId);
      throw error;
    }
  }

  /**
   * Delete temp configuration
   */
  async deleteTempConfig(pageId: string, correlationId?: string): Promise<void> {
    const filePath = this.getTempConfigPath(pageId);

    try {
      await fs.unlink(filePath);
      logger.logConfigChange('temp', pageId, 'delete', correlationId, { path: filePath });
    } catch (error: any) {
      if (error.code === 'ENOENT') {
        // File doesn't exist, that's fine
        logger.debug('Temp config already deleted', { pageId, path: filePath });
        return;
      }
      logger.error('Failed to delete temp config', { pageId, path: filePath, error }, correlationId);
      throw error;
    }
  }

  /**
   * Check if temp config exists
   */
  async tempConfigExists(pageId: string): Promise<boolean> {
    const filePath = this.getTempConfigPath(pageId);
    try {
      await fs.access(filePath);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * List all page IDs
   */
  async listPages(): Promise<string[]> {
    try {
      const files = await fs.readdir(this.pagesDir);
      const pageIds = files
        .filter((file) => file.endsWith('.json') && !file.endsWith('.temp.json'))
        .map((file) => file.replace('.json', ''));

      logger.debug('Listed pages', { count: pageIds.length });
      return pageIds;
    } catch (error) {
      logger.error('Failed to list pages', { error });
      throw error;
    }
  }

  /**
   * List all temp config page IDs
   */
  async listTempConfigs(): Promise<string[]> {
    try {
      const files = await fs.readdir(this.pagesDir);
      const pageIds = files
        .filter((file) => file.endsWith('.temp.json'))
        .map((file) => file.replace('.temp.json', ''));

      logger.debug('Listed temp configs', { count: pageIds.length });
      return pageIds;
    } catch (error) {
      logger.error('Failed to list temp configs', { error });
      throw error;
    }
  }

  /**
   * Check if page config exists
   */
  async pageConfigExists(pageId: string): Promise<boolean> {
    const filePath = this.getPageConfigPath(pageId);
    try {
      await fs.access(filePath);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Get file stats for a given path
   * Returns null if file doesn't exist
   */
  async getFileStats(filePath: string): Promise<any | null> {
    try {
      return await fs.stat(filePath);
    } catch (error: any) {
      if (error.code === 'ENOENT') {
        return null;
      }
      throw error;
    }
  }

  /**
   * Get the temp config file path (exposed for cleanup operations)
   */
  getPublicTempConfigPath(pageId: string): string {
    return path.join(this.pagesDir, `${pageId}.temp.json`);
  }

}

// Export singleton instance
export const configManager = new ConfigManager();
