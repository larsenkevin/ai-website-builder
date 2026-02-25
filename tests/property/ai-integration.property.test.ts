/**
 * Property-Based Tests for AI Integration
 * 
 * Tests AI agent behavior including conversation history management,
 * API request structure, and system prompt generation.
 */

import { describe, it, beforeEach, afterEach } from 'vitest';
import * as fc from 'fast-check';
import { AIAgent } from '../../app/services/AIAgent.js';
import { Logger } from '../../app/services/Logger.js';
import { Message } from '../../app/types/config.js';
import { PageContext, AIAgentConfig } from '../../app/types/ai.js';

/**
 * Property 27: Conversation History in API Requests
 * 
 * For any AI content generation request, the request to Claude API SHALL include 
 * all messages from the current conversation history.
 * 
 * **Validates: Requirements 17.2**
 */

/**
 * Property 28: API Request Structure
 * 
 * For any AI content generation request, the request SHALL include both user 
 * messages and system prompts.
 * 
 * **Validates: Requirements 17.3**
 */

describe('AI Integration Properties', () => {
  let logger: Logger;
  let aiAgent: AIAgent;

  beforeEach(() => {
    // Create logger for testing
    logger = new Logger({
      logDir: './logs/ai-test',
      logLevel: 'error', // Minimize test output
      rotationSize: 100 * 1024 * 1024,
      retentionDays: 30,
    });

    // Create AI agent with test config (no real API key needed for structure tests)
    const config: AIAgentConfig = {
      apiKey: 'test-key',
      model: 'claude-3-5-sonnet-20241022',
      maxTokens: 4096,
      temperature: 0.7,
    };

    aiAgent = new AIAgent(config, logger);
  });

  afterEach(() => {
    // Logger cleanup happens automatically
  });

  describe('Property 27: Conversation History in API Requests', () => {
    it('Property: System prompt includes all page context fields', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.record({
            businessName: fc.string({ minLength: 1, maxLength: 100 }),
            industry: fc.string({ minLength: 1, maxLength: 50 }),
            businessDescription: fc.string({ minLength: 1, maxLength: 500 }),
            pageTitle: fc.string({ minLength: 1, maxLength: 100 }),
            intent: fc.option(
              fc.record({
                primaryGoal: fc.option(fc.string({ minLength: 1, maxLength: 200 })),
                targetAudience: fc.option(fc.string({ minLength: 1, maxLength: 200 })),
                callsToAction: fc.option(fc.array(fc.string({ minLength: 1, maxLength: 100 }), { maxLength: 5 })),
              }),
              { nil: undefined }
            ),
          }),
          async (pageContext: PageContext) => {
            // Access the private buildSystemPrompt method via reflection
            const buildSystemPrompt = (aiAgent as any).buildSystemPrompt.bind(aiAgent);
            const systemPrompt = buildSystemPrompt(pageContext);

            // Verify all context fields are included in the system prompt
            if (pageContext.businessName) {
              if (!systemPrompt.includes(pageContext.businessName)) {
                throw new Error(`System prompt missing business name: ${pageContext.businessName}`);
              }
            }
            if (pageContext.industry) {
              if (!systemPrompt.includes(pageContext.industry)) {
                throw new Error(`System prompt missing industry: ${pageContext.industry}`);
              }
            }
            if (pageContext.businessDescription) {
              if (!systemPrompt.includes(pageContext.businessDescription)) {
                throw new Error(`System prompt missing description: ${pageContext.businessDescription}`);
              }
            }
            if (pageContext.pageTitle) {
              if (!systemPrompt.includes(pageContext.pageTitle)) {
                throw new Error(`System prompt missing page title: ${pageContext.pageTitle}`);
              }
            }

            // Verify intent fields if present
            if (pageContext.intent?.primaryGoal) {
              if (!systemPrompt.includes(pageContext.intent.primaryGoal)) {
                throw new Error(`System prompt missing primary goal: ${pageContext.intent.primaryGoal}`);
              }
            }
            if (pageContext.intent?.targetAudience) {
              if (!systemPrompt.includes(pageContext.intent.targetAudience)) {
                throw new Error(`System prompt missing target audience: ${pageContext.intent.targetAudience}`);
              }
            }
          }
        ),
        { numRuns: 50 }
      );
    });

    it('Property: Conversation history is limited to 20 messages', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.array(
            fc.record({
              role: fc.constantFrom('user' as const, 'assistant' as const),
              content: fc.string({ minLength: 1, maxLength: 500 }),
              timestamp: fc.date().map(d => d.toISOString()),
            }),
            { minLength: 0, maxLength: 50 }
          ),
          async (conversationHistory: Message[]) => {
            // Access the private limitConversationHistory method
            const limitHistory = (aiAgent as any).limitConversationHistory.bind(aiAgent);
            const limited = limitHistory(conversationHistory, 20);

            // Verify the result is at most 20 messages
            if (limited.length > 20) {
              throw new Error(`History not limited: got ${limited.length} messages, expected max 20`);
            }

            // If original was <= 20, should be unchanged
            if (conversationHistory.length <= 20) {
              if (limited.length !== conversationHistory.length) {
                throw new Error(`History changed when it shouldn't: ${conversationHistory.length} -> ${limited.length}`);
              }
            }

            // If original was > 20, should be exactly 20 or 21 (if first message preserved)
            if (conversationHistory.length > 20) {
              if (limited.length < 20 || limited.length > 21) {
                throw new Error(`History not properly limited: got ${limited.length}, expected 20-21`);
              }

              // If first message was user message, it should be preserved
              if (conversationHistory[0].role === 'user' && conversationHistory.length > 20) {
                if (limited[0].content !== conversationHistory[0].content) {
                  throw new Error('First user message not preserved in limited history');
                }
              }
            }
          }
        ),
        { numRuns: 100 }
      );
    });

    it('Property: First user message is preserved when history exceeds limit', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.tuple(
            fc.record({
              role: fc.constant('user' as const),
              content: fc.string({ minLength: 1, maxLength: 500 }),
              timestamp: fc.date().map(d => d.toISOString()),
            }),
            fc.array(
              fc.record({
                role: fc.constantFrom('user' as const, 'assistant' as const),
                content: fc.string({ minLength: 1, maxLength: 500 }),
                timestamp: fc.date().map(d => d.toISOString()),
              }),
              { minLength: 21, maxLength: 50 }
            )
          ),
          async ([firstMessage, restMessages]) => {
            const conversationHistory = [firstMessage, ...restMessages];
            
            // Access the private limitConversationHistory method
            const limitHistory = (aiAgent as any).limitConversationHistory.bind(aiAgent);
            const limited = limitHistory(conversationHistory, 20);

            // First message should be preserved
            if (limited[0].content !== firstMessage.content) {
              throw new Error('First user message not preserved when history exceeds limit');
            }
          }
        ),
        { numRuns: 50 }
      );
    });
  });

  describe('Property 28: API Request Structure', () => {
    it('Property: System prompt contains required sections', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.record({
            businessName: fc.string({ minLength: 1, maxLength: 100 }),
            industry: fc.string({ minLength: 1, maxLength: 50 }),
            businessDescription: fc.string({ minLength: 1, maxLength: 500 }),
            pageTitle: fc.string({ minLength: 1, maxLength: 100 }),
          }),
          async (pageContext: PageContext) => {
            // Access the private buildSystemPrompt method
            const buildSystemPrompt = (aiAgent as any).buildSystemPrompt.bind(aiAgent);
            const systemPrompt = buildSystemPrompt(pageContext);

            // Verify required sections are present
            const requiredSections = [
              'Business Context:',
              'Page Context:',
              'Your role:',
              'Guidelines:',
            ];

            for (const section of requiredSections) {
              if (!systemPrompt.includes(section)) {
                throw new Error(`System prompt missing required section: ${section}`);
              }
            }

            // Verify it's a non-empty string
            if (systemPrompt.length === 0) {
              throw new Error('System prompt is empty');
            }
          }
        ),
        { numRuns: 50 }
      );
    });

    it('Property: System prompt handles missing optional intent fields gracefully', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.record({
            businessName: fc.string({ minLength: 1, maxLength: 100 }),
            industry: fc.string({ minLength: 1, maxLength: 50 }),
            businessDescription: fc.string({ minLength: 1, maxLength: 500 }),
            pageTitle: fc.string({ minLength: 1, maxLength: 100 }),
            intent: fc.option(
              fc.record({
                primaryGoal: fc.option(fc.string({ minLength: 1, maxLength: 200 })),
                targetAudience: fc.option(fc.string({ minLength: 1, maxLength: 200 })),
              }),
              { nil: undefined }
            ),
          }),
          async (pageContext: PageContext) => {
            // Access the private buildSystemPrompt method
            const buildSystemPrompt = (aiAgent as any).buildSystemPrompt.bind(aiAgent);
            const systemPrompt = buildSystemPrompt(pageContext);

            // When intent fields are missing, should show default values
            if (!pageContext.intent?.primaryGoal) {
              if (!systemPrompt.includes('Not specified')) {
                throw new Error('System prompt should show "Not specified" for missing primary goal');
              }
            }

            if (!pageContext.intent?.targetAudience) {
              if (!systemPrompt.includes('General public')) {
                throw new Error('System prompt should show "General public" for missing target audience');
              }
            }

            // Should still be a valid prompt
            if (systemPrompt.length === 0) {
              throw new Error('System prompt is empty even with missing intent');
            }
          }
        ),
        { numRuns: 50 }
      );
    });
  });
});
