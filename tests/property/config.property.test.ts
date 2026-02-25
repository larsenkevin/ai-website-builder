import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fc from 'fast-check';
import { ConfigManager } from '../../app/services/ConfigManager.js';
import { SiteConfig, PageConfig } from '../../app/types/config.js';
import fs from 'fs/promises';
import path from 'path';

/**
 * Property 1: Configuration Round Trip
 * 
 * For any valid configuration object (SiteConfig or PageConfig), serializing to JSON 
 * then parsing back SHALL produce an equivalent object.
 * 
 * **Validates: Requirements 4.6, 28.4**
 */

describe('Property 1: Configuration Round Trip', () => {
  const testConfigDir = './test-config-property';
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

  it('Property: SiteConfig round trip preserves data', async () => {
    await fc.assert(
      fc.asyncProperty(siteConfigArbitrary, async (originalConfig) => {
        // Save the config
        await configManager.saveSiteConfig(originalConfig as SiteConfig);

        // Load it back
        const loadedConfig = await configManager.loadSiteConfig();

        // Compare all fields (except lastModified which gets updated on save)
        expect(loadedConfig.businessName).toBe(originalConfig.businessName);
        expect(loadedConfig.legalName).toBe(originalConfig.legalName);
        expect(loadedConfig.industry).toBe(originalConfig.industry);
        expect(loadedConfig.description).toBe(originalConfig.description);
        expect(loadedConfig.email).toBe(originalConfig.email);
        expect(loadedConfig.phone).toBe(originalConfig.phone);
        expect(loadedConfig.address).toEqual(originalConfig.address);
        expect(loadedConfig.logo).toBe(originalConfig.logo);
        expect(loadedConfig.favicon).toBe(originalConfig.favicon);
        expect(loadedConfig.primaryColor).toBe(originalConfig.primaryColor);
        expect(loadedConfig.secondaryColor).toBe(originalConfig.secondaryColor);
        expect(loadedConfig.fontFamily).toBe(originalConfig.fontFamily);
        expect(loadedConfig.domain).toBe(originalConfig.domain);
        expect(loadedConfig.navigation).toEqual(originalConfig.navigation);
        expect(loadedConfig.privacyPolicyEnabled).toBe(originalConfig.privacyPolicyEnabled);
        expect(loadedConfig.termsOfServiceEnabled).toBe(originalConfig.termsOfServiceEnabled);
        expect(loadedConfig.createdAt).toBe(originalConfig.createdAt);
        // lastModified is updated on save, so we just verify it's a valid ISO string
        expect(new Date(loadedConfig.lastModified).toISOString()).toBe(loadedConfig.lastModified);
      }),
      { numRuns: 20 }
    );
  });

  it('Property: PageConfig round trip preserves data', async () => {
    await fc.assert(
      fc.asyncProperty(pageConfigArbitrary, async (originalConfig) => {
        // Create a unique ID to avoid conflicts between test runs
        const uniqueId = `${originalConfig.id}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        const configToSave = { ...originalConfig, id: uniqueId } as PageConfig;
        
        // Capture the original version before save (since savePageConfig mutates the object)
        const originalVersion = configToSave.version;
        
        // Save the config
        await configManager.savePageConfig(configToSave);

        // Load it back
        const loadedConfig = await configManager.loadPageConfig(uniqueId);

        // Compare all fields (except lastModified and version which get updated on save)
        expect(loadedConfig.id).toBe(uniqueId);
        expect(loadedConfig.title).toBe(configToSave.title);
        expect(loadedConfig.sections).toEqual(configToSave.sections);
        expect(loadedConfig.metaDescription).toBe(configToSave.metaDescription);
        expect(loadedConfig.keywords).toEqual(configToSave.keywords);
        expect(loadedConfig.featuredImage).toBe(configToSave.featuredImage);
        expect(loadedConfig.intent).toEqual(configToSave.intent);
        expect(loadedConfig.createdAt).toBe(configToSave.createdAt);
        // lastModified is updated on save, so we just verify it's a valid ISO string
        expect(new Date(loadedConfig.lastModified).toISOString()).toBe(loadedConfig.lastModified);
        // version is incremented on save
        expect(loadedConfig.version).toBe(originalVersion + 1);
      }),
      { numRuns: 20 }
    );
  });

  it('Property: Multiple round trips preserve data integrity', async () => {
    await fc.assert(
      fc.asyncProperty(
        siteConfigArbitrary,
        fc.integer({ min: 2, max: 5 }),
        async (originalConfig, iterations) => {
          let currentConfig = originalConfig as SiteConfig;

          for (let i = 0; i < iterations; i++) {
            // Save and load
            await configManager.saveSiteConfig(currentConfig);
            currentConfig = await configManager.loadSiteConfig();
          }

          // After multiple round trips, core data should still match
          expect(currentConfig.businessName).toBe(originalConfig.businessName);
          expect(currentConfig.email).toBe(originalConfig.email);
          expect(currentConfig.address).toEqual(originalConfig.address);
          expect(currentConfig.navigation).toEqual(originalConfig.navigation);
        }
      ),
      { numRuns: 10 }
    );
  });

  it('Property: JSON serialization is idempotent', async () => {
    await fc.assert(
      fc.asyncProperty(pageConfigArbitrary, async (originalConfig) => {
        // Save the config
        await configManager.savePageConfig(originalConfig as PageConfig);

        // Read the raw JSON file
        const filePath = path.join(testConfigDir, 'pages', `${originalConfig.id}.json`);
        const jsonContent1 = await fs.readFile(filePath, 'utf-8');
        const parsed1 = JSON.parse(jsonContent1);

        // Parse and re-serialize
        const jsonContent2 = JSON.stringify(parsed1, null, 2);
        const parsed2 = JSON.parse(jsonContent2);

        // Both parsed objects should be deeply equal
        expect(parsed2).toEqual(parsed1);
      }),
      { numRuns: 20 }
    );
  });

  it('Property: Config files contain valid JSON', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.oneof(
          siteConfigArbitrary.map(c => ({ type: 'site' as const, config: c })),
          pageConfigArbitrary.map(c => ({ type: 'page' as const, config: c }))
        ),
        async ({ type, config }) => {
          if (type === 'site') {
            await configManager.saveSiteConfig(config as SiteConfig);
            const filePath = path.join(testConfigDir, 'site.json');
            const content = await fs.readFile(filePath, 'utf-8');
            
            // Should parse without error
            const parsed = JSON.parse(content);
            expect(parsed).toBeDefined();
            expect(typeof parsed).toBe('object');
          } else {
            await configManager.savePageConfig(config as PageConfig);
            const filePath = path.join(testConfigDir, 'pages', `${config.id}.json`);
            const content = await fs.readFile(filePath, 'utf-8');
            
            // Should parse without error
            const parsed = JSON.parse(content);
            expect(parsed).toBeDefined();
            expect(typeof parsed).toBe('object');
          }
        }
      ),
      { numRuns: 30 }
    );
  });

  it('Property: Nested objects are preserved through round trip', async () => {
    await fc.assert(
      fc.asyncProperty(siteConfigArbitrary, async (originalConfig) => {
        await configManager.saveSiteConfig(originalConfig as SiteConfig);
        const loadedConfig = await configManager.loadSiteConfig();

        // Verify nested address object
        expect(loadedConfig.address.street).toBe(originalConfig.address.street);
        expect(loadedConfig.address.city).toBe(originalConfig.address.city);
        expect(loadedConfig.address.state).toBe(originalConfig.address.state);
        expect(loadedConfig.address.zip).toBe(originalConfig.address.zip);
        expect(loadedConfig.address.country).toBe(originalConfig.address.country);

        // Verify navigation array with nested objects
        expect(loadedConfig.navigation.length).toBe(originalConfig.navigation.length);
        for (let i = 0; i < originalConfig.navigation.length; i++) {
          expect(loadedConfig.navigation[i].label).toBe(originalConfig.navigation[i].label);
          expect(loadedConfig.navigation[i].pageId).toBe(originalConfig.navigation[i].pageId);
          expect(loadedConfig.navigation[i].order).toBe(originalConfig.navigation[i].order);
        }
      }),
      { numRuns: 20 }
    );
  });

  it('Property: Arrays are preserved through round trip', async () => {
    await fc.assert(
      fc.asyncProperty(pageConfigArbitrary, async (originalConfig) => {
        await configManager.savePageConfig(originalConfig as PageConfig);
        const loadedConfig = await configManager.loadPageConfig(originalConfig.id);

        // Verify sections array
        expect(loadedConfig.sections.length).toBe(originalConfig.sections.length);
        expect(loadedConfig.sections).toEqual(originalConfig.sections);

        // Verify keywords array
        expect(loadedConfig.keywords.length).toBe(originalConfig.keywords.length);
        expect(loadedConfig.keywords).toEqual(originalConfig.keywords);

        // Verify callsToAction array
        expect(loadedConfig.intent.callsToAction.length).toBe(originalConfig.intent.callsToAction.length);
        expect(loadedConfig.intent.callsToAction).toEqual(originalConfig.intent.callsToAction);
      }),
      { numRuns: 20 }
    );
  });

  it('Property: Boolean values are preserved through round trip', async () => {
    await fc.assert(
      fc.asyncProperty(siteConfigArbitrary, async (originalConfig) => {
        await configManager.saveSiteConfig(originalConfig as SiteConfig);
        const loadedConfig = await configManager.loadSiteConfig();

        expect(loadedConfig.privacyPolicyEnabled).toBe(originalConfig.privacyPolicyEnabled);
        expect(loadedConfig.termsOfServiceEnabled).toBe(originalConfig.termsOfServiceEnabled);
        expect(typeof loadedConfig.privacyPolicyEnabled).toBe('boolean');
        expect(typeof loadedConfig.termsOfServiceEnabled).toBe('boolean');
      }),
      { numRuns: 20 }
    );
  });

  it('Property: Optional fields are preserved through round trip', async () => {
    await fc.assert(
      fc.asyncProperty(pageConfigArbitrary, async (originalConfig) => {
        await configManager.savePageConfig(originalConfig as PageConfig);
        const loadedConfig = await configManager.loadPageConfig(originalConfig.id);

        // featuredImage is optional
        if (originalConfig.featuredImage === undefined) {
          expect(loadedConfig.featuredImage).toBeUndefined();
        } else {
          expect(loadedConfig.featuredImage).toBe(originalConfig.featuredImage);
        }
      }),
      { numRuns: 20 }
    );
  });
});
