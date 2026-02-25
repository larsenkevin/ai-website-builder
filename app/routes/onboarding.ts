/**
 * Onboarding Routes
 * 
 * Handles initial setup and configuration for new users.
 */

import { Router, Request, Response } from 'express';
import { ConfigManager } from '../services/ConfigManager.js';
import { TemplateGenerator } from '../services/TemplateGenerator.js';
import { StaticGenerator } from '../services/StaticGenerator.js';
import { Logger } from '../services/Logger.js';
import { SiteConfig, PageConfig, NavigationItem } from '../types/config.js';

export function createOnboardingRouter(
  configManager: ConfigManager,
  templateGenerator: TemplateGenerator,
  staticGenerator: StaticGenerator,
  logger: Logger
): Router {
  const router = Router();

  /**
   * POST /api/onboarding
   * Process onboarding form and create initial site configuration
   */
  router.post('/', async (req: Request, res: Response): Promise<void> => {
    try {
      logger.info('Processing onboarding request');

      const {
        businessName,
        legalName,
        industry,
        description,
        email,
        phone,
        address,
        primaryColor,
        secondaryColor,
        fontFamily,
        domain,
        selectedPages,
        privacyPolicyEnabled,
        termsOfServiceEnabled,
      } = req.body;

      // Validate required fields
      if (!businessName || !email || !domain) {
        res.status(400).json({
          error: 'Missing required fields: businessName, email, domain',
        });
        return;
      }

      // Create site configuration
      const siteConfig: SiteConfig = {
        businessName,
        legalName: legalName || businessName,
        industry: industry || '',
        description: description || '',
        email,
        phone: phone || '',
        address: address || {
          street: '',
          city: '',
          state: '',
          zip: '',
          country: '',
        },
        logo: '',
        favicon: '',
        primaryColor: primaryColor || '#333333',
        secondaryColor: secondaryColor || '#666666',
        fontFamily: fontFamily || 'system-ui, -apple-system, sans-serif',
        domain,
        navigation: [],
        privacyPolicyEnabled: privacyPolicyEnabled || false,
        termsOfServiceEnabled: termsOfServiceEnabled || false,
        createdAt: new Date().toISOString(),
        lastModified: new Date().toISOString(),
      };

      // Save site configuration
      await configManager.saveSiteConfig(siteConfig);

      // Create page configurations for selected pages
      const pages: string[] = selectedPages || ['home', 'about', 'contact'];
      const navigation: NavigationItem[] = [];

      for (let i = 0; i < pages.length; i++) {
        const pageId = pages[i];
        const pageConfig: PageConfig = {
          id: pageId,
          title: pageId.charAt(0).toUpperCase() + pageId.slice(1),
          sections: [
            {
              type: 'hero',
              id: 'hero-1',
              order: 1,
              content: {
                headline: `Welcome to ${businessName}`,
                subheadline: description || 'Your trusted partner',
                ctaText: 'Get Started',
                ctaLink: '/contact.html',
              },
            },
          ],
          metaDescription: `${pageId} page for ${businessName}`,
          keywords: [pageId, businessName.toLowerCase(), industry.toLowerCase()],
          intent: {
            primaryGoal: 'Provide information',
            targetAudience: 'General public',
            callsToAction: ['Contact us'],
          },
          createdAt: new Date().toISOString(),
          lastModified: new Date().toISOString(),
          version: 1,
        };

        await configManager.savePageConfig(pageConfig);

        navigation.push({
          label: pageConfig.title,
          pageId,
          order: i + 1,
        });
      }

      // Generate legal pages if enabled
      if (privacyPolicyEnabled) {
        const privacyPolicy = templateGenerator.generatePrivacyPolicy(siteConfig);
        await configManager.savePageConfig(privacyPolicy);
        navigation.push({
          label: 'Privacy Policy',
          pageId: 'privacy',
          order: navigation.length + 1,
        });
      }

      if (termsOfServiceEnabled) {
        const termsOfService = templateGenerator.generateTermsOfService(siteConfig);
        await configManager.savePageConfig(termsOfService);
        navigation.push({
          label: 'Terms of Service',
          pageId: 'terms',
          order: navigation.length + 1,
        });
      }

      // Update site config with navigation
      siteConfig.navigation = navigation;
      await configManager.saveSiteConfig(siteConfig);

      // Generate initial site
      await staticGenerator.generateSite();

      logger.info('Onboarding completed successfully', {
        businessName,
        pageCount: pages.length,
      });

      res.json({
        success: true,
        message: 'Onboarding completed successfully',
        siteConfig,
      });
    } catch (error: any) {
      logger.error('Onboarding failed', {
        error: error.message,
        stack: error.stack,
      });

      res.status(500).json({
        error: 'Onboarding failed',
        message: error.message,
      });
    }
  });

  return router;
}
