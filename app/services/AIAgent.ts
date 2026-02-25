/**
 * AIAgent Service
 * 
 * Handles AI-powered content generation using Claude API.
 * Manages conversation history, system prompts, and token tracking.
 */

import Anthropic from '@anthropic-ai/sdk';
import { Message } from '../types/config.js';
import { AIResponse, PageContext, AIAgentConfig } from '../types/ai.js';
import { Logger } from './Logger.js';

export class AIAgent {
  private client: Anthropic;
  private config: AIAgentConfig;
  private logger: Logger;
  private rateLimiter: any; // Will be injected

  constructor(config: AIAgentConfig, logger: Logger, rateLimiter?: any) {
    this.config = config;
    this.logger = logger;
    this.client = new Anthropic({
      apiKey: config.apiKey,
    });
    this.rateLimiter = rateLimiter;
  }

  /**
   * Generate content based on conversation history and page context
   */
  async generateContent(
    conversationHistory: Message[],
    userMessage: string,
    pageContext: PageContext
  ): Promise<AIResponse> {
    // Build system prompt with page context
    const systemPrompt = this.buildSystemPrompt(pageContext);

    // Limit conversation history to last 20 messages
    const limitedHistory = this.limitConversationHistory(conversationHistory, 20);

    // Add user message to history
    const messages = [
      ...limitedHistory.map((m) => ({
        role: m.role as 'user' | 'assistant',
        content: m.content,
      })),
      {
        role: 'user' as const,
        content: userMessage,
      },
    ];

    // Rate limit check if rate limiter is available
    if (this.rateLimiter) {
      await this.rateLimiter.acquire();
    }

    try {
      // Call Claude API with retry logic
      const response = await this.callWithRetry({
        model: this.config.model,
        max_tokens: this.config.maxTokens,
        temperature: this.config.temperature,
        system: systemPrompt,
        messages: messages,
      });

      const tokensUsed =
        response.usage.input_tokens + response.usage.output_tokens;

      // Track token usage if rate limiter is available
      if (this.rateLimiter) {
        this.rateLimiter.trackTokenUsage(tokensUsed);
      }

      this.logger.info('AI content generated successfully', {
        tokensUsed,
        model: this.config.model,
        messageCount: messages.length,
      });

      return {
        content: response.content[0].text,
        tokensUsed,
      };
    } catch (error: any) {
      this.logger.error('Failed to generate AI content', {
        error: error.message,
        stack: error.stack,
      });
      throw new AIAgentError('Failed to generate content', error);
    }
  }

  /**
   * Build system prompt with business and page context
   */
  private buildSystemPrompt(pageContext: PageContext): string {
    return `You are an expert website content writer helping a small business owner create professional web content.

Business Context:
- Business Name: ${pageContext.businessName}
- Industry: ${pageContext.industry}
- Description: ${pageContext.businessDescription}

Page Context:
- Page: ${pageContext.pageTitle}
- Purpose: ${pageContext.intent?.primaryGoal || 'Not specified'}
- Target Audience: ${pageContext.intent?.targetAudience || 'General public'}

Your role:
1. Ask clarifying questions to understand the page's purpose and content needs
2. Generate professional, engaging content appropriate for the business and audience
3. Suggest specific sections (hero, text, images, CTAs) that would work well
4. Refine content based on user feedback
5. Keep content concise and focused on the business goals

Guidelines:
- Use a professional but approachable tone
- Focus on benefits and value propositions
- Include clear calls-to-action where appropriate
- Ensure content is SEO-friendly
- Keep paragraphs short and scannable`;
  }

  /**
   * Limit conversation history to prevent token overflow
   */
  private limitConversationHistory(
    history: Message[],
    maxMessages: number
  ): Message[] {
    if (history.length <= maxMessages) {
      return history;
    }

    // Keep most recent messages
    const recentMessages = history.slice(-maxMessages);

    // Always include first message if it contains important context
    if (history.length > maxMessages && history[0].role === 'user') {
      return [history[0], ...recentMessages.slice(1)];
    }

    return recentMessages;
  }

  /**
   * Call Claude API with retry logic
   */
  private async callWithRetry(
    params: any,
    attempt: number = 1
  ): Promise<any> {
    try {
      return await this.client.messages.create(params);
    } catch (error: any) {
      // Check if we should retry
      if (attempt >= 3) {
        throw error;
      }

      if (this.isTransientError(error)) {
        const delayMs = Math.pow(2, attempt) * 1000;
        this.logger.warn(`Retrying AI request after ${delayMs}ms`, {
          attempt,
          error: error.message,
        });

        await this.sleep(delayMs);
        return this.callWithRetry(params, attempt + 1);
      }

      throw error;
    }
  }

  /**
   * Check if error is transient and should be retried
   */
  private isTransientError(error: any): boolean {
    const transientStatuses = [429, 500, 502, 503, 504];
    const transientCodes = ['ECONNRESET', 'ETIMEDOUT'];

    return (
      transientStatuses.includes(error.status) ||
      transientCodes.includes(error.code)
    );
  }

  /**
   * Sleep for specified milliseconds
   */
  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}

/**
 * Custom error class for AI Agent errors
 */
export class AIAgentError extends Error {
  constructor(
    message: string,
    public originalError?: any
  ) {
    super(message);
    this.name = 'AIAgentError';
  }
}
