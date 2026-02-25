/**
 * StaticGenerator Service
 * 
 * Generates static HTML files from configuration.
 * Handles SEO meta tags, sitemap generation, and responsive HTML.
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import { SiteConfig, PageConfig, ContentSection } from '../types/config.js';
import { ConfigManager } from './ConfigManager.js';
import { Logger } from './Logger.js';

export interface StaticGeneratorConfig {
  publicDir: string;
  assetsDir: string;
}

interface SEOTags {
  title: string;
  description: string;
  canonical: string;
  ogTitle: string;
  ogDescription: string;
  ogImage?: string;
  viewport: string;
}

export class StaticGenerator {
  private config: StaticGeneratorConfig;
  private configManager: ConfigManager;
  private logger: Logger;

  constructor(
    config: StaticGeneratorConfig,
    configManager: ConfigManager,
    logger: Logger
  ) {
    this.config = config;
    this.configManager = configManager;
    this.logger = logger;
  }

  /**
   * Generate entire site (all pages)
   */
  async generateSite(): Promise<void> {
    this.logger.info('Starting site generation');

    try {
      const siteConfig = await this.configManager.loadSiteConfig();
      const pages = await this.configManager.listPages();

      // Ensure public directory exists
      await fs.mkdir(this.config.publicDir, { recursive: true });

      // Generate each page
      for (const pageId of pages) {
        await this.generatePage(pageId, siteConfig);
      }

      // Generate sitemap
      await this.generateSitemap(pages, siteConfig);

      // Generate robots.txt
      await this.generateRobotsTxt(siteConfig);

      this.logger.info('Site generation completed', {
        pageCount: pages.length,
      });
    } catch (error: any) {
      this.logger.error('Site generation failed', {
        error: error.message,
        stack: error.stack,
      });
      throw error;
    }
  }

  /**
   * Generate a single page
   */
  async generatePage(pageId: string, siteConfig: SiteConfig): Promise<void> {
    this.logger.debug('Generating page', { pageId });

    const pageConfig = await this.configManager.loadPageConfig(pageId);

    // Build HTML
    const html = this.renderPage(pageConfig, siteConfig);

    // Write to public directory
    const outputPath = path.join(
      this.config.publicDir,
      pageId === 'home' ? 'index.html' : `${pageId}.html`
    );
    await fs.writeFile(outputPath, html, 'utf-8');

    this.logger.debug('Page generated', { pageId, outputPath });
  }

  /**
   * Render page HTML
   */
  private renderPage(page: PageConfig, site: SiteConfig): string {
    const seo = this.generateSEOTags(page, site);
    const navigation = this.buildNavigation(site);
    const content = this.renderContent(page.sections);
    const structuredData = this.generateStructuredData(site);

    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="${seo.viewport}">
  <title>${seo.title}</title>
  <meta name="description" content="${seo.description}">
  <link rel="canonical" href="${seo.canonical}">
  
  <!-- Open Graph -->
  <meta property="og:title" content="${seo.ogTitle}">
  <meta property="og:description" content="${seo.ogDescription}">
  <meta property="og:url" content="${seo.canonical}">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="${this.escapeHtml(site.businessName)}">
  ${seo.ogImage ? `<meta property="og:image" content="${seo.ogImage}">` : ''}
  
  <!-- Favicon -->
  <link rel="icon" type="image/x-icon" href="/favicon.ico">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  
  <!-- Structured Data -->
  <script type="application/ld+json">
${JSON.stringify(structuredData, null, 2)}
  </script>
  
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: ${site.fontFamily || 'system-ui, -apple-system, sans-serif'};
      line-height: 1.6;
      color: #333;
    }
    nav {
      background: ${site.primaryColor || '#333'};
      padding: 1rem 2rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    nav .logo {
      color: white;
      font-size: 1.5rem;
      font-weight: bold;
      text-decoration: none;
    }
    nav ul {
      list-style: none;
      display: flex;
      gap: 2rem;
    }
    nav a {
      color: white;
      text-decoration: none;
    }
    nav a:hover {
      text-decoration: underline;
    }
    main {
      max-width: 1200px;
      margin: 0 auto;
      padding: 2rem;
    }
    .section {
      margin-bottom: 3rem;
    }
    .hero {
      text-align: center;
      padding: 4rem 2rem;
      background: linear-gradient(135deg, ${site.primaryColor || '#333'}, ${site.secondaryColor || '#666'});
      color: white;
      border-radius: 8px;
    }
    .hero h1 {
      font-size: 3rem;
      margin-bottom: 1rem;
    }
    .hero p {
      font-size: 1.25rem;
      margin-bottom: 2rem;
    }
    .cta-button {
      display: inline-block;
      padding: 1rem 2rem;
      background: white;
      color: ${site.primaryColor || '#333'};
      text-decoration: none;
      border-radius: 4px;
      font-weight: bold;
    }
    .text-section h2 {
      font-size: 2rem;
      margin-bottom: 1rem;
      color: ${site.primaryColor || '#333'};
    }
    .text-section p {
      margin-bottom: 1rem;
    }
    .image-section {
      text-align: center;
    }
    .image-section img {
      max-width: 100%;
      height: auto;
      border-radius: 8px;
    }
    footer {
      background: #f5f5f5;
      padding: 2rem;
      text-align: center;
      margin-top: 4rem;
    }
    @media (max-width: 768px) {
      nav ul { flex-direction: column; gap: 1rem; }
      .hero h1 { font-size: 2rem; }
    }
  </style>
</head>
<body>
  <nav>
    <a href="/" class="logo">${this.escapeHtml(site.businessName)}</a>
    <ul>
${navigation}
    </ul>
  </nav>
  
  <main>
${content}
  </main>
  
  <footer>
    <p>&copy; ${new Date().getFullYear()} ${this.escapeHtml(site.businessName)}. All rights reserved.</p>
    <p>${this.escapeHtml(site.email)} | ${this.escapeHtml(site.phone)}</p>
    ${site.privacyPolicyEnabled ? '<p><a href="/privacy.html">Privacy Policy</a></p>' : ''}
    ${site.termsOfServiceEnabled ? '<p><a href="/terms.html">Terms of Service</a></p>' : ''}
  </footer>
</body>
</html>`;
  }

  /**
   * Generate SEO meta tags
   */
  private generateSEOTags(page: PageConfig, site: SiteConfig): SEOTags {
    const title =
      page.id === 'home'
        ? `${site.businessName} - ${site.industry}`
        : `${page.title} | ${site.businessName}`;

    const description =
      page.metaDescription || this.extractDescription(page.sections);

    return {
      title,
      description,
      canonical: `https://${site.domain}/${page.id === 'home' ? '' : page.id + '.html'}`,
      ogTitle: page.title,
      ogDescription: description,
      ogImage: page.featuredImage,
      viewport: 'width=device-width, initial-scale=1.0',
    };
  }

  /**
   * Extract description from content sections
   */
  private extractDescription(sections: ContentSection[]): string {
    const textSection = sections.find(
      (s) => s.type === 'text' || s.type === 'hero'
    );

    if (!textSection) {
      return '';
    }

    const text =
      textSection.content.body ||
      textSection.content.subheadline ||
      textSection.content.headline ||
      '';
    const plainText = this.stripHTML(text);

    return plainText.substring(0, 160).trim() + (plainText.length > 160 ? '...' : '');
  }

  /**
   * Build navigation HTML
   */
  private buildNavigation(site: SiteConfig): string {
    return site.navigation
      .sort((a, b) => a.order - b.order)
      .map((item) => {
        const href = item.pageId === 'home' ? '/' : `/${item.pageId}.html`;
        return `      <li><a href="${href}">${this.escapeHtml(item.label)}</a></li>`;
      })
      .join('\n');
  }

  /**
   * Render content sections
   */
  private renderContent(sections: ContentSection[]): string {
    return sections
      .sort((a, b) => a.order - b.order)
      .map((section) => this.renderSection(section))
      .join('\n');
  }

  /**
   * Render individual content section
   */
  private renderSection(section: ContentSection): string {
    switch (section.type) {
      case 'hero':
        return this.renderHeroSection(section);
      case 'text':
        return this.renderTextSection(section);
      case 'image':
        return this.renderImageSection(section);
      case 'cta':
        return this.renderCTASection(section);
      default:
        return '';
    }
  }

  /**
   * Render hero section
   */
  private renderHeroSection(section: ContentSection): string {
    const { headline, subheadline, ctaText, ctaLink } = section.content;
    return `    <section class="section hero">
      <h1>${this.escapeHtml(headline || '')}</h1>
      <p>${this.escapeHtml(subheadline || '')}</p>
      ${ctaText && ctaLink ? `<a href="${ctaLink}" class="cta-button">${this.escapeHtml(ctaText)}</a>` : ''}
    </section>`;
  }

  /**
   * Render text section
   */
  private renderTextSection(section: ContentSection): string {
    const { heading, body } = section.content;
    return `    <section class="section text-section">
      ${heading ? `<h2>${this.escapeHtml(heading)}</h2>` : ''}
      <div>${body || ''}</div>
    </section>`;
  }

  /**
   * Render image section
   */
  private renderImageSection(section: ContentSection): string {
    const { imageId, altText, caption } = section.content;
    return `    <section class="section image-section">
      <img src="/assets/${imageId}" alt="${this.escapeHtml(altText || '')}" loading="lazy">
      ${caption ? `<p>${this.escapeHtml(caption)}</p>` : ''}
    </section>`;
  }

  /**
   * Render CTA section
   */
  private renderCTASection(section: ContentSection): string {
    const { text, link } = section.content;
    return `    <section class="section" style="text-align: center;">
      <a href="${link}" class="cta-button">${this.escapeHtml(text || '')}</a>
    </section>`;
  }

  /**
   * Generate structured data (JSON-LD)
   */
  private generateStructuredData(site: SiteConfig): object {
    return {
      '@context': 'https://schema.org',
      '@type': 'LocalBusiness',
      name: site.businessName,
      description: site.description,
      url: `https://${site.domain}`,
      telephone: site.phone,
      email: site.email,
      address: {
        '@type': 'PostalAddress',
        streetAddress: site.address.street,
        addressLocality: site.address.city,
        addressRegion: site.address.state,
        postalCode: site.address.zip,
        addressCountry: site.address.country,
      },
    };
  }

  /**
   * Generate sitemap.xml
   */
  private async generateSitemap(
    pages: string[],
    site: SiteConfig
  ): Promise<void> {
    this.logger.debug('Generating sitemap');

    const urls = await Promise.all(
      pages.map(async (pageId) => {
        const config = await this.configManager.loadPageConfig(pageId);
        const loc =
          pageId === 'home'
            ? `https://${site.domain}/`
            : `https://${site.domain}/${pageId}.html`;
        const priority = pageId === 'home' ? '1.0' : '0.8';
        const changefreq = pageId === 'home' ? 'weekly' : 'monthly';

        return `  <url>
    <loc>${loc}</loc>
    <lastmod>${config.lastModified}</lastmod>
    <changefreq>${changefreq}</changefreq>
    <priority>${priority}</priority>
  </url>`;
      })
    );

    const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.join('\n')}
</urlset>`;

    const sitemapPath = path.join(this.config.publicDir, 'sitemap.xml');
    await fs.writeFile(sitemapPath, sitemap, 'utf-8');

    this.logger.debug('Sitemap generated', { sitemapPath });
  }

  /**
   * Generate robots.txt
   */
  private async generateRobotsTxt(site: SiteConfig): Promise<void> {
    const robotsTxt = `User-agent: *
Allow: /

Sitemap: https://${site.domain}/sitemap.xml`;

    const robotsPath = path.join(this.config.publicDir, 'robots.txt');
    await fs.writeFile(robotsPath, robotsTxt, 'utf-8');

    this.logger.debug('robots.txt generated', { robotsPath });
  }

  /**
   * Strip HTML tags from text
   */
  private stripHTML(html: string): string {
    return html.replace(/<[^>]*>/g, '');
  }

  /**
   * Escape HTML special characters
   */
  private escapeHtml(text: string): string {
    const map: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;',
    };
    return text.replace(/[&<>"']/g, (m) => map[m]);
  }
}
