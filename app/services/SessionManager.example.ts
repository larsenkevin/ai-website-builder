/**
 * SessionManager Usage Examples
 * 
 * This file demonstrates how to use the SessionManager service
 * for managing editing sessions with temporary configurations.
 */

import { SessionManager } from './SessionManager.js';
import { ConfigManager } from './ConfigManager.js';
import { Message } from '../types/config.js';

// Initialize services
const configManager = new ConfigManager();
const sessionManager = new SessionManager(configManager);

/**
 * Example 1: Start an editing session
 */
async function example1_startEditing() {
  const pageId = 'home';
  
  // Start editing session
  const session = await sessionManager.startEditing(pageId);
  
  console.log('Session started:', {
    pageId: session.pageId,
    sessionId: session.sessionId,
    startedAt: session.startedAt,
  });
  
  // The temp config is now created and stored
  // Original page config remains unchanged
}

/**
 * Example 2: Update content during editing
 */
async function example2_updateContent() {
  const pageId = 'home';
  
  // Update the temp config with new content
  await sessionManager.updateTempConfig(pageId, {
    title: 'Updated Home Page Title',
    metaDescription: 'New meta description',
    sections: [
      {
        type: 'hero',
        id: 'hero-1',
        order: 1,
        content: {
          headline: 'Welcome to Our Business',
          subheadline: 'We provide excellent services',
        },
      },
    ],
  });
  
  console.log('Content updated in temp config');
}

/**
 * Example 3: Add AI conversation messages
 */
async function example3_addMessages() {
  const pageId = 'home';
  
  // Add user message
  const userMessage: Message = {
    role: 'user',
    content: 'Can you help me write a compelling hero section?',
    timestamp: new Date().toISOString(),
  };
  
  await sessionManager.addMessage(pageId, userMessage);
  
  // Add AI assistant response
  const assistantMessage: Message = {
    role: 'assistant',
    content: 'I\'d be happy to help! Let me suggest a hero section...',
    timestamp: new Date().toISOString(),
  };
  
  await sessionManager.addMessage(pageId, assistantMessage);
  
  console.log('Messages added to conversation history');
}

/**
 * Example 4: Confirm changes (publish)
 */
async function example4_confirmChanges() {
  const pageId = 'home';
  
  // Confirm changes - copies temp config to page config
  await sessionManager.confirmChanges(pageId);
  
  console.log('Changes confirmed and published');
  // Temp config is deleted
  // Page config is updated
  // Session is removed from memory
}

/**
 * Example 5: Cancel changes (discard)
 */
async function example5_cancelChanges() {
  const pageId = 'about';
  
  // Start editing
  await sessionManager.startEditing(pageId);
  
  // Make some changes...
  await sessionManager.updateTempConfig(pageId, {
    title: 'This will be discarded',
  });
  
  // Cancel changes - deletes temp config
  await sessionManager.cancelChanges(pageId);
  
  console.log('Changes cancelled');
  // Temp config is deleted
  // Original page config is preserved
  // Session is removed from memory
}

/**
 * Example 6: Check for active sessions
 */
async function example6_checkSessions() {
  const pageId = 'services';
  
  // Check if page has active session
  const hasSession = sessionManager.hasActiveSession(pageId);
  console.log(`Page ${pageId} has active session:`, hasSession);
  
  // Get specific session
  const session = sessionManager.getSession(pageId);
  if (session) {
    console.log('Session details:', {
      sessionId: session.sessionId,
      startedAt: session.startedAt,
      conversationLength: session.tempConfig.conversationHistory.length,
    });
  }
  
  // Get all active sessions
  const allSessions = sessionManager.getAllSessions();
  console.log(`Total active sessions: ${allSessions.length}`);
}

/**
 * Example 7: Restore sessions on startup
 */
async function example7_restoreSessions() {
  // This should be called when the server starts
  // It restores sessions from existing temp config files
  
  await sessionManager.restoreSessions();
  
  console.log('Sessions restored from temp configs');
  
  // Now all sessions are available in memory
  const sessions = sessionManager.getAllSessions();
  console.log(`Restored ${sessions.length} sessions`);
}

/**
 * Example 8: Complete editing workflow
 */
async function example8_completeWorkflow() {
  const pageId = 'contact';
  
  try {
    // 1. Start editing
    const session = await sessionManager.startEditing(pageId);
    console.log('Started editing:', session.sessionId);
    
    // 2. User interacts with AI
    await sessionManager.addMessage(pageId, {
      role: 'user',
      content: 'Create a contact page with a form',
      timestamp: new Date().toISOString(),
    });
    
    await sessionManager.addMessage(pageId, {
      role: 'assistant',
      content: 'I\'ll create a contact page with a form section...',
      timestamp: new Date().toISOString(),
    });
    
    // 3. Update content based on AI suggestions
    await sessionManager.updateTempConfig(pageId, {
      title: 'Contact Us',
      metaDescription: 'Get in touch with our team',
      sections: [
        {
          type: 'contact-form',
          id: 'contact-form-1',
          order: 1,
          content: {
            heading: 'Get In Touch',
            fields: ['name', 'email', 'message'],
          },
        },
      ],
    });
    
    // 4. User reviews and confirms
    await sessionManager.confirmChanges(pageId);
    console.log('Changes published successfully');
    
  } catch (error: any) {
    console.error('Error in workflow:', error);
    
    // If something goes wrong, cancel changes
    if (sessionManager.hasActiveSession(pageId)) {
      await sessionManager.cancelChanges(pageId);
      console.log('Changes cancelled due to error');
    }
  }
}

/**
 * Example 9: Prevent concurrent editing
 */
async function example9_preventConcurrentEditing() {
  const pageId = 'home';
  
  try {
    // First user starts editing
    await sessionManager.startEditing(pageId);
    console.log('User 1 started editing');
    
    // Second user tries to edit the same page
    await sessionManager.startEditing(pageId);
    // This will throw an error
    
  } catch (error: any) {
    console.error('Expected error:', error.message);
    // "Page home is already being edited"
  }
}

// Export examples for testing
export {
  example1_startEditing,
  example2_updateContent,
  example3_addMessages,
  example4_confirmChanges,
  example5_cancelChanges,
  example6_checkSessions,
  example7_restoreSessions,
  example8_completeWorkflow,
  example9_preventConcurrentEditing,
};
