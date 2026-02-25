# Implementation Plan: AI Website Builder

## Overview

This plan implements a two-component system: a VPN-protected Builder Interface for content management and a public Static Server for serving generated websites. The system uses Node.js/Express.js with TypeScript for the backend, React with TypeScript for the frontend, and is designed to run on AWS Lightsail (1 CPU, 1GB RAM) with a target cost of $12-30/month.

## Tasks

- [x] 1. Infrastructure and deployment setup
  - [x] 1.1 Create deployment scripts for AWS Lightsail
    - Write Terraform or CloudFormation templates for Lightsail instance provisioning
    - Configure Ubuntu LTS installation
    - Set up automatic security updates
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 1.2 Configure NGINX as static web server
    - Install NGINX
    - Configure server blocks for public content serving
    - Set up gzip compression and cache headers
    - Configure 404 error page handling
    - _Requirements: 1.4, 29.1, 29.2, 29.3, 29.5_

  - [x] 1.3 Set up UFW firewall rules
    - Allow ports 80, 443, and Tailscale port
    - Block all other inbound traffic by default
    - _Requirements: 2.1, 2.2_

  - [x] 1.4 Configure Tailscale VPN integration
    - Install Tailscale client
    - Configure VPN access for Builder Interface
    - Set up access control to restrict Builder Interface to VPN only
    - _Requirements: 2.3, 2.5_

  - [x] 1.5 Set up Let's Encrypt SSL automation
    - Install certbot
    - Configure automatic certificate acquisition
    - Set up automatic renewal with cron job
    - Implement renewal retry logic with exponential backoff
    - Configure certificate expiration monitoring (30-day threshold)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 1.6 Create systemd service files
    - Write systemd service for Builder Interface
    - Configure automatic restart on failure
    - Set up service logging
    - _Requirements: 1.5_

- [x] 2. Backend project setup and core infrastructure
  - [x] 2.1 Initialize Node.js/TypeScript project
    - Create package.json with dependencies (express, @anthropic-ai/sdk, sharp, chokidar, etc.)
    - Configure TypeScript with tsconfig.json
    - Set up project directory structure (/app, /config, /assets, /versions, /logs)
    - Create .env file template with required environment variables
    - _Requirements: 4.4_

  - [x] 2.2 Set up Express.js server
    - Create main server.js entry point
    - Configure Express middleware (body-parser, cors, express-fileupload)
    - Set up error handling middleware
    - Configure port binding (3000)
    - _Requirements: 2.3_

  - [x] 2.3 Implement logging infrastructure
    - Create Logger service with structured JSON logging
    - Implement log levels (ERROR, WARN, INFO, DEBUG)
    - Add correlation IDs for request tracing
    - Configure log rotation at 100MB
    - Implement 30-day log retention
    - _Requirements: 30.1, 30.2, 30.3, 30.4, 30.5_

  - [x] 2.4 Write property test for logging
    - **Property 58: Comprehensive Logging**
    - **Validates: Requirements 30.1, 30.2, 30.3**

- [x] 3. Configuration management system
  - [x] 3.1 Implement ConfigManager service
    - Create methods for reading/writing site.json
    - Create methods for reading/writing pages/*.json
    - Create methods for reading/writing pages/*.temp.json
    - Implement atomic file write operations
    - Add JSON validation for configuration objects
    - _Requirements: 4.1, 4.2, 4.3, 4.6_

  - [x] 3.2 Create TypeScript interfaces for configuration models
    - Define SiteConfig interface with all required fields
    - Define PageConfig interface with sections and metadata
    - Define TempConfig interface extending PageConfig
    - Define ContentSection types (hero, text, image, gallery, contact-form, cta)
    - Define ProcessedAsset and ImageVariant interfaces
    - _Requirements: 4.1, 4.2, 4.3_

  - [x] 3.3 Implement configuration validation
    - Create validators for required fields in SiteConfig
    - Create validators for required fields in PageConfig
    - Implement email, phone, and URL format validation
    - Add descriptive error messages for validation failures
    - _Requirements: 6.6, 28.2, 28.5_

  - [x] 3.4 Write property tests for configuration management
    - **Property 1: Configuration Round Trip**
    - **Validates: Requirements 4.6, 28.4**

  - [x] 3.5 Write property test for configuration validation
    - **Property 54: Config Parsing**
    - **Property 55: Invalid JSON Error Handling**
    - **Property 56: Config Formatting**
    - **Property 57: Required Field Validation**
    - **Validates: Requirements 28.1, 28.2, 28.3, 28.5**

- [x] 4. Session management system
  - [x] 4.1 Implement SessionManager service
    - Create in-memory session store (Map<string, EditingSession>)
    - Implement startEditing() method to create temp configs
    - Implement confirmChanges() method to copy temp to page config
    - Implement cancelChanges() method to delete temp config
    - Add session restoration from existing temp files on startup
    - _Requirements: 11.1, 11.2, 11.3, 11.5, 12.3, 12.4, 12.5_

  - [x] 4.2 Implement session cleanup job
    - Create scheduled job to run every hour
    - Identify temp configs older than 24 hours
    - Delete abandoned temp configs
    - Remove corresponding sessions from memory
    - _Requirements: 11.4_

  - [x] 4.3 Add concurrent editing prevention
    - Check for existing session before starting new one
    - Return error if page is already being edited
    - _Requirements: 11.1_

  - [x] 4.4 Write property tests for session lifecycle
    - **Property 2: Temp Config Preserves Original**
    - **Property 13: Session Lifecycle - Start**
    - **Property 14: Session Lifecycle - Modification**
    - **Property 15: Session Lifecycle - Cleanup**
    - **Property 16: Session Lifecycle - Restoration**
    - **Property 17: Session Lifecycle - Confirmation**
    - **Property 18: Session Lifecycle - Cancellation**
    - **Validates: Requirements 4.5, 11.1, 11.2, 11.3, 11.4, 11.5, 12.3, 12.4, 12.5_

- [x] 5. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. AI integration with Claude API
  - [x] 6.1 Implement AIAgent service
    - Initialize Anthropic client with API key from environment
    - Create generateContent() method with conversation history support
    - Build system prompts with business and page context
    - Implement conversation history management (limit to 20 messages)
    - Add token usage tracking
    - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5_

  - [x] 6.2 Implement retry logic with exponential backoff
    - Create callWithRetry() helper function
    - Detect transient errors (429, 500, 502, 503, 504, ECONNRESET, ETIMEDOUT)
    - Implement exponential backoff (1s, 2s, 4s)
    - Limit to 3 retry attempts
    - _Requirements: 19.1, 19.2, 19.3_

  - [x] 6.3 Implement RateLimiter service
    - Track requests per minute with sliding window
    - Implement request queue (FIFO)
    - Add acquire() method to check/queue requests
    - Create queue processing loop
    - Implement monthly token tracking
    - Add threshold notification (configurable limit)
    - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5, 19.5, 20.1, 20.2, 20.3_

  - [x] 6.4 Write property tests for AI integration
    - **Property 27: Conversation History in API Requests**
    - **Property 28: API Request Structure**
    - **Validates: Requirements 17.2, 17.3**

  - [x] 6.5 Write property tests for rate limiting
    - **Property 29: Rate Limiting - Request Tracking**
    - **Property 30: Rate Limiting - Queue on Excess**
    - **Property 31: Rate Limiting - Queue Processing**
    - **Property 32: Token Usage Tracking**
    - **Property 33: Token Threshold Notification**
    - **Property 38: Concurrent Request Queuing**
    - **Property 39: FIFO Queue Processing**
    - **Property 40: Rate Limit Respect During Queue Processing**
    - **Validates: Requirements 18.1, 18.2, 18.3, 18.4, 18.5, 20.1, 20.2, 20.3**

  - [x] 6.6 Write property tests for retry logic
    - **Property 34: Retry on Transient Errors**
    - **Property 35: Exponential Backoff**
    - **Property 36: Maximum Retry Attempts**
    - **Property 37: Rate Limit Error Queuing**
    - **Validates: Requirements 3.4, 19.1, 19.2, 19.3, 19.5**

- [x] 7. Asset processing and image optimization
  - [x] 7.1 Implement AssetProcessor service
    - Create processImage() method for image uploads
    - Implement file format validation (JPEG, PNG, GIF)
    - Implement file size validation (5MB limit)
    - Generate unique filenames using UUID
    - Save original uploads to /assets/uploads
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

  - [x] 7.2 Implement image optimization pipeline
    - Use sharp.js for image processing
    - Convert images to WebP format (85% quality)
    - Generate responsive variants (320px, 768px, 1920px)
    - Preserve aspect ratios during resizing
    - Save variants to /assets/processed/{width}/
    - Store asset metadata with variant paths
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

  - [x] 7.3 Implement favicon generation
    - Create generateFavicon() method
    - Generate 16x16, 32x32 favicon.ico
    - Generate 180x180 apple-touch-icon.png
    - Place favicon files in web root directory
    - Trigger regeneration on logo upload
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

  - [x] 7.4 Implement alt text management
    - Store alt text in ProcessedAsset metadata
    - Associate alt text with images in PageConfig
    - Validate alt text presence before image insertion
    - Display warning for missing alt text
    - _Requirements: 16.1, 16.2, 16.3, 16.5_

  - [x] 7.5 Write property tests for asset processing
    - **Property 19: Image Format Validation**
    - **Property 20: Image Size Validation**
    - **Property 21: Unique Filename Generation**
    - **Property 22: Image Optimization Pipeline**
    - **Property 23: Favicon Generation from Logo**
    - **Property 24: Alt Text Requirement**
    - **Property 25: Alt Text Storage**
    - **Validates: Requirements 13.1, 13.2, 13.4, 13.5, 14.1-14.5, 15.1-15.5, 16.2, 16.3**

- [x] 8. Static HTML generation
  - [x] 8.1 Implement StaticGenerator service
    - Create generateSite() method to regenerate all pages
    - Create generatePage() method for individual pages
    - Implement HTML template rendering
    - Apply site-wide branding from SiteConfig
    - Generate navigation structure from SiteConfig
    - Write generated HTML to /var/www/html
    - _Requirements: 21.1, 21.2, 21.3, 21.4_

  - [x] 8.2 Implement SEO meta tag generation
    - Generate title tags (format: "Page Title | Business Name")
    - Extract and generate meta descriptions from content
    - Generate Open Graph tags (og:title, og:description, og:image, og:url)
    - Generate canonical URL tags
    - Generate viewport meta tags for mobile responsiveness
    - _Requirements: 22.1, 22.2, 22.3, 22.4, 22.5_

  - [x] 8.3 Implement structured data generation
    - Generate JSON-LD LocalBusiness schema
    - Include business name, address, phone, email
    - Embed structured data in HTML head
    - _Requirements: 22.1_

  - [x] 8.4 Implement sitemap.xml generation
    - Create generateSitemap() method
    - Include all public pages with loc, lastmod, priority
    - Set home page priority to 1.0, others to 0.8
    - Write sitemap.xml to web root
    - Update sitemap when pages are added/removed
    - _Requirements: 23.1, 23.2, 23.3, 23.4, 23.5_

  - [x] 8.5 Implement robots.txt generation
    - Create generateRobotsTxt() method
    - Allow all user agents
    - Include sitemap URL
    - Write robots.txt to web root
    - _Requirements: 23.5_

  - [x] 8.6 Generate responsive HTML with picture elements
    - Create picture elements for images with multiple sources
    - Add media queries for 320px, 768px, 1920px breakpoints
    - Include alt text in img tags
    - Add lazy loading attributes
    - _Requirements: 16.4, 21.4, 29.4_

  - [x] 8.7 Write property tests for HTML generation
    - **Property 41: HTML Generation from Config**
    - **Property 42: Branding in Generated HTML**
    - **Property 43: Navigation Completeness**
    - **Property 44: Responsive HTML Structure**
    - **Property 45: SEO Meta Tags**
    - **Property 46: Sitemap Generation**
    - **Property 26: Alt Text in Generated HTML**
    - **Validates: Requirements 16.4, 21.1, 21.2, 21.3, 21.4, 22.1-22.5, 23.1-23.4**

- [x] 9. Configuration change detection
  - [x] 9.1 Implement ConfigDetector service
    - Use chokidar to watch site.json and pages/*.json
    - Ignore *.temp.json files
    - Implement 5-second debounce timer
    - Trigger StaticGenerator.generateSite() after debounce
    - Handle multiple simultaneous changes with batching
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 9.2 Write property tests for config detection
    - **Property 3: Config Change Batching**
    - **Property 4: Temp Config Ignored by Detector**
    - **Validates: Requirements 5.4, 5.5**

- [x] 10. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Version management and rollback
  - [x] 11.1 Implement VersionManager service
    - Create createBackup() method to save page versions
    - Store versions in /versions/pages/{pageId}/v{N}.json
    - Implement listVersions() method to retrieve version history
    - Implement restoreVersion() method to rollback changes
    - Limit to 10 versions per page, delete oldest when exceeded
    - _Requirements: 27.1, 27.2, 27.3, 27.4_

  - [x] 11.2 Integrate version creation with SessionManager
    - Call createBackup() before confirmChanges()
    - Trigger regeneration after restoreVersion()
    - _Requirements: 27.1, 27.5_

  - [x] 11.3 Write property tests for version management
    - **Property 51: Version Backup Creation**
    - **Property 52: Version Retention Limit**
    - **Property 53: Version Restoration**
    - **Validates: Requirements 27.1, 27.2, 27.4**

- [x] 12. Legal page template generation
  - [x] 12.1 Implement TemplateGenerator service
    - Create generatePrivacyPolicy() method
    - Create generateTermsOfService() method
    - Populate templates with business info from SiteConfig
    - Include placeholders for customization
    - Return PageConfig objects for legal pages
    - _Requirements: 24.1, 24.2, 24.3, 24.4_

  - [x] 12.2 Integrate with onboarding workflow
    - Generate legal pages when legal info is provided
    - Save generated PageConfig files
    - Add legal pages to navigation
    - _Requirements: 8.4_

  - [x] 12.3 Write property tests for legal templates
    - **Property 47: Legal Template Population**
    - **Property 48: Legal Template Placeholders**
    - **Validates: Requirements 24.3, 24.4**

- [x] 13. API routes and controllers
  - [x] 13.1 Implement onboarding endpoints
    - POST /api/onboarding - Process onboarding form
    - Validate required fields
    - Create SiteConfig from form data
    - Create PageConfig files for selected pages
    - Generate navigation structure
    - Generate legal pages if info provided
    - Trigger initial site generation
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 7.1, 7.2, 7.3, 7.4, 7.5, 8.1, 8.2, 8.3, 8.4, 8.5_

  - [x] 13.2 Implement page management endpoints
    - GET /api/pages - List all pages
    - POST /api/pages/:id/edit - Start editing session
    - POST /api/pages/:id/confirm - Confirm changes
    - POST /api/pages/:id/cancel - Cancel changes
    - _Requirements: 11.1, 11.2, 11.3, 12.1, 12.2, 12.3, 12.4, 12.5_

  - [x] 13.3 Implement AI chat endpoint
    - POST /api/pages/:id/ai-chat - Send message to AI
    - Load page context and conversation history
    - Call AIAgent.generateContent()
    - Update TempConfig with AI suggestions
    - Return AI response and updated content
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 10.1, 10.2, 10.3, 10.4, 10.5_

  - [x] 13.4 Implement asset management endpoints
    - POST /api/assets/upload - Upload and process image
    - GET /api/assets - List uploaded assets
    - DELETE /api/assets/:id - Delete asset
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

  - [x] 13.5 Implement version management endpoints
    - GET /api/pages/:id/versions - List versions
    - POST /api/pages/:id/rollback - Restore version
    - _Requirements: 27.3, 27.4, 27.5_

  - [x] 13.6 Implement status endpoint
    - GET /api/status - Return system status
    - Check NGINX status
    - Check SSL certificate expiration
    - Return API usage statistics
    - Return last backup timestamp
    - Return disk usage
    - _Requirements: 26.1, 26.2, 26.3, 26.4, 26.5_

  - [x] 13.7 Write integration tests for API endpoints
    - Test complete onboarding flow
    - Test editing session lifecycle
    - Test AI chat interaction
    - Test asset upload and processing
    - Test version rollback

- [x] 14. Frontend - React application setup
  - [x] 14.1 Initialize React project with Vite
    - Create React + TypeScript project
    - Configure Vite build settings
    - Set up React Router for navigation
    - Configure API client with axios
    - Set up environment variables for API base URL
    - _Requirements: 2.3_

  - [x] 14.2 Create shared UI components
    - Button, Input, Select, Textarea components
    - Modal, Alert, Toast notification components
    - Loading spinner and progress indicators
    - Form validation helpers
    - _Requirements: 6.1, 9.1_

- [x] 15. Frontend - Onboarding wizard
  - [x] 15.1 Implement OnboardingWizard component
    - Create multi-step form with progress indicator
    - Step 1: Business information (name, industry, description)
    - Step 2: Contact information (email, phone, address)
    - Step 3: Branding (colors, logo upload)
    - Step 4: Page selection (Home, About, Services, Contact, custom)
    - Step 5: Legal information (legal name, privacy/terms preferences)
    - Implement form validation for required fields
    - Submit to /api/onboarding on completion
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 7.1, 7.2, 7.3, 8.1, 8.2, 8.3_

  - [x] 15.2 Write property tests for onboarding
    - **Property 5: Onboarding Data Persistence**
    - **Property 6: Required Field Validation**
    - **Property 7: Page Config Creation from Selection**
    - **Property 8: Navigation Matches Selected Pages**
    - **Property 9: Legal Page Generation**
    - **Property 10: Legal Information Storage**
    - **Validates: Requirements 6.5, 6.6, 7.4, 7.5, 8.4, 8.5**

- [x] 16. Frontend - Page editor with AI chat
  - [x] 16.1 Implement PageEditor component
    - Display page title and metadata
    - Show AI chat interface on the left
    - Show content preview on the right
    - Load page data and start editing session on mount
    - Display conversation history
    - Handle user message submission to /api/pages/:id/ai-chat
    - Update preview when AI returns suggestions
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

  - [x] 16.2 Implement AI chat interface
    - Message input with send button
    - Display conversation history with user/assistant messages
    - Show loading indicator during AI processing
    - Display queue status when requests are queued
    - Handle error messages gracefully
    - _Requirements: 9.1, 9.4, 20.4, 20.5_

  - [x] 16.3 Implement content intent capture UI
    - Prompt for page goal, target audience, CTAs
    - Display captured intent in sidebar
    - Allow editing of intent
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [x] 16.4 Implement change confirmation UI
    - Show "Confirm" and "Cancel" buttons
    - Display preview of changes before confirmation
    - Call /api/pages/:id/confirm on confirm
    - Call /api/pages/:id/cancel on cancel
    - Show success message after confirmation
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

  - [x] 16.5 Write property tests for editing workflow
    - **Property 11: Conversation History Preservation**
    - **Property 12: Intent Storage in Temp Config**
    - **Validates: Requirements 9.4, 10.4**

- [x] 17. Frontend - Preview panel
  - [x] 17.1 Implement PreviewPanel component
    - Display iframe with generated HTML
    - Add device size toggle (mobile 375px, tablet 768px, desktop 1920px)
    - Load content from TempConfig during editing
    - Load content from PageConfig for published pages
    - Refresh preview when content updates
    - _Requirements: 25.1, 25.2, 25.3, 25.4, 25.5_

  - [x] 17.2 Write property tests for preview mode
    - **Property 49: Preview Data Source - Active Session**
    - **Property 50: Preview Data Source - Published**
    - **Validates: Requirements 25.4, 25.5**

- [x] 18. Frontend - Asset manager UI
  - [x] 18.1 Implement AssetManager component
    - Display grid of uploaded images
    - Implement drag-and-drop upload
    - Show upload progress
    - Prompt for alt text on upload
    - Display validation errors (format, size)
    - Allow image deletion
    - _Requirements: 13.1, 13.2, 13.4, 16.1, 16.2, 16.5_

- [x] 19. Frontend - Status dashboard
  - [x] 19.1 Implement StatusDashboard component
    - Fetch status from /api/status
    - Display Static Server status with indicator
    - Display SSL certificate status with expiration date
    - Display API usage statistics (requests, tokens, estimated cost)
    - Display last backup timestamp
    - Display disk usage with progress bar
    - Highlight errors with warning indicators
    - Auto-refresh every 30 seconds
    - _Requirements: 26.1, 26.2, 26.3, 26.4, 26.5_

- [x] 20. Frontend - Version history UI
  - [x] 20.1 Implement VersionHistory component
    - Fetch versions from /api/pages/:id/versions
    - Display list of versions with timestamps
    - Show "Restore" button for each version
    - Confirm before restoring
    - Call /api/pages/:id/rollback on restore
    - Show success message after restoration
    - _Requirements: 27.3, 27.4, 27.5_

- [x] 21. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 22. Integration and wiring
  - [x] 22.1 Wire all backend services together
    - Initialize all services in server.js
    - Pass dependencies between services
    - Start ConfigDetector on server startup
    - Start session cleanup job
    - _Requirements: 5.1, 11.4_

  - [x] 22.2 Wire frontend components together
    - Set up routing (/, /onboarding, /pages, /pages/:id/edit, /assets, /status, /versions)
    - Connect API client to all components
    - Implement global error handling
    - Add authentication check (Tailscale)
    - _Requirements: 2.3, 2.5_

  - [x] 22.3 Create build and deployment scripts
    - Write build script for frontend (npm run build)
    - Write build script for backend (tsc)
    - Create deployment script to copy files to server
    - Configure systemd service to start on boot
    - _Requirements: 1.5, 1.6_

  - [x] 22.4 Write end-to-end integration tests
    - Test complete onboarding to published site flow
    - Test editing session with AI interaction
    - Test image upload and optimization
    - Test version rollback
    - Test configuration change detection and regeneration

- [x] 23. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties (60 total)
- Unit tests validate specific examples and edge cases
- The system uses TypeScript for both frontend and backend
- All code should follow TypeScript best practices with strict type checking
- Environment variables must be used for sensitive configuration (API keys, secrets)
- File operations must be atomic to prevent corruption
- API requests must include retry logic and rate limiting
- All user-facing errors must be clear and actionable
