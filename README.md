# AI Website Builder

An AI-powered website builder designed for small business owners to create and manage professional websites through AI-assisted content creation.

## Overview

The AI Website Builder consists of two main components:

1. **Builder Interface**: A VPN-protected web application for content management and AI interaction
2. **Static Server**: A public-facing NGINX server that serves generated HTML pages

The system is optimized to run on AWS Lightsail (1 CPU, 1GB RAM) with a target operational cost of $12-30/month.

## Prerequisites

- Node.js >= 20.0.0
- npm or yarn
- Anthropic API key (Claude)
- AWS Lightsail instance (for production deployment)
- Tailscale VPN (for secure access to Builder Interface)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ai-website-builder
```

2. Install dependencies:
```bash
npm install
```

3. Create environment configuration:
```bash
cp .env.example .env
```

4. Edit `.env` and configure required environment variables:
   - `ANTHROPIC_API_KEY`: Your Claude API key
   - `DOMAIN`: Your domain name
   - `SSL_EMAIL`: Email for Let's Encrypt SSL certificates
   - Other configuration as needed

## Development

Start the development server:
```bash
npm run dev
```

The Builder Interface will be available at `http://localhost:3000`

## Building

Build the TypeScript project:
```bash
npm run build
```

The compiled JavaScript will be output to the `dist/` directory.

## Testing

Run tests:
```bash
npm test
```

Run tests in watch mode:
```bash
npm run test:watch
```

## Project Structure

```
ai-website-builder/
├── app/                    # Application code
│   ├── server.ts          # Express server entry point
│   ├── routes/            # API routes
│   ├── services/          # Business logic services
│   └── public/            # Builder Interface static files
├── config/                # Configuration files (site.json, pages/*.json)
├── assets/                # Asset storage
│   ├── uploads/           # Original uploaded files
│   └── processed/         # Optimized images (320px, 768px, 1920px)
├── versions/              # Version backups
├── logs/                  # Application logs
├── dist/                  # Compiled TypeScript output
└── tests/                 # Test files

```

## Deployment

See the `infrastructure/` directory for deployment scripts and configuration:

- CloudFormation/Terraform templates for AWS Lightsale provisioning
- NGINX configuration
- UFW firewall setup
- Tailscale VPN configuration
- Let's Encrypt SSL automation
- systemd service files

## Architecture

### Security

- Builder Interface is protected behind Tailscale VPN
- Static content is served publicly via NGINX
- Configuration files are stored outside the public web directory
- Automatic SSL certificate management with Let's Encrypt

### Configuration Management

- Site-wide configuration: `config/site.json`
- Page-specific configuration: `config/pages/[page-name].json`
- Temporary editing sessions: `config/pages/[page-name].temp.json`

### AI Integration

- Uses Claude API for content generation
- Rate limiting: 10 requests per minute
- Request queuing for concurrent operations
- Retry logic with exponential backoff

### Image Processing

- Automatic WebP conversion
- Responsive variants: 320px, 768px, 1920px
- Favicon generation from logo
- Alt text management for accessibility

## Environment Variables

See `.env.example` for all available configuration options.

### Required Variables

- `ANTHROPIC_API_KEY`: Claude API key
- `DOMAIN`: Your domain name
- `SSL_EMAIL`: Email for SSL certificates

### Optional Variables

- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Environment (development/production)
- `MAX_REQUESTS_PER_MINUTE`: API rate limit (default: 10)
- `MONTHLY_TOKEN_THRESHOLD`: Token usage alert threshold (default: 1000000)

## License

MIT
