/**
 * TemplateGenerator Service
 * 
 * Generates legal page templates (Privacy Policy, Terms of Service)
 * populated with business information.
 */

import { SiteConfig, PageConfig, ContentSection } from '../types/config.js';
import { Logger } from './Logger.js';

export class TemplateGenerator {
  private logger: Logger;

  constructor(logger: Logger) {
    this.logger = logger;
  }

  /**
   * Generate Privacy Policy page
   */
  generatePrivacyPolicy(siteConfig: SiteConfig): PageConfig {
    this.logger.debug('Generating privacy policy', {
      businessName: siteConfig.businessName,
    });

    const sections: ContentSection[] = [
      {
        type: 'text',
        id: 'intro',
        order: 1,
        content: {
          heading: 'Privacy Policy',
          body: `
<p>Last updated: ${new Date().toLocaleDateString()}</p>

<p>${siteConfig.businessName} ("we", "our", or "us") is committed to protecting your privacy. 
This Privacy Policy explains how we collect, use, and safeguard your information when 
you visit our website ${siteConfig.domain}.</p>
          `,
        },
      },
      {
        type: 'text',
        id: 'information-collection',
        order: 2,
        content: {
          heading: 'Information We Collect',
          body: `
<p>We may collect information that you provide directly to us, including:</p>
<ul>
  <li>Name and contact information</li>
  <li>Email address</li>
  <li>Phone number</li>
  <li>Any other information you choose to provide</li>
</ul>

<p><strong>[Customizable section]</strong> - You can customize this section based on your specific data collection practices.</p>
          `,
        },
      },
      {
        type: 'text',
        id: 'information-use',
        order: 3,
        content: {
          heading: 'How We Use Your Information',
          body: `
<p>We use the information we collect to:</p>
<ul>
  <li>Provide and maintain our services</li>
  <li>Respond to your inquiries and requests</li>
  <li>Send you updates and marketing communications (with your consent)</li>
  <li>Improve our website and services</li>
</ul>

<p><strong>[Customizable section]</strong> - Add specific uses relevant to your business.</p>
          `,
        },
      },
      {
        type: 'text',
        id: 'data-protection',
        order: 4,
        content: {
          heading: 'Data Protection',
          body: `
<p>We implement appropriate technical and organizational measures to protect your personal information 
against unauthorized access, alteration, disclosure, or destruction.</p>

<p><strong>[Customizable section]</strong> - Describe your specific security measures.</p>
          `,
        },
      },
      {
        type: 'text',
        id: 'your-rights',
        order: 5,
        content: {
          heading: 'Your Rights',
          body: `
<p>You have the right to:</p>
<ul>
  <li>Access your personal information</li>
  <li>Correct inaccurate information</li>
  <li>Request deletion of your information</li>
  <li>Opt-out of marketing communications</li>
</ul>

<p>To exercise these rights, please contact us using the information below.</p>
          `,
        },
      },
      {
        type: 'text',
        id: 'contact',
        order: 6,
        content: {
          heading: 'Contact Us',
          body: `
<p>If you have questions about this Privacy Policy, please contact us:</p>

<p>
<strong>${siteConfig.businessName}</strong><br>
Email: ${siteConfig.email}<br>
Phone: ${siteConfig.phone}<br>
Address: ${this.formatAddress(siteConfig)}
</p>
          `,
        },
      },
    ];

    return {
      id: 'privacy',
      title: 'Privacy Policy',
      sections,
      metaDescription: `Privacy Policy for ${siteConfig.businessName}`,
      keywords: ['privacy', 'policy', 'data protection'],
      intent: {
        primaryGoal: 'Legal compliance',
        targetAudience: 'All visitors',
        callsToAction: [],
      },
      createdAt: new Date().toISOString(),
      lastModified: new Date().toISOString(),
      version: 1,
    };
  }

  /**
   * Generate Terms of Service page
   */
  generateTermsOfService(siteConfig: SiteConfig): PageConfig {
    this.logger.debug('Generating terms of service', {
      businessName: siteConfig.businessName,
    });

    const sections: ContentSection[] = [
      {
        type: 'text',
        id: 'intro',
        order: 1,
        content: {
          heading: 'Terms of Service',
          body: `
<p>Last updated: ${new Date().toLocaleDateString()}</p>

<p>Please read these Terms of Service carefully before using ${siteConfig.domain} 
operated by ${siteConfig.legalName}.</p>

<p>By accessing or using our website, you agree to be bound by these Terms.</p>
          `,
        },
      },
      {
        type: 'text',
        id: 'use-license',
        order: 2,
        content: {
          heading: 'Use License',
          body: `
<p>Permission is granted to temporarily access the materials on ${siteConfig.businessName}'s 
website for personal, non-commercial transitory viewing only.</p>

<p>This is the grant of a license, not a transfer of title, and under this license you may not:</p>
<ul>
  <li>Modify or copy the materials</li>
  <li>Use the materials for any commercial purpose</li>
  <li>Attempt to reverse engineer any software on the website</li>
  <li>Remove any copyright or proprietary notations</li>
</ul>

<p><strong>[Customizable section]</strong> - Adjust based on your specific use case.</p>
          `,
        },
      },
      {
        type: 'text',
        id: 'disclaimer',
        order: 3,
        content: {
          heading: 'Disclaimer',
          body: `
<p>The materials on ${siteConfig.businessName}'s website are provided on an 'as is' basis. 
${siteConfig.businessName} makes no warranties, expressed or implied, and hereby disclaims 
and negates all other warranties including, without limitation, implied warranties or conditions 
of merchantability, fitness for a particular purpose, or non-infringement of intellectual property 
or other violation of rights.</p>

<p><strong>[Customizable section]</strong> - Consult with legal counsel for appropriate disclaimers.</p>
          `,
        },
      },
      {
        type: 'text',
        id: 'limitations',
        order: 4,
        content: {
          heading: 'Limitations',
          body: `
<p>In no event shall ${siteConfig.businessName} or its suppliers be liable for any damages 
(including, without limitation, damages for loss of data or profit, or due to business interruption) 
arising out of the use or inability to use the materials on ${siteConfig.businessName}'s website.</p>

<p><strong>[Customizable section]</strong> - Consult with legal counsel for appropriate limitations.</p>
          `,
        },
      },
      {
        type: 'text',
        id: 'modifications',
        order: 5,
        content: {
          heading: 'Revisions and Errata',
          body: `
<p>${siteConfig.businessName} may revise these Terms of Service at any time without notice. 
By using this website you are agreeing to be bound by the then current version of these Terms of Service.</p>
          `,
        },
      },
      {
        type: 'text',
        id: 'contact',
        order: 6,
        content: {
          heading: 'Contact Information',
          body: `
<p>For questions about these Terms, contact:</p>

<p>
<strong>${siteConfig.legalName}</strong><br>
Email: ${siteConfig.email}<br>
Phone: ${siteConfig.phone}<br>
Address: ${this.formatAddress(siteConfig)}
</p>
          `,
        },
      },
    ];

    return {
      id: 'terms',
      title: 'Terms of Service',
      sections,
      metaDescription: `Terms of Service for ${siteConfig.businessName}`,
      keywords: ['terms', 'service', 'legal'],
      intent: {
        primaryGoal: 'Legal compliance',
        targetAudience: 'All visitors',
        callsToAction: [],
      },
      createdAt: new Date().toISOString(),
      lastModified: new Date().toISOString(),
      version: 1,
    };
  }

  /**
   * Format address for display
   */
  private formatAddress(siteConfig: SiteConfig): string {
    const { street, city, state, zip, country } = siteConfig.address;
    return `${street}, ${city}, ${state} ${zip}, ${country}`;
  }
}
