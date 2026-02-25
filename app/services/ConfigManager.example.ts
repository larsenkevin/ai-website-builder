/**
 * ConfigManager Usage Examples
 * 
 * This file demonstrates how to use the ConfigManager service
 * for managing site and page configurations.
 */

import { configManager } from './ConfigManager.js';
import { SiteConfig, PageConfig, TempConfig } from '../types/config.js';

/**
 * Example 1: Creating and saving a site configuration
 */
async function createSiteConfig() {
  const siteConfig: SiteConfig = {
    businessName: 'Acme Corporation',
    legalName: 'Acme Corporation LLC',
    industry: 'Technology',
    description: 'Leading provider of innovative solutions',
    email: 'contact@acme.com',
    phone: '555-0123',
    address: {
      street: '123 Tech Street',
      city: 'San Francisco',
      state: 'CA',
      zip: '94105',
      country: 'USA',
    },
    logo: '/assets/logo.png',
    favicon: '/assets/favicon.ico',
    primaryColor: '#0066CC',
    secondaryColor: '#FF6600',
    fontFamily: 'Inter, sans-serif',
    domain: 'acme.com',
    navigation: [
      { label: 'Home', pageId: 'home', order: 1 },
      { label: 'About', pageId: 'about', order: 2 },
      { label: 'Services', pageId: 'services', order: 3 },
      { label: 'Contact', pageId: 'contact', order: 4 },
    ],
    privacyPolicyEnabled: true,
    termsOfServiceEnabled: true,
    createdAt: new Date().toISOString(),
    lastModified: new Date().toISOString(),
  };

  try {
    await configManager.saveSiteConfig(siteConfig);
    console.log('Site configuration saved successfully');
  } catch (error) {
    console.error('Failed to save site configuration:', error);
  }
}

/**
 * Example 2: Loading and updating site configuration
 */
async function updateSiteConfig() {
  try {
    // Load existing config
    const siteConfig = await configManager.loadSiteConfig();
    
    // Update some fields
    siteConfig.description = 'Updated description';
    siteConfig.primaryColor = '#0099FF';
    
    // Save updated config
    await configManager.saveSiteConfig(siteConfig);
    console.log('Site configuration updated successfully');
  } catch (error) {
    console.error('Failed to update site configuration:', error);
  }
}

/**
 * Example 3: Creating a page configuration
 */
async function createPageConfig() {
  const pageConfig: PageConfig = {
    id: 'home',
    title: 'Welcome to Acme',
    sections: [
      {
        type: 'hero',
        id: 'hero-1',
        order: 1,
        content: {
          headline: 'Innovative Solutions for Modern Businesses',
          subheadline: 'Transform your business with cutting-edge technology',
          backgroundImage: '/assets/hero-bg.jpg',
          ctaText: 'Get Started',
          ctaLink: '/contact',
        },
      },
      {
        type: 'text',
        id: 'intro-1',
        order: 2,
        content: {
          heading: 'About Us',
          body: 'We are a leading provider of innovative technology solutions...',
        },
      },
    ],
    metaDescription: 'Acme Corporation - Leading provider of innovative solutions',
    keywords: ['technology', 'innovation', 'solutions'],
    featuredImage: '/assets/home-featured.jpg',
    intent: {
      primaryGoal: 'Generate leads',
      targetAudience: 'Small to medium businesses',
      callsToAction: ['Contact us', 'Schedule a demo'],
    },
    createdAt: new Date().toISOString(),
    lastModified: new Date().toISOString(),
    version: 1,
  };

  try {
    await configManager.savePageConfig(pageConfig);
    console.log('Page configuration saved successfully');
  } catch (error) {
    console.error('Failed to save page configuration:', error);
  }
}

/**
 * Example 4: Starting an editing session with temp config
 */
async function startEditingSession(pageId: string) {
  try {
    // Load the current page config
    const pageConfig = await configManager.loadPageConfig(pageId);
    
    // Create a temp config for editing
    const tempConfig: TempConfig = {
      ...pageConfig,
      sessionId: 'session-' + Date.now(),
      startedAt: new Date().toISOString(),
      conversationHistory: [],
    };
    
    // Save temp config
    await configManager.saveTempConfig(tempConfig);
    console.log('Editing session started');
    
    return tempConfig;
  } catch (error) {
    console.error('Failed to start editing session:', error);
    throw error;
  }
}

/**
 * Example 5: Updating temp config during editing
 */
async function updateTempConfig(pageId: string, userMessage: string, aiResponse: string) {
  try {
    // Load temp config
    const tempConfig = await configManager.loadTempConfig(pageId);
    
    // Add conversation messages
    tempConfig.conversationHistory.push({
      role: 'user',
      content: userMessage,
      timestamp: new Date().toISOString(),
    });
    
    tempConfig.conversationHistory.push({
      role: 'assistant',
      content: aiResponse,
      timestamp: new Date().toISOString(),
    });
    
    // Update content based on AI suggestions
    tempConfig.sections[0].content.headline = 'Updated headline from AI';
    
    // Save updated temp config
    await configManager.saveTempConfig(tempConfig);
    console.log('Temp config updated');
  } catch (error) {
    console.error('Failed to update temp config:', error);
  }
}

/**
 * Example 6: Confirming changes (copy temp to page)
 */
async function confirmChanges(pageId: string) {
  try {
    // Copy temp config to page config
    await configManager.copyTempToPage(pageId);
    
    // Delete temp config
    await configManager.deleteTempConfig(pageId);
    
    console.log('Changes confirmed and published');
  } catch (error) {
    console.error('Failed to confirm changes:', error);
  }
}

/**
 * Example 7: Canceling changes
 */
async function cancelChanges(pageId: string) {
  try {
    // Just delete the temp config, preserving the original
    await configManager.deleteTempConfig(pageId);
    console.log('Changes canceled');
  } catch (error) {
    console.error('Failed to cancel changes:', error);
  }
}

/**
 * Example 8: Listing all pages
 */
async function listAllPages() {
  try {
    const pages = await configManager.listPages();
    console.log('Pages:', pages);
    
    for (const pageId of pages) {
      const config = await configManager.loadPageConfig(pageId);
      console.log(`- ${pageId}: ${config.title} (v${config.version})`);
    }
  } catch (error) {
    console.error('Failed to list pages:', error);
  }
}

/**
 * Example 9: Checking for abandoned temp configs
 */
async function checkAbandonedSessions() {
  try {
    const tempConfigs = await configManager.listTempConfigs();
    const now = Date.now();
    const twentyFourHours = 24 * 60 * 60 * 1000;
    
    for (const pageId of tempConfigs) {
      const tempConfig = await configManager.loadTempConfig(pageId);
      const startedAt = new Date(tempConfig.startedAt).getTime();
      const age = now - startedAt;
      
      if (age > twentyFourHours) {
        console.log(`Abandoned session found for page: ${pageId}`);
        await configManager.deleteTempConfig(pageId);
        console.log(`Cleaned up abandoned session: ${pageId}`);
      }
    }
  } catch (error) {
    console.error('Failed to check abandoned sessions:', error);
  }
}

/**
 * Example 10: Error handling
 */
async function handleErrors() {
  try {
    // Try to load non-existent page
    await configManager.loadPageConfig('non-existent');
  } catch (error: any) {
    console.error('Expected error:', error.message);
  }
  
  try {
    // Try to save invalid config
    const invalidConfig = {
      id: 'test',
      title: '', // Empty title - validation will fail
    } as PageConfig;
    
    await configManager.savePageConfig(invalidConfig);
  } catch (error: any) {
    console.error('Validation error:', error.message);
  }
}

// Export examples for use in other files
export {
  createSiteConfig,
  updateSiteConfig,
  createPageConfig,
  startEditingSession,
  updateTempConfig,
  confirmChanges,
  cancelChanges,
  listAllPages,
  checkAbandonedSessions,
  handleErrors,
};
