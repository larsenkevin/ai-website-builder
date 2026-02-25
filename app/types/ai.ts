/**
 * AI Agent type definitions
 */

export interface PageContext {
  businessName: string;
  industry: string;
  businessDescription: string;
  pageTitle: string;
  intent?: {
    primaryGoal?: string;
    targetAudience?: string;
    callsToAction?: string[];
  };
}

export interface AIResponse {
  content: string;
  tokensUsed: number;
}

export interface AIAgentConfig {
  apiKey: string;
  model: string;
  maxTokens: number;
  temperature: number;
}
