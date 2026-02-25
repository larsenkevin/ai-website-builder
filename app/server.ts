import express from 'express';
import cors from 'cors';
import fileUpload from 'express-fileupload';
import dotenv from 'dotenv';
import * as path from 'path';
import { logger } from './services/Logger.js';
import { correlationIdMiddleware } from './middleware/correlationId.js';
import { requestLoggerMiddleware } from './middleware/requestLogger.js';
import { ConfigManager } from './services/ConfigManager.js';
import { SessionManager } from './services/SessionManager.js';
import { AIAgent } from './services/AIAgent.js';
import { RateLimiter } from './services/RateLimiter.js';
import { AssetProcessor } from './services/AssetProcessor.js';
import { StaticGenerator } from './services/StaticGenerator.js';
import { ConfigDetector } from './services/ConfigDetector.js';
import { VersionManager } from './services/VersionManager.js';
import { TemplateGenerator } from './services/TemplateGenerator.js';
import { createOnboardingRouter } from './routes/onboarding.js';
import { createPagesRouter } from './routes/pages.js';
import { createAssetsRouter } from './routes/assets.js';
import { createStatusRouter } from './routes/status.js';

// Load environment variables
dotenv.config();

const app = express();
const PORT = parseInt(process.env.PORT || '3000', 10);

// Initialize services
const configDir = process.env.CONFIG_DIR || path.join(process.cwd(), 'config');
const assetsDir = process.env.ASSETS_DIR || path.join(process.cwd(), 'assets');
const publicDir = process.env.PUBLIC_DIR || path.join(process.cwd(), 'public');
const versionsDir = process.env.VERSIONS_DIR || path.join(process.cwd(), 'versions');

const configManager = new ConfigManager({ configDir });

const sessionManager = new SessionManager(configManager);

const rateLimiter = new RateLimiter(
  {
    maxRequestsPerMinute: parseInt(process.env.MAX_REQUESTS_PER_MINUTE || '10'),
    monthlyTokenThreshold: parseInt(process.env.MONTHLY_TOKEN_THRESHOLD || '1000000'),
  },
  logger
);

const aiAgent = new AIAgent(
  {
    apiKey: process.env.ANTHROPIC_API_KEY || '',
    model: 'claude-3-5-sonnet-20241022',
    maxTokens: 4096,
    temperature: 0.7,
  },
  logger,
  rateLimiter
);

const assetProcessor = new AssetProcessor(
  {
    uploadsDir: path.join(assetsDir, 'uploads'),
    processedDir: path.join(assetsDir, 'processed'),
    publicDir,
    maxFileSize: 5 * 1024 * 1024, // 5MB
    sizes: [320, 768, 1920],
    webpQuality: 85,
  },
  logger
);

const staticGenerator = new StaticGenerator(
  {
    publicDir,
    assetsDir,
  },
  configManager,
  logger
);

const configDetector = new ConfigDetector(
  {
    configDir,
    debounceMs: 5000,
  },
  staticGenerator,
  logger
);

const versionManager = new VersionManager(
  {
    versionsDir,
    maxVersions: 10,
  },
  configManager,
  logger
);

const templateGenerator = new TemplateGenerator(logger);

// Start config detector
configDetector.start();

// Start session cleanup job (runs every hour)
setInterval(() => {
  sessionManager.cleanupAbandonedSessions();
}, 60 * 60 * 1000);

// Correlation ID middleware (must be first)
app.use(correlationIdMiddleware);

// Request logging middleware
app.use(requestLoggerMiddleware);

// Middleware
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(fileUpload({
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max file size
  abortOnLimit: true,
}));

// Health check endpoint
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API routes
app.use('/api/onboarding', createOnboardingRouter(
  configManager,
  templateGenerator,
  staticGenerator,
  logger
));

app.use('/api/pages', createPagesRouter(
  configManager,
  sessionManager,
  aiAgent,
  versionManager,
  logger
));

app.use('/api/assets', createAssetsRouter(
  assetProcessor,
  logger
));

app.use('/api/status', createStatusRouter(
  rateLimiter,
  logger,
  publicDir
));

// Error handling middleware
app.use((err: Error, req: express.Request, res: express.Response, _next: express.NextFunction) => {
  // Log the error with correlation ID
  logger.error('Unhandled error', {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  }, req.correlationId);

  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
    correlationId: req.correlationId,
  });
});

// Start server
const BIND_ADDRESS = process.env.BIND_ADDRESS || '0.0.0.0';

const server = app.listen(PORT, BIND_ADDRESS, () => {
  logger.info('Server started', {
    address: BIND_ADDRESS,
    port: PORT,
    environment: process.env.NODE_ENV || 'development',
  });
  console.log(`AI Website Builder server running on ${BIND_ADDRESS}:${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  configDetector.stop();
  rateLimiter.stop();
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  configDetector.stop();
  rateLimiter.stop();
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

export default app;
