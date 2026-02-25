/**
 * Configuration type definitions for the AI Website Builder
 */

export interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
  country: string;
}

export interface NavigationItem {
  label: string;
  pageId: string;
  order: number;
}

export interface SiteConfig {
  // Business Information
  businessName: string;
  legalName: string;
  industry: string;
  description: string;

  // Contact Information
  email: string;
  phone: string;
  address: Address;

  // Branding
  logo: string; // Path to logo file
  favicon: string; // Path to favicon
  primaryColor: string; // Hex color
  secondaryColor: string; // Hex color
  fontFamily: string;

  // Domain and URLs
  domain: string;

  // Navigation
  navigation: NavigationItem[];

  // Legal
  privacyPolicyEnabled: boolean;
  termsOfServiceEnabled: boolean;

  // Metadata
  createdAt: string; // ISO 8601 timestamp
  lastModified: string; // ISO 8601 timestamp
}

export interface PageIntent {
  primaryGoal: string; // e.g., "Generate leads", "Provide information"
  targetAudience: string; // e.g., "Small business owners"
  callsToAction: string[]; // e.g., ["Contact us", "Schedule consultation"]
}

export interface ContentSection {
  type: 'hero' | 'text' | 'image' | 'gallery' | 'contact-form' | 'cta';
  id: string;
  order: number;
  content: Record<string, any>; // Type-specific content
}

export interface PageConfig {
  // Identification
  id: string; // Unique page identifier (slug)
  title: string; // Page title

  // Content
  sections: ContentSection[];

  // SEO
  metaDescription: string;
  keywords: string[];
  featuredImage?: string;

  // Page Intent (captured during AI interaction)
  intent: PageIntent;

  // Metadata
  createdAt: string; // ISO 8601 timestamp
  lastModified: string; // ISO 8601 timestamp
  version: number;
}

export interface Message {
  role: 'user' | 'assistant';
  content: string;
  timestamp: string; // ISO 8601 timestamp
}

export interface TempConfig extends PageConfig {
  // Additional fields for editing session
  sessionId: string;
  startedAt: string; // ISO 8601 timestamp
  conversationHistory: Message[];
}
