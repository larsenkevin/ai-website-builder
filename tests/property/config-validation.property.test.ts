import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fc from 'fast-check';
import { ConfigManager, ConfigValidationError } from '../../app/services/ConfigManager.js';
import { SiteConfig, PageConfig } from '../../app/types/config.js';
import fs from 'fs/promises';
import path from 'path';

/**
 * Property 54: Config Parsing
 * 
 * For any valid JSON configuration file, the Config_Parser SHALL successfully 
 * parse it into a configuration object.
 * 
 * **Validates: Requirements 28.1**
 */

/**
 * Property 55: Invalid JSON Error Handling
 * 
 * For any configuration file containing invalid JSON, the Config_Parser SHALL 
 * return a descriptive error message.
 * 
 * **Validates: Requirements 28.2**
 */

/**
 * Property 56: Config Formatting
 * 
 * For any valid configuration object, the Config_Formatter SHALL produce 
 * valid JSON output.
 * 
 * **Validates: Requirements 28.3**
 */

/**
 * Property 57: Required Field Validation in Configs
 * 
 * For any configuration object missing required fields, the Config_Parser 
 * SHALL return a validation error.
 * 
 * **Validates: Requirements 28.5**
 */

describe('Properties 54-57: Configuration Validation', () => {
  const testConfigDir = './test-config-validation';
  let configManager: ConfigManager;

  beforeEach(async () => {
    await fs.mkdir(testConfigDir, { recursive: true });
    await fs.mkdir(path.join(testConfigDir, 'pages'), { recursive: true });
    configManager = new ConfigManager({ configDir: testConfigDir });
  });

  afterEach(async () => {
    try {
      await fs.rm(testConfigDir, { recursive: true, force: true });
    } catch (error) {
      // Ignore cleanup errors
    }
  });

  // Custom arbitraries for generating valid config objects
  const addressArbitrary = fc.record({
    street: fc.string({ minLength: 1, maxLength: 100 }),
    city: fc.string({ minLength: 1, maxLength: 50 }),
    state: fc.string({ minLength: 2, maxLength: 2 }),
    zip: fc.string({ minLength: 5, maxLength: 10 }),
    country: fc.string({ minLength: 2, maxLength: 50 }),
  });

  const navigationItemArbitrary = fc.record({
    label: fc.string({ minLength: 1, maxLength: 50 }),
    pageId: fc.string({ minLength: 1, maxLength: 50 }).map(s => s.replace(/[^a-z0-9-]/gi, '-').toLowerCase()),
    order: fc.integer({ min: 1, max: 100 }),
  });

  const hexColorArbitrary = fc.hexaString({ minLength: 6, maxLength: 6 }).map(s => `#${s}`);

  const emailArbitrary = fc.tuple(
    fc.string({ minLength: 1, maxLength: 20 }).filter(s => /^[a-zA-Z0-9._-]+$/.test(s)),
    fc.string({ minLength: 1, maxLength: 20 }).filter(s => /^[a-zA-Z0-9-]+$/.test(s)),
    fc.constantFrom('com', 'org', 'net', 'edu', 'co.uk')
  ).map(([user, domain, tld]) => `${user}@${domain}.${tld}`);

  const phoneArbitrary = fc.tuple(
    fc.integer({ min: 100, max: 999 }),
    fc.integer({ min: 100, max: 999 }),
    fc.integer({ min: 1000, max: 9999 })
  ).map(([area, prefix, line]) => `${area}-${prefix}-${line}`);

  const domainArbitrary = fc.tuple(
    fc.string({ minLength: 3, maxLength: 20 }).filter(s => /^[a-z0-9][a-z0-9-]*[a-z0-9]$/.test(s)),
    fc.constantFrom('com', 'org', 'net', 'io', 'co')
  ).map(([name, tld]) => `${name}.${tld}`);

  const siteConfigArbitrary = fc.record({
    businessName: fc.string({ minLength: 1, maxLength: 100 }),
    legalName: fc.string({ minLength: 1, maxLength: 100 }),
    industry: fc.string({ minLength: 1, maxLength: 50 }),
    description: fc.string({ minLength: 1, maxLength: 500 }),
    email: emailArbitrary,
    phone: phoneArbitrary,
    address: addressArbitrary,
    logo: fc.constant('/assets/logo.png'),
    favicon: fc.constant('/assets/favicon.ico'),
    primaryColor: hexColorArbitrary,
    secondaryColor: hexColorArbitrary,
    fontFamily: fc.constantFrom('Arial', 'Helvetica', 'Times New Roman', 'Georgia', 'Verdana'),
    domain: domainArbitrary,
    navigation: fc.array(navigationItemArbitrary, { minLength: 1, maxLength: 10 }),
    privacyPolicyEnabled: fc.boolean(),
    termsOfServiceEnabled: fc.boolean(),
    createdAt: fc.date().map(d => d.toISOString()),
    lastModified: fc.date().map(d => d.toISOString()),
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

  const pageIntentArbitrary = fc.record({
    primaryGoal: fc.string({ minLength: 1, maxLength: 200 }),
    targetAudience: fc.string({ minLength: 1, maxLength: 200 }),
    callsToAction: fc.array(fc.string({ minLength: 1, maxLength: 100 }), { minLength: 0, maxLength: 5 }),
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

  describe('Property 54: Config Parsing', () => {
    it('Property: Valid SiteConfig JSON is successfully parsed', async () => {
      await fc.assert(
        fc.asyncProperty(siteConfigArbitrary, async (config) => {
          // Save the config (which formats it as JSON)
          await configManager.saveSiteConfig(config as SiteConfig);

          // Load it back (which parses the JSON)
          const loadedConfig = await configManager.loadSiteConfig();

          // Should successfully parse and return a valid object
          expect(loadedConfig).toBeDefined();
          expect(typeof loadedConfig).toBe('object');
          expect(loadedConfig.businessName).toBe(config.businessName);
        }),
        { numRuns: 30 }
      );
    });

    it('Property: Valid PageConfig JSON is successfully parsed', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (config) => {
          // Save the config (which formats it as JSON)
          await configManager.savePageConfig(config as PageConfig);

          // Load it back (which parses the JSON)
          const loadedConfig = await configManager.loadPageConfig(config.id);

          // Should successfully parse and return a valid object
          expect(loadedConfig).toBeDefined();
          expect(typeof loadedConfig).toBe('object');
          expect(loadedConfig.id).toBe(config.id);
          expect(loadedConfig.title).toBe(config.title);
        }),
        { numRuns: 30 }
      );
    });

    it('Property: Parsing preserves all data types', async () => {
      await fc.assert(
        fc.asyncProperty(siteConfigArbitrary, async (config) => {
          await configManager.saveSiteConfig(config as SiteConfig);
          const loadedConfig = await configManager.loadSiteConfig();

          // Verify data types are preserved
          expect(typeof loadedConfig.businessName).toBe('string');
          expect(typeof loadedConfig.email).toBe('string');
          expect(typeof loadedConfig.privacyPolicyEnabled).toBe('boolean');
          expect(Array.isArray(loadedConfig.navigation)).toBe(true);
          expect(typeof loadedConfig.address).toBe('object');
        }),
        { numRuns: 20 }
      );
    });
  });

  describe('Property 55: Invalid JSON Error Handling', () => {
    it('Property: Invalid JSON in SiteConfig returns descriptive error', async () => {
      // Generate various types of invalid JSON (syntax errors that won't parse)
      const invalidJsonArbitrary = fc.oneof(
        fc.constant('{ invalid json }'),
        fc.constant('{ "businessName": "Test", }'), // Trailing comma
        fc.constant('{ "businessName": "Test" "email": "test@test.com" }'), // Missing comma
        fc.constant('{ "businessName": undefined }'), // Invalid value
        fc.constant('{ businessName: "Test" }'), // Unquoted key
        fc.constant('not json at all'),
        fc.constant('{ "businessName": "Test"'), // Unclosed brace
        fc.constant('{ "businessName": "Test" ]'), // Mismatched brackets
      );

      await fc.assert(
        fc.asyncProperty(invalidJsonArbitrary, async (invalidJson) => {
          // Write invalid JSON directly to file
          const siteConfigPath = path.join(testConfigDir, 'site.json');
          await fs.writeFile(siteConfigPath, invalidJson, 'utf-8');

          // Attempt to load should throw a descriptive error
          await expect(configManager.loadSiteConfig()).rejects.toThrow();
          
          try {
            await configManager.loadSiteConfig();
          } catch (error: any) {
            // Error should be descriptive
            expect(error.message).toBeDefined();
            expect(typeof error.message).toBe('string');
            expect(error.message.length).toBeGreaterThan(0);
            
            // Should mention JSON, parsing, invalid, or validation
            const errorMsg = error.message.toLowerCase();
            expect(
              errorMsg.includes('json') || 
              errorMsg.includes('parse') || 
              errorMsg.includes('invalid') ||
              errorMsg.includes('validation')
            ).toBe(true);
          }
        }),
        { numRuns: 20 }
      );
    });

    it('Property: Invalid JSON in PageConfig returns descriptive error', async () => {
      const invalidJsonArbitrary = fc.oneof(
        fc.constant('{ "id": "test", invalid }'),
        fc.constant('{ "id": "test", }'),
        fc.constant('not json at all'),
        fc.constant('{ "id": "test"'), // Unclosed
      );

      await fc.assert(
        fc.asyncProperty(
          invalidJsonArbitrary,
          fc.string({ minLength: 1, maxLength: 20 }).map(s => s.replace(/[^a-z0-9-]/gi, '-').toLowerCase()),
          async (invalidJson, pageId) => {
            // Write invalid JSON directly to file
            const pageConfigPath = path.join(testConfigDir, 'pages', `${pageId}.json`);
            await fs.writeFile(pageConfigPath, invalidJson, 'utf-8');

            // Attempt to load should throw a descriptive error
            await expect(configManager.loadPageConfig(pageId)).rejects.toThrow();
            
            try {
              await configManager.loadPageConfig(pageId);
            } catch (error: any) {
              // Error should be descriptive
              expect(error.message).toBeDefined();
              expect(typeof error.message).toBe('string');
              expect(error.message.length).toBeGreaterThan(0);
              
              // Should mention JSON or parsing or the page ID
              const errorMsg = error.message.toLowerCase();
              expect(
                errorMsg.includes('json') || 
                errorMsg.includes('parse') || 
                errorMsg.includes('invalid') ||
                errorMsg.includes(pageId.toLowerCase())
              ).toBe(true);
            }
          }
        ),
        { numRuns: 20 }
      );
    });

    it('Property: Error message distinguishes between JSON syntax and validation errors', async () => {
      // Test that we get different error types for syntax vs validation
      const invalidJson = '{ invalid json }';
      const siteConfigPath = path.join(testConfigDir, 'site.json');
      await fs.writeFile(siteConfigPath, invalidJson, 'utf-8');

      try {
        await configManager.loadSiteConfig();
        expect.fail('Should have thrown an error');
      } catch (error: any) {
        // Should be a JSON parsing error, not a validation error
        expect(error.message.toLowerCase()).toContain('json');
      }

      // Now test validation error with valid JSON but missing fields
      const invalidConfig = { businessName: 'Test' }; // Missing required fields
      await fs.writeFile(siteConfigPath, JSON.stringify(invalidConfig), 'utf-8');

      try {
        await configManager.loadSiteConfig();
        expect.fail('Should have thrown an error');
      } catch (error: any) {
        // Should be a validation error
        expect(error.message.toLowerCase()).toContain('validation');
      }
    });
  });

  describe('Property 56: Config Formatting', () => {
    it('Property: Valid SiteConfig produces valid JSON output', async () => {
      await fc.assert(
        fc.asyncProperty(siteConfigArbitrary, async (config) => {
          // Save the config (which formats it as JSON)
          await configManager.saveSiteConfig(config as SiteConfig);

          // Read the raw file
          const siteConfigPath = path.join(testConfigDir, 'site.json');
          const jsonContent = await fs.readFile(siteConfigPath, 'utf-8');

          // Should be valid JSON (parsing should not throw)
          const parsed = JSON.parse(jsonContent);
          expect(parsed).toBeDefined();
          expect(typeof parsed).toBe('object');
          
          // Should contain the original data
          expect(parsed.businessName).toBe(config.businessName);
          expect(parsed.email).toBe(config.email);
        }),
        { numRuns: 30 }
      );
    });

    it('Property: Valid PageConfig produces valid JSON output', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (config) => {
          // Save the config (which formats it as JSON)
          await configManager.savePageConfig(config as PageConfig);

          // Read the raw file
          const pageConfigPath = path.join(testConfigDir, 'pages', `${config.id}.json`);
          const jsonContent = await fs.readFile(pageConfigPath, 'utf-8');

          // Should be valid JSON (parsing should not throw)
          const parsed = JSON.parse(jsonContent);
          expect(parsed).toBeDefined();
          expect(typeof parsed).toBe('object');
          
          // Should contain the original data
          expect(parsed.id).toBe(config.id);
          expect(parsed.title).toBe(config.title);
        }),
        { numRuns: 30 }
      );
    });

    it('Property: Formatted JSON is well-formed and readable', async () => {
      await fc.assert(
        fc.asyncProperty(siteConfigArbitrary, async (config) => {
          await configManager.saveSiteConfig(config as SiteConfig);

          const siteConfigPath = path.join(testConfigDir, 'site.json');
          const jsonContent = await fs.readFile(siteConfigPath, 'utf-8');

          // Should be formatted with indentation (not minified)
          expect(jsonContent).toContain('\n');
          expect(jsonContent).toContain('  '); // 2-space indentation
          
          // Should start and end with braces
          expect(jsonContent.trim().startsWith('{')).toBe(true);
          expect(jsonContent.trim().endsWith('}')).toBe(true);
        }),
        { numRuns: 20 }
      );
    });

    it('Property: Formatted JSON can be re-parsed without loss', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (config) => {
          // Save the config
          await configManager.savePageConfig(config as PageConfig);

          // Read and parse the JSON
          const pageConfigPath = path.join(testConfigDir, 'pages', `${config.id}.json`);
          const jsonContent1 = await fs.readFile(pageConfigPath, 'utf-8');
          const parsed1 = JSON.parse(jsonContent1);

          // Re-format and parse again
          const jsonContent2 = JSON.stringify(parsed1, null, 2);
          const parsed2 = JSON.parse(jsonContent2);

          // Should be equivalent
          expect(parsed2).toEqual(parsed1);
        }),
        { numRuns: 20 }
      );
    });

    it('Property: Special characters are properly escaped in JSON', async () => {
      // Generate configs with special characters
      const specialCharConfig = fc.record({
        businessName: fc.string({ minLength: 1, maxLength: 50 }).map(s => s + '\n\t"\\'),
        legalName: fc.string({ minLength: 1, maxLength: 50 }),
        industry: fc.string({ minLength: 1, maxLength: 50 }),
        description: fc.string({ minLength: 1, maxLength: 100 }).map(s => s + '\r\n'),
        email: emailArbitrary,
        phone: phoneArbitrary,
        address: addressArbitrary,
        logo: fc.constant('/assets/logo.png'),
        favicon: fc.constant('/assets/favicon.ico'),
        primaryColor: hexColorArbitrary,
        secondaryColor: hexColorArbitrary,
        fontFamily: fc.constant('Arial'),
        domain: domainArbitrary,
        navigation: fc.array(navigationItemArbitrary, { minLength: 1, maxLength: 3 }),
        privacyPolicyEnabled: fc.boolean(),
        termsOfServiceEnabled: fc.boolean(),
        createdAt: fc.date().map(d => d.toISOString()),
        lastModified: fc.date().map(d => d.toISOString()),
      });

      await fc.assert(
        fc.asyncProperty(specialCharConfig, async (config) => {
          // Save the config
          await configManager.saveSiteConfig(config as SiteConfig);

          // Read the raw JSON
          const siteConfigPath = path.join(testConfigDir, 'site.json');
          const jsonContent = await fs.readFile(siteConfigPath, 'utf-8');

          // Should parse successfully despite special characters
          const parsed = JSON.parse(jsonContent);
          expect(parsed.businessName).toBe(config.businessName);
          expect(parsed.description).toBe(config.description);
        }),
        { numRuns: 20 }
      );
    });
  });

  describe('Property 57: Required Field Validation', () => {
    it('Property: SiteConfig missing businessName is rejected', async () => {
      await fc.assert(
        fc.asyncProperty(siteConfigArbitrary, async (config) => {
          const invalidConfig = { ...config, businessName: undefined };
          
          await expect(
            configManager.saveSiteConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
          
          try {
            await configManager.saveSiteConfig(invalidConfig as any);
          } catch (error: any) {
            expect(error.message.toLowerCase()).toContain('businessname');
          }
        }),
        { numRuns: 10 }
      );
    });

    it('Property: SiteConfig missing email is rejected', async () => {
      await fc.assert(
        fc.asyncProperty(siteConfigArbitrary, async (config) => {
          const invalidConfig = { ...config, email: undefined };
          
          await expect(
            configManager.saveSiteConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
          
          try {
            await configManager.saveSiteConfig(invalidConfig as any);
          } catch (error: any) {
            expect(error.message.toLowerCase()).toContain('email');
          }
        }),
        { numRuns: 10 }
      );
    });

    it('Property: SiteConfig with invalid email format is rejected', async () => {
      const invalidEmails = fc.oneof(
        fc.constant('not-an-email'),
        fc.constant('missing@domain'),
        fc.constant('@nodomain.com'),
        fc.constant('no-at-sign.com'),
        fc.constant('spaces in@email.com'),
        fc.constant(''),
      );

      await fc.assert(
        fc.asyncProperty(siteConfigArbitrary, invalidEmails, async (config, invalidEmail) => {
          const invalidConfig = { ...config, email: invalidEmail };
          
          await expect(
            configManager.saveSiteConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
          
          try {
            await configManager.saveSiteConfig(invalidConfig as any);
          } catch (error: any) {
            expect(error.message.toLowerCase()).toContain('email');
          }
        }),
        { numRuns: 15 }
      );
    });

    it('Property: SiteConfig with invalid phone format is rejected', async () => {
      const invalidPhones = fc.oneof(
        fc.constant('123'), // Too short
        fc.constant('abc-def-ghij'), // Not numbers
        fc.constant(''), // Empty
      );

      await fc.assert(
        fc.asyncProperty(siteConfigArbitrary, invalidPhones, async (config, invalidPhone) => {
          const invalidConfig = { ...config, phone: invalidPhone };
          
          await expect(
            configManager.saveSiteConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
          
          try {
            await configManager.saveSiteConfig(invalidConfig as any);
          } catch (error: any) {
            expect(error.message.toLowerCase()).toContain('phone');
          }
        }),
        { numRuns: 10 }
      );
    });

    it('Property: SiteConfig with invalid domain format is rejected', async () => {
      const invalidDomains = fc.oneof(
        fc.constant('not a domain'),
        fc.constant('http://example.com'), // Should not include protocol
        fc.constant('example'), // Missing TLD
        fc.constant('.com'), // Missing domain name
        fc.constant(''),
      );

      await fc.assert(
        fc.asyncProperty(siteConfigArbitrary, invalidDomains, async (config, invalidDomain) => {
          const invalidConfig = { ...config, domain: invalidDomain };
          
          await expect(
            configManager.saveSiteConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
          
          try {
            await configManager.saveSiteConfig(invalidConfig as any);
          } catch (error: any) {
            expect(error.message.toLowerCase()).toContain('domain');
          }
        }),
        { numRuns: 10 }
      );
    });

    it('Property: SiteConfig missing address is rejected', async () => {
      await fc.assert(
        fc.asyncProperty(siteConfigArbitrary, async (config) => {
          const invalidConfig = { ...config, address: undefined };
          
          await expect(
            configManager.saveSiteConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
          
          try {
            await configManager.saveSiteConfig(invalidConfig as any);
          } catch (error: any) {
            expect(error.message.toLowerCase()).toContain('address');
          }
        }),
        { numRuns: 10 }
      );
    });

    it('Property: SiteConfig with incomplete address is rejected', async () => {
      const addressFields = ['street', 'city', 'state', 'zip', 'country'];
      
      await fc.assert(
        fc.asyncProperty(
          siteConfigArbitrary,
          fc.constantFrom(...addressFields),
          async (config, fieldToRemove) => {
            const invalidAddress = { ...config.address };
            delete (invalidAddress as any)[fieldToRemove];
            const invalidConfig = { ...config, address: invalidAddress };
            
            await expect(
              configManager.saveSiteConfig(invalidConfig as any)
            ).rejects.toThrow(ConfigValidationError);
            
            try {
              await configManager.saveSiteConfig(invalidConfig as any);
            } catch (error: any) {
              expect(error.message.toLowerCase()).toContain('address');
              expect(error.message.toLowerCase()).toContain(fieldToRemove.toLowerCase());
            }
          }
        ),
        { numRuns: 15 }
      );
    });

    it('Property: PageConfig missing id is rejected', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (config) => {
          const invalidConfig = { ...config, id: undefined };
          
          await expect(
            configManager.savePageConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
          
          try {
            await configManager.savePageConfig(invalidConfig as any);
          } catch (error: any) {
            expect(error.message.toLowerCase()).toContain('id');
          }
        }),
        { numRuns: 10 }
      );
    });

    it('Property: PageConfig missing title is rejected', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (config) => {
          const invalidConfig = { ...config, title: undefined };
          
          await expect(
            configManager.savePageConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
          
          try {
            await configManager.savePageConfig(invalidConfig as any);
          } catch (error: any) {
            expect(error.message.toLowerCase()).toContain('title');
          }
        }),
        { numRuns: 10 }
      );
    });

    it('Property: PageConfig missing metaDescription is rejected', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (config) => {
          const invalidConfig = { ...config, metaDescription: undefined };
          
          await expect(
            configManager.savePageConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
          
          try {
            await configManager.savePageConfig(invalidConfig as any);
          } catch (error: any) {
            expect(error.message.toLowerCase()).toContain('metadescription');
          }
        }),
        { numRuns: 10 }
      );
    });

    it('Property: PageConfig missing intent is rejected', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (config) => {
          const invalidConfig = { ...config, intent: undefined };
          
          await expect(
            configManager.savePageConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
          
          try {
            await configManager.savePageConfig(invalidConfig as any);
          } catch (error: any) {
            expect(error.message.toLowerCase()).toContain('intent');
          }
        }),
        { numRuns: 10 }
      );
    });

    it('Property: PageConfig with incomplete intent is rejected', async () => {
      const intentFields = ['primaryGoal', 'targetAudience', 'callsToAction'];
      
      await fc.assert(
        fc.asyncProperty(
          pageConfigArbitrary,
          fc.constantFrom(...intentFields),
          async (config, fieldToRemove) => {
            const invalidIntent = { ...config.intent };
            delete (invalidIntent as any)[fieldToRemove];
            const invalidConfig = { ...config, intent: invalidIntent };
            
            await expect(
              configManager.savePageConfig(invalidConfig as any)
            ).rejects.toThrow(ConfigValidationError);
            
            try {
              await configManager.savePageConfig(invalidConfig as any);
            } catch (error: any) {
              expect(error.message.toLowerCase()).toContain('intent');
            }
          }
        ),
        { numRuns: 15 }
      );
    });

    it('Property: PageConfig with non-array sections is rejected', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (config) => {
          const invalidConfig = { ...config, sections: 'not an array' };
          
          await expect(
            configManager.savePageConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
        }),
        { numRuns: 10 }
      );
    });

    it('Property: PageConfig with non-array keywords is rejected', async () => {
      await fc.assert(
        fc.asyncProperty(pageConfigArbitrary, async (config) => {
          const invalidConfig = { ...config, keywords: 'not an array' };
          
          await expect(
            configManager.savePageConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
        }),
        { numRuns: 10 }
      );
    });

    it('Property: Multiple missing required fields produce comprehensive error', async () => {
      await fc.assert(
        fc.asyncProperty(siteConfigArbitrary, async (config) => {
          // Remove multiple required fields
          const invalidConfig = {
            ...config,
            businessName: undefined,
            email: undefined,
            phone: undefined,
          };
          
          await expect(
            configManager.saveSiteConfig(invalidConfig as any)
          ).rejects.toThrow(ConfigValidationError);
          
          try {
            await configManager.saveSiteConfig(invalidConfig as any);
          } catch (error: any) {
            // Error should mention validation failure
            expect(error.message.toLowerCase()).toContain('validation');
            // Should be comprehensive (mention multiple issues or be a combined message)
            expect(error.message.length).toBeGreaterThan(20);
          }
        }),
        { numRuns: 10 }
      );
    });

    it('Property: Validation errors are descriptive and actionable', async () => {
      await fc.assert(
        fc.asyncProperty(
          siteConfigArbitrary,
          fc.constantFrom('businessName', 'email', 'phone', 'domain'),
          async (config, fieldToRemove) => {
            const invalidConfig = { ...config };
            delete (invalidConfig as any)[fieldToRemove];
            
            try {
              await configManager.saveSiteConfig(invalidConfig as any);
              expect.fail('Should have thrown validation error');
            } catch (error: any) {
              // Error should be descriptive
              expect(error.message).toBeDefined();
              expect(typeof error.message).toBe('string');
              expect(error.message.length).toBeGreaterThan(10);
              
              // Should mention the specific field
              expect(error.message.toLowerCase()).toContain(fieldToRemove.toLowerCase());
              
              // Should indicate it's required or missing
              const msg = error.message.toLowerCase();
              expect(
                msg.includes('required') || 
                msg.includes('missing') || 
                msg.includes('must be')
              ).toBe(true);
            }
          }
        ),
        { numRuns: 15 }
      );
    });
  });
});
