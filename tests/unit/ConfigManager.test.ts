import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'fs/promises';
import path from 'path';
import { ConfigManager, ConfigValidationError } from '../../app/services/ConfigManager.js';
import { SiteConfig, PageConfig, TempConfig } from '../../app/types/config.js';

const TEST_CONFIG_DIR = './test-config';

describe('ConfigManager', () => {
  let configManager: ConfigManager;

  beforeEach(async () => {
    // Create test config directory
    await fs.mkdir(TEST_CONFIG_DIR, { recursive: true });
    await fs.mkdir(path.join(TEST_CONFIG_DIR, 'pages'), { recursive: true });

    configManager = new ConfigManager({ configDir: TEST_CONFIG_DIR });
  });

  afterEach(async () => {
    // Clean up test directory
    try {
      await fs.rm(TEST_CONFIG_DIR, { recursive: true, force: true });
    } catch (error) {
      // Ignore cleanup errors
    }
  });

  describe('Site Configuration', () => {
    const validSiteConfig: SiteConfig = {
      businessName: 'Test Business',
      legalName: 'Test Business LLC',
      industry: 'Technology',
      description: 'A test business',
      email: 'test@example.com',
      phone: '555-123-4567',
      address: {
        street: '123 Main St',
        city: 'Test City',
        state: 'TS',
        zip: '12345',
        country: 'USA',
      },
      logo: '/assets/logo.png',
      favicon: '/assets/favicon.ico',
      primaryColor: '#000000',
      secondaryColor: '#FFFFFF',
      fontFamily: 'Arial',
      domain: 'example.com',
      navigation: [
        { label: 'Home', pageId: 'home', order: 1 },
        { label: 'About', pageId: 'about', order: 2 },
      ],
      privacyPolicyEnabled: true,
      termsOfServiceEnabled: true,
      createdAt: new Date().toISOString(),
      lastModified: new Date().toISOString(),
    };

    it('should save and load site config', async () => {
      await configManager.saveSiteConfig(validSiteConfig);
      const loaded = await configManager.loadSiteConfig();

      expect(loaded.businessName).toBe(validSiteConfig.businessName);
      expect(loaded.email).toBe(validSiteConfig.email);
      expect(loaded.address.city).toBe(validSiteConfig.address.city);
    });

    it('should update lastModified timestamp on save', async () => {
      const originalTimestamp = validSiteConfig.lastModified;
      
      // Wait a bit to ensure timestamp changes
      await new Promise((resolve) => setTimeout(resolve, 10));
      
      await configManager.saveSiteConfig(validSiteConfig);
      const loaded = await configManager.loadSiteConfig();

      expect(loaded.lastModified).not.toBe(originalTimestamp);
    });

    it('should throw error for missing required fields', async () => {
      const invalidConfig = { ...validSiteConfig, businessName: '' };

      await expect(configManager.saveSiteConfig(invalidConfig as SiteConfig)).rejects.toThrow(
        ConfigValidationError
      );
    });

    it('should throw error for invalid address', async () => {
      const invalidConfig = {
        ...validSiteConfig,
        address: { ...validSiteConfig.address, city: '' },
      };

      await expect(configManager.saveSiteConfig(invalidConfig as SiteConfig)).rejects.toThrow(
        ConfigValidationError
      );
    });

    it('should throw error when loading non-existent config', async () => {
      await expect(configManager.loadSiteConfig()).rejects.toThrow('Site configuration not found');
    });

    it('should throw error for invalid JSON', async () => {
      const siteConfigPath = path.join(TEST_CONFIG_DIR, 'site.json');
      await fs.writeFile(siteConfigPath, 'invalid json{', 'utf-8');

      await expect(configManager.loadSiteConfig()).rejects.toThrow(ConfigValidationError);
    });

    describe('Email Validation', () => {
      it('should accept valid email addresses', async () => {
        const validEmails = [
          'user@example.com',
          'test.user@example.com',
          'user+tag@example.co.uk',
          'user_name@example-domain.com',
        ];

        for (const email of validEmails) {
          const config = { ...validSiteConfig, email };
          await expect(configManager.saveSiteConfig(config)).resolves.not.toThrow();
        }
      });

      it('should reject invalid email addresses', async () => {
        const invalidEmails = [
          'invalid',
          'invalid@',
          '@example.com',
          'user@',
          'user @example.com',
          'user@example',
        ];

        for (const email of invalidEmails) {
          const config = { ...validSiteConfig, email };
          await expect(configManager.saveSiteConfig(config)).rejects.toThrow(
            /email must be a valid email address/
          );
        }
      });
    });

    describe('Phone Validation', () => {
      it('should accept valid phone numbers', async () => {
        const validPhones = [
          '555-1234567',
          '(555) 123-4567',
          '+1-555-123-4567',
          '5551234567',
          '+44 20 1234 5678',
          '1234567890',
        ];

        for (const phone of validPhones) {
          const config = { ...validSiteConfig, phone };
          await expect(configManager.saveSiteConfig(config)).resolves.not.toThrow();
        }
      });

      it('should reject invalid phone numbers', async () => {
        const invalidPhones = [
          '123',
          'abc',
          '555',
          '12345', // too short
        ];

        for (const phone of invalidPhones) {
          const config = { ...validSiteConfig, phone };
          await expect(configManager.saveSiteConfig(config)).rejects.toThrow(
            /phone must be a valid phone number/
          );
        }
      });
    });

    describe('Domain Validation', () => {
      it('should accept valid domain names', async () => {
        const validDomains = [
          'example.com',
          'sub.example.com',
          'my-site.example.co.uk',
          'test123.example.org',
        ];

        for (const domain of validDomains) {
          const config = { ...validSiteConfig, domain };
          await expect(configManager.saveSiteConfig(config)).resolves.not.toThrow();
        }
      });

      it('should reject invalid domain names', async () => {
        const invalidDomains = [
          'invalid',
          'http://example.com',
          'example',
          '-example.com',
          'example-.com',
          'example..com',
        ];

        for (const domain of invalidDomains) {
          const config = { ...validSiteConfig, domain };
          await expect(configManager.saveSiteConfig(config)).rejects.toThrow(
            /domain must be a valid domain name/
          );
        }
      });
    });

    describe('Color Validation', () => {
      it('should accept valid hex colors', async () => {
        const validColors = [
          '#000000',
          '#FFFFFF',
          '#FF5733',
          '#abc',
          '#ABC',
          '#123',
        ];

        for (const color of validColors) {
          const config = { ...validSiteConfig, primaryColor: color, secondaryColor: color };
          await expect(configManager.saveSiteConfig(config)).resolves.not.toThrow();
        }
      });

      it('should reject invalid hex colors', async () => {
        const invalidColors = [
          'red',
          '#GGGGGG',
          '#12',
          '#12345',
          '000000',
          '#1234567',
        ];

        for (const color of invalidColors) {
          const config = { ...validSiteConfig, primaryColor: color };
          await expect(configManager.saveSiteConfig(config)).rejects.toThrow(
            /primaryColor must be a valid hex color/
          );
        }
      });
    });
  });

  describe('Page Configuration', () => {
    const validPageConfig: PageConfig = {
      id: 'test-page',
      title: 'Test Page',
      sections: [
        {
          type: 'hero',
          id: 'hero-1',
          order: 1,
          content: {
            headline: 'Welcome',
            subheadline: 'Test page',
          },
        },
      ],
      metaDescription: 'A test page',
      keywords: ['test', 'page'],
      intent: {
        primaryGoal: 'Test goal',
        targetAudience: 'Test audience',
        callsToAction: ['Contact us'],
      },
      createdAt: new Date().toISOString(),
      lastModified: new Date().toISOString(),
      version: 1,
    };

    it('should save and load page config', async () => {
      await configManager.savePageConfig(validPageConfig);
      const loaded = await configManager.loadPageConfig('test-page');

      expect(loaded.id).toBe(validPageConfig.id);
      expect(loaded.title).toBe(validPageConfig.title);
      expect(loaded.sections).toHaveLength(1);
    });

    it('should increment version on save', async () => {
      await configManager.savePageConfig(validPageConfig);
      const loaded1 = await configManager.loadPageConfig('test-page');
      const version1 = loaded1.version;

      await configManager.savePageConfig(loaded1);
      const loaded2 = await configManager.loadPageConfig('test-page');

      expect(loaded2.version).toBe(version1 + 1);
    });

    it('should throw error for missing required fields', async () => {
      const invalidConfig = { ...validPageConfig, title: '' };

      await expect(configManager.savePageConfig(invalidConfig as PageConfig)).rejects.toThrow(
        ConfigValidationError
      );
    });

    it('should throw error when loading non-existent page', async () => {
      await expect(configManager.loadPageConfig('non-existent')).rejects.toThrow(
        'Page configuration not found'
      );
    });

    it('should list all pages', async () => {
      await configManager.savePageConfig(validPageConfig);
      await configManager.savePageConfig({ ...validPageConfig, id: 'page-2' });

      const pages = await configManager.listPages();

      expect(pages).toHaveLength(2);
      expect(pages).toContain('test-page');
      expect(pages).toContain('page-2');
    });

    it('should check if page exists', async () => {
      expect(await configManager.pageConfigExists('test-page')).toBe(false);

      await configManager.savePageConfig(validPageConfig);

      expect(await configManager.pageConfigExists('test-page')).toBe(true);
    });

    describe('PageConfig Validation', () => {
      it('should require metaDescription', async () => {
        const invalidConfig = { ...validPageConfig, metaDescription: '' };
        await expect(configManager.savePageConfig(invalidConfig as PageConfig)).rejects.toThrow(
          /metaDescription is required/
        );
      });

      it('should require keywords array', async () => {
        const invalidConfig = { ...validPageConfig, keywords: 'not-an-array' };
        await expect(configManager.savePageConfig(invalidConfig as any)).rejects.toThrow(
          /keywords must be an array/
        );
      });

      it('should require intent.primaryGoal', async () => {
        const invalidConfig = {
          ...validPageConfig,
          intent: { ...validPageConfig.intent, primaryGoal: '' },
        };
        await expect(configManager.savePageConfig(invalidConfig as PageConfig)).rejects.toThrow(
          /intent.primaryGoal is required/
        );
      });

      it('should require intent.targetAudience', async () => {
        const invalidConfig = {
          ...validPageConfig,
          intent: { ...validPageConfig.intent, targetAudience: '' },
        };
        await expect(configManager.savePageConfig(invalidConfig as PageConfig)).rejects.toThrow(
          /intent.targetAudience is required/
        );
      });

      it('should require intent.callsToAction to be an array', async () => {
        const invalidConfig = {
          ...validPageConfig,
          intent: { ...validPageConfig.intent, callsToAction: 'not-an-array' },
        };
        await expect(configManager.savePageConfig(invalidConfig as any)).rejects.toThrow(
          /intent.callsToAction must be an array/
        );
      });

      it('should accept valid featuredImage URL', async () => {
        const config = { ...validPageConfig, featuredImage: 'https://example.com/image.jpg' };
        await expect(configManager.savePageConfig(config)).resolves.not.toThrow();
      });

      it('should accept valid featuredImage path', async () => {
        const config = { ...validPageConfig, featuredImage: '/assets/image.jpg' };
        await expect(configManager.savePageConfig(config)).resolves.not.toThrow();
      });

      it('should reject invalid featuredImage', async () => {
        const config = { ...validPageConfig, featuredImage: 'not-a-valid-url-or-path' };
        await expect(configManager.savePageConfig(config)).rejects.toThrow(
          /featuredImage must be a valid URL or path/
        );
      });
    });
  });

  describe('Temp Configuration', () => {
    const validTempConfig: TempConfig = {
      id: 'test-page',
      title: 'Test Page',
      sections: [
        {
          type: 'text',
          id: 'text-1',
          order: 1,
          content: {
            body: 'Test content',
          },
        },
      ],
      metaDescription: 'A test page',
      keywords: ['test'],
      intent: {
        primaryGoal: 'Test',
        targetAudience: 'Users',
        callsToAction: [],
      },
      createdAt: new Date().toISOString(),
      lastModified: new Date().toISOString(),
      version: 1,
      sessionId: 'session-123',
      startedAt: new Date().toISOString(),
      conversationHistory: [
        {
          role: 'user',
          content: 'Hello',
          timestamp: new Date().toISOString(),
        },
      ],
    };

    it('should save and load temp config', async () => {
      await configManager.saveTempConfig(validTempConfig);
      const loaded = await configManager.loadTempConfig('test-page');

      expect(loaded.id).toBe(validTempConfig.id);
      expect(loaded.sessionId).toBe(validTempConfig.sessionId);
      expect(loaded.conversationHistory).toHaveLength(1);
    });

    it('should delete temp config', async () => {
      await configManager.saveTempConfig(validTempConfig);
      expect(await configManager.tempConfigExists('test-page')).toBe(true);

      await configManager.deleteTempConfig('test-page');
      expect(await configManager.tempConfigExists('test-page')).toBe(false);
    });

    it('should not throw when deleting non-existent temp config', async () => {
      await expect(configManager.deleteTempConfig('non-existent')).resolves.not.toThrow();
    });

    it('should list all temp configs', async () => {
      await configManager.saveTempConfig(validTempConfig);
      await configManager.saveTempConfig({ ...validTempConfig, id: 'page-2' });

      const tempConfigs = await configManager.listTempConfigs();

      expect(tempConfigs).toHaveLength(2);
      expect(tempConfigs).toContain('test-page');
      expect(tempConfigs).toContain('page-2');
    });

    it('should not include temp configs in page list', async () => {
      const pageConfig: PageConfig = {
        id: 'test-page',
        title: 'Test Page',
        sections: [],
        metaDescription: 'Test',
        keywords: [],
        intent: {
          primaryGoal: 'Test',
          targetAudience: 'Users',
          callsToAction: [],
        },
        createdAt: new Date().toISOString(),
        lastModified: new Date().toISOString(),
        version: 1,
      };

      await configManager.savePageConfig(pageConfig);
      await configManager.saveTempConfig(validTempConfig);

      const pages = await configManager.listPages();
      const tempConfigs = await configManager.listTempConfigs();

      expect(pages).toHaveLength(1);
      expect(pages).toContain('test-page');
      expect(tempConfigs).toHaveLength(1);
      expect(tempConfigs).toContain('test-page');
    });
  });

  describe('Copy Temp to Page', () => {
    it('should copy temp config to page config', async () => {
      const tempConfig: TempConfig = {
        id: 'test-page',
        title: 'Updated Title',
        sections: [
          {
            type: 'text',
            id: 'text-1',
            order: 1,
            content: {
              body: 'Updated content',
            },
          },
        ],
        metaDescription: 'Updated description',
        keywords: ['updated'],
        intent: {
          primaryGoal: 'Updated goal',
          targetAudience: 'Updated audience',
          callsToAction: ['Updated CTA'],
        },
        createdAt: new Date().toISOString(),
        lastModified: new Date().toISOString(),
        version: 1,
        sessionId: 'session-123',
        startedAt: new Date().toISOString(),
        conversationHistory: [
          {
            role: 'user',
            content: 'Test message',
            timestamp: new Date().toISOString(),
          },
        ],
      };

      await configManager.saveTempConfig(tempConfig);
      await configManager.copyTempToPage('test-page');

      const pageConfig = await configManager.loadPageConfig('test-page');

      expect(pageConfig.title).toBe('Updated Title');
      expect(pageConfig.metaDescription).toBe('Updated description');
      expect(pageConfig.sections[0].content.body).toBe('Updated content');
      expect((pageConfig as any).sessionId).toBeUndefined();
      expect((pageConfig as any).conversationHistory).toBeUndefined();
    });

    it('should preserve original page config when temp exists', async () => {
      const originalPage: PageConfig = {
        id: 'test-page',
        title: 'Original Title',
        sections: [],
        metaDescription: 'Original',
        keywords: [],
        intent: {
          primaryGoal: 'Original',
          targetAudience: 'Original',
          callsToAction: [],
        },
        createdAt: new Date().toISOString(),
        lastModified: new Date().toISOString(),
        version: 1,
      };

      const tempConfig: TempConfig = {
        ...originalPage,
        title: 'Temp Title',
        sessionId: 'session-123',
        startedAt: new Date().toISOString(),
        conversationHistory: [],
      };

      await configManager.savePageConfig(originalPage);
      await configManager.saveTempConfig(tempConfig);

      // Load original page - should still have original title
      const loadedOriginal = await configManager.loadPageConfig('test-page');
      expect(loadedOriginal.title).toBe('Original Title');

      // Copy temp to page
      await configManager.copyTempToPage('test-page');

      // Now page should have temp title
      const loadedAfterCopy = await configManager.loadPageConfig('test-page');
      expect(loadedAfterCopy.title).toBe('Temp Title');
    });
  });

  describe('Atomic Write Operations', () => {
    it('should write files atomically', async () => {
      const config: PageConfig = {
        id: 'atomic-test',
        title: 'Atomic Test',
        sections: [],
        metaDescription: 'Test',
        keywords: [],
        intent: {
          primaryGoal: 'Test',
          targetAudience: 'Test',
          callsToAction: [],
        },
        createdAt: new Date().toISOString(),
        lastModified: new Date().toISOString(),
        version: 1,
      };

      await configManager.savePageConfig(config);

      // Check that temp file doesn't exist
      const tempPath = path.join(TEST_CONFIG_DIR, 'pages', 'atomic-test.json.tmp');
      await expect(fs.access(tempPath)).rejects.toThrow();

      // Check that actual file exists
      const actualPath = path.join(TEST_CONFIG_DIR, 'pages', 'atomic-test.json');
      await expect(fs.access(actualPath)).resolves.not.toThrow();
    });
  });

  describe('File Stats and Path Helpers', () => {
    it('should get file stats for existing file', async () => {
      const config: PageConfig = {
        id: 'stats-test',
        title: 'Stats Test',
        sections: [],
        metaDescription: 'Test',
        keywords: [],
        intent: {
          primaryGoal: 'Test',
          targetAudience: 'Test',
          callsToAction: [],
        },
        createdAt: new Date().toISOString(),
        lastModified: new Date().toISOString(),
        version: 1,
      };

      await configManager.savePageConfig(config);

      const filePath = path.join(TEST_CONFIG_DIR, 'pages', 'stats-test.json');
      const stats = await configManager.getFileStats(filePath);

      expect(stats).not.toBeNull();
      expect(stats?.mtimeMs).toBeDefined();
      expect(stats?.size).toBeGreaterThan(0);
    });

    it('should return null for non-existent file', async () => {
      const filePath = path.join(TEST_CONFIG_DIR, 'pages', 'non-existent.json');
      const stats = await configManager.getFileStats(filePath);

      expect(stats).toBeNull();
    });

    it('should get temp config path', () => {
      const tempPath = configManager.getPublicTempConfigPath('test-page');
      
      expect(tempPath).toContain('test-page.temp.json');
      expect(tempPath).toContain('pages');
    });
  });
});

