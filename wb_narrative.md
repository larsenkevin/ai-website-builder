# AI Website Builder Application - Revised Narrative

I've rewritten your narrative incorporating all the feedback and your specific requirements. I've broken it down into **7 manageable sections** that can be worked on sequentially in Kiro without overwhelming token limits.

---

## Section 1: Core Architecture & Hosting

**Scope:** Infrastructure, hosting platform, and fundamental system design

---

### Application Overview

I'd like to develop an application that helps small business owners create a website using agentic AI. The application should be architected as a GitHub repository that can be deployed to an **AWS Lightsail** instance. This is designed for small business owners, so it should run on a minimal instance with one CPU and one gigabyte of RAM.

### Two-Part Architecture

The application consists of two distinct components:

1. **Website Builder Interface** - A simple interface where users interact with the AI assistant, upload files, and manage their website content. This component is accessible only through Tailscale and is not publicly available.

2. **Static Web Server** - The actual NGINX web server that serves the generated static HTML pages to the public internet.

### Technology Stack

The website should use established web technologies:
- **Ubuntu LTS** - Operating system with automatic security updates enabled
- **NGINX** - Web server for serving static content
- **JavaScript** - For builder interface functionality
- **Let's Encrypt** - For SSL/TLS certificates
- **Tailscale** - For secure access to the builder interface

### Hosting & Backup Strategy

- Website backups will be handled through the AWS Lightsail console using instance snapshots
- The Claude API should be configured with monthly spend limits so only actual usage is charged
- Automatic updates should be enabled for OS and open-source packages

### Security Requirements

- Firewall configured to limit access to only necessary ports (80, 443 for public; Tailscale for admin)
- Configuration files stored outside the publicly accessible web directory
- Builder interface accessible only through Tailscale VPN
- No database required - all persistent data stored in JSON files

---

**Kiro Implementation Notes for Section 1:**
- Set up AWS Lightsail instance provisioning scripts
- Configure NGINX with appropriate security headers
- Implement Tailscale integration for builder access
- Create firewall rules (UFW configuration)
- Set up Let's Encrypt certificate automation

---

## Section 2: Configuration System & File Structure

**Scope:** File organization, configuration management, and data persistence

---

### File Structure

```
/var/www/
├── builder/                    # Website builder app (Tailscale only)
│   ├── app.js                  # Main application
│   ├── api/                    # Claude API integration
│   ├── templates/              # Page templates
│   └── static/                 # Builder UI assets
│
├── config/                     # NOT publicly accessible
│   ├── site.json               # Site-wide persistent config
│   ├── pages/
│   │   ├── index.json          # Homepage persistent config
│   │   ├── index.temp.json     # Homepage temp session (if active)
│   │   ├── about.json
│   │   └── ...
│   └── history/
│       └── changelog.json      # Simple version history
│
└── public/                     # NGINX serves this directory
    ├── index.html
    ├── about.html
    ├── contact.html
    ├── legal.html
    ├── assets/
    │   ├── css/
    │   ├── js/
    │   └── images/
    ├── robots.txt
    └── sitemap.xml
```

### Configuration File Types

**1. Site-Wide Persistent Configuration (`site.json`)**

Stores information relevant across the entire website:
- Website name and domain
- Logo file path and favicon variants
- Color scheme (primary, secondary, accent colors)
- CSS framework selection (default: Tailwind CSS)
- Contact information
- Social media links
- Business hours and location
- Analytics configuration (if enabled)
- Legal page links (Terms, Privacy, AUP)
- Site structure map with all pages
- SEO defaults (site title template, default meta description)

**2. Page-Specific Persistent Configuration (`pages/[page-name].json`)**

Stores information for each individual page:
- Page intent/purpose statement
- Target audience for the page
- Key messages and goals
- SEO metadata (title, description, keywords)
- Last modified date
- Version history references

**3. Temporary Session Configuration (`pages/[page-name].temp.json`)**

Used for active editing sessions:
- Chat history for the current session
- Proposed changes not yet committed
- Session start timestamp
- Deleted when changes are committed or user starts over

### Configuration File Rules

- The main configuration file maintains a persistent history of all site pages and their configuration files
- When any user sends a prompt, the system should:
  1. Evaluate what needs to be changed
  2. Read all relevant configuration files
  3. Only work on impacted parts of the site
- If there's a change to the site-wide config file, all existing webpages should be re-evaluated and updated
- If a temporary configuration file grows very large, prompt the user to start over; if confirmed, delete the temp file

---

**Kiro Implementation Notes for Section 2:**
- Create JSON schema definitions for each config type
- Implement config file read/write utilities
- Build config validation functions
- Create NGINX rules to block access to /config directory
- Implement config change detection and propagation logic

---

## Section 3: Onboarding Flow

**Scope:** First-time user experience and initial site setup

---

### Welcome Process

The first time a user connects, the application should guide them through a welcome onboarding process:

**Step 1: Basic Information**
- Website/business name
- Business category/industry (helps with content suggestions)
- Target audience description

**Step 2: Branding**
- Logo upload (if available)
- Color scheme preferences (or suggest based on industry)
- CSS framework selection (default to Tailwind CSS, offer Bootstrap as alternative)

**Step 3: Contact & Business Details**
- Business contact email
- Phone number (optional)
- Physical address (optional, for local SEO)
- Business hours (optional)
- Social media links (optional)

**Step 4: Legal Information**
- Business legal name
- Country/state (affects required disclosures)
- Contact email for legal inquiries

**Step 5: Site Structure Planning**

Guide the user through defining their site structure. Suggest common page templates:

| Template | Purpose | Common Elements |
|----------|---------|-----------------|
| Homepage | First impression, key messages | Hero section, features, CTA, testimonials |
| About Us | Build trust and connection | Story, team, mission statement |
| Services | Showcase offerings | Grid/list of services with descriptions |
| Contact | Enable communication | Contact form (email), map embed, hours |
| FAQ | Answer common questions | Accordion-style Q&A |
| Portfolio/Gallery | Show work examples | Image grid with descriptions |

All site-specific information should be captured in the configuration file and saved for future use. Any future prompt should reference this configuration file to understand the structure of the website.

### Optional Guided Processes

**Domain Registration Guidance (Optional)**

If the user indicates they need help with a domain:
- Explain what a domain name is and why it matters
- Recommend registrars (Namecheap, Cloudflare, Porkbun)
- Provide step-by-step guidance for DNS configuration
- Explain email setup options (if they want name@theirbusiness.com)

**Analytics Setup (Optional)**

Prompt: "Would you like to track how many people visit your website?"
- If yes, guide them through privacy-friendly options:
  - Plausible (privacy-focused, paid)
  - Umami (self-hosted option)
  - Google Analytics (free, more complex)
- Store analytics snippet in site-wide config
- Auto-inject into all pages when enabled

---

**Kiro Implementation Notes for Section 3:**
- Build multi-step onboarding wizard UI
- Create industry-specific color palette suggestions
- Implement logo upload and processing
- Build page template selection interface
- Create optional domain/analytics guidance flows

---

## Section 4: Page Building & Content Coaching

**Scope:** AI-assisted content creation and page editing workflow

---

### Page-by-Page Content Development

After collecting basic information, the onboarding process should prompt the user to go through each page in the site structure one at a time.

**For Each Page:**

1. **Intent Capture**
 - Prompt the user: "What are you trying to accomplish on this page?"
 - Coach them on best practices for that page type
 - Help them research how other businesses accomplish similar goals
 - Store the intent in the page's persistent configuration file

2. **Content Development**
 - Help the user write content with succinct, convincing language in a friendly tone
 - Make content suggestions based on the stated intent
 - Review the intent with the user before suggesting any page changes

3. **Review & Confirmation**
 - User can ask for a summary of changes at any time
 - Claude should recognize keywords like "summarize the changes" or "go ahead and make the changes"
 - All changes must be summarized and confirmed before being committed

### Session Management

**Chat History Persistence:**
- Chat history is stored in the temporary configuration file for the page
- If the chat session is lost, the user can resume using the temp file
- When starting a new session, if a temp file exists, summarize changes in progress

**Session Completion:**
- Once the user confirms making changes, the session history is deleted
- Only the original intent of the webpage is persistently stored
- If there's no temporary file, read the persistent config and summarize as a starting point
- Prompt the user: "What would you like to change today?"

### Intent Conflict Resolution

If a user's prompt conflicts with the stored intent of the page:
- Ask for clarification: "This seems different from the original purpose of this page. Would you like to update the content, or should we also update the page's purpose?"
- Update the appropriate configuration based on user response

### Content Guidelines

- Never suggest copyrighted content
- Only recommend open-source images that are publicly available
- Use appropriate attribution where needed
- Suggest succinct, convincing language that is friendly in tone

---

**Kiro Implementation Notes for Section 4:**
- Build page editing interface with chat
- Implement intent capture and storage
- Create content suggestion engine
- Build change summary generation
- Implement session resume logic
- Create intent conflict detection

---

## Section 5: Image & Asset Management

**Scope:** File uploads, image optimization, and asset organization

---

### Image Optimization Pipeline

Critical for performance on a 1GB RAM instance:

**Upload Processing:**
1. Maximum file size limit: 5MB per image before upload
2. Automatic compression on upload
3. WebP conversion with JPEG/PNG fallbacks for older browsers
4. Responsive image generation (srcset) for different screen sizes
5. Lazy loading implementation for all images

**Image Organization:**
```
/public/assets/images/
├── logo/
│   ├── logo-full.webp
│   ├── logo-full.png (fallback)
│   └── favicon/
│       ├── favicon-16x16.png
│       ├── favicon-32x32.png
│       ├── apple-touch-icon.png
│       └── favicon.ico
├── homepage/
├── about/
└── services/
```

### Asset Management

**Favicon Generation:**
- Automatically generate multiple favicon sizes from uploaded logo
- Create Apple touch icons
- Generate Open Graph images for social sharing

**Font Management:**
- Default to system fonts for performance
- If custom fonts needed, prefer self-hosted over CDN (GDPR compliance)
- Store font choices in site-wide config

**Asset Inventory:**
- Maintain list of all assets in config file
- Detect and flag orphaned files (not referenced by any page)
- Track image alt text status

### Accessibility Requirements

Auto-implement for all images and content:
- Prompt for alt text on all image uploads
- Enforce proper heading hierarchy (h1 → h2 → h3)
- Check color contrast against chosen color scheme
- Add skip navigation links
- Include ARIA labels where needed
- Enforce semantic HTML structure

---

**Kiro Implementation Notes for Section 5:**
- Implement image upload endpoint with size validation
- Build image compression pipeline (sharp.js or similar)
- Create WebP conversion with fallback generation
- Build responsive image generator
- Implement favicon generation from logo
- Create asset inventory tracking
- Build accessibility checker

---

## Section 6: Claude API Integration & Error Handling

**Scope:** AI integration, rate limiting, and graceful error handling

---

### API Integration Best Practices

**Rate Limiting & Throttling:**
- Break down each update to a single page to prevent API throttling
- If multiple pages need editing, queue them for sequential processing
- Implement exponential backoff for rate limit errors
- Track token usage per request

**Context Management:**
- Be aware of Claude API token limits and context length
- Summarize configuration files before including in prompts
- Only include relevant page configs in each request

### Retry Logic

```
Retry Strategy:
├── Initial request
├── If rate limited: wait 1 second, retry
├── If still limited: wait 2 seconds, retry
├── If still limited: wait 4 seconds, retry
├── If still limited: wait 8 seconds, retry
└── After 5 attempts: show error to user
```

### Error Handling

**User-Friendly Error Messages:**
- Display clear, non-technical error messages
- Provide a snippet of the error in an email link format so users can contact the developer
- Example: "Something went wrong. [Click here to email support with error details](mailto:support@example.com?subject=Error&body=Error%20code%3A%20429)"

**Graceful Degradation:**
- Show offline mode indicator in the UI if API is unavailable
- Persist queue if connection drops mid-batch
- Provide manual retry button for users
- Display Claude API status in builder interface

### Queue Management

When multiple pages need updates:
1. Add all pages to a processing queue
2. Process one page at a time
3. Show progress to user (e.g., "Updating page 2 of 5...")
4. If an error occurs, pause queue and notify user
5. Allow user to retry failed page or skip

---

**Kiro Implementation Notes for Section 6:**
- Build Claude API client with retry logic
- Implement request queue system
- Create token counting utility
- Build error message formatter
- Implement email link generator for errors
- Create API status indicator component

---

## Section 7: SEO, Legal Pages, Preview & Monitoring

**Scope:** Search optimization, legal compliance, responsive preview, and system health

---

### SEO Best Practices

**Automatic SEO Implementation:**
- Generate meta tags based on page intent from config
- Create structured data (JSON-LD) for business information
- Build and maintain sitemap.xml automatically
- Generate robots.txt with appropriate rules
- Implement canonical URLs

**Page-Level SEO:**
- Title tags following template: "[Page Title] | [Business Name]"
- Meta descriptions based on page intent
- Proper heading hierarchy (one H1 per page)
- Alt text for all images
- Internal linking suggestions

### Legal Pages

**Auto-Generated Legal Content:**

Store in site-wide config and generate a combined legal page with:
- Terms of Service
- Acceptable Use Policy  
- Privacy Policy

**Required Information (from onboarding):**
- Business legal name
- Business address
- Contact email for legal inquiries
- Country/state (affects required disclosures)
- Cookie usage declaration
- Data collection practices

Insert link to legal page in footer of all pages. Use standard boilerplate but allow user modifications when prompted.

### Contact Form Handling

Contact forms should default to using email (mailto: links). For users who want more functionality, provide guidance on:
- Formspree (free tier available)
- Google Forms embed
- Calendly/Cal.com embed for scheduling

Store preferred contact method in page config.

### Preview Mode

Implement a simple preview system accessible from the website builder:

**Desktop/Tablet/Mobile Views:**
- Desktop preview (1200px+ width)
- Tablet preview (768px width)
- Mobile preview (375px width)

Display previews in iframe or side panel within the builder interface. Allow users to toggle between views before committing changes.

### Monitoring & Health Checks

Implement a simple summary page accessible **only from the website builder interface** (not publicly available):

**Status Dashboard:**
- SSL certificate expiry date and warnings
- Disk space usage
- Last backup date (manual entry or API check)
- NGINX status (running/stopped)
- Recent error log summary (last 10 errors)
- Site uptime indicator

This is a simple status page, not a full monitoring solution. For advanced monitoring, users can optionally integrate UptimeRobot (free tier).

### Version Control & Rollback

**Lightweight Rollback System:**
- Keep last 3-5 versions of each HTML file locally
- Store simple changelog in `/config/history/changelog.json`
- Allow users to say "undo the last change to the homepage"
- Track what changed, when, and provide one-click restore

### Export & Migration

For users who outgrow the system:
- Ensure HTML is clean and portable
- Provide "Download My Site" feature (zip of all public files)
- Document file structure for migration
- Provide guidance on moving to WordPress, Webflow, etc.

---

**Kiro Implementation Notes for Section 7:**
- Build SEO meta tag generator
- Create sitemap.xml auto-generation
- Implement legal page template system
- Build responsive preview component
- Create status dashboard page
- Implement file versioning system
- Build site export/download feature

---

## Summary: Section Breakdown for Kiro

| Section | Focus Area | Key Deliverables |
|---------|------------|------------------|
| 1 | Core Architecture | AWS Lightsail setup, NGINX, Tailscale, security |
| 2 | Configuration System | File structure, JSON schemas, config management |
| 3 | Onboarding Flow | Welcome wizard, branding, site structure planning |
| 4 | Page Building | Content coaching, session management, intent tracking |
| 5 | Asset Management | Image optimization, favicons, accessibility |
| 6 | API Integration | Claude API, rate limiting, error handling, queues |
| 7 | SEO & Extras | Legal pages, preview mode, monitoring, export |

---

## Updated Cost Estimate

| Service | Cost | Notes |
|---------|------|-------|
| AWS Lightsail | $5-7/month | 1 CPU, 1GB RAM instance |
| Domain Name | $10-15/year | Via Namecheap, Cloudflare, etc. |
| Claude API | $5-20/month | Usage-based with spend limits |
| Tailscale | Free | For personal/small team use |
| **Total** | **~$12-30/month** | Significantly less than Squarespace/Wix |

---