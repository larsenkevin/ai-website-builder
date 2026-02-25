# Services

This directory contains core business logic services for the AI Website Builder.

## Logger Service

The Logger service provides comprehensive structured logging with the following features:

### Features

- **Structured JSON Logging**: All log entries are formatted as JSON for easy parsing and analysis
- **Log Levels**: ERROR, WARN, INFO, DEBUG with configurable filtering
- **Correlation IDs**: Unique identifiers for request tracing across the system
- **Automatic Log Rotation**: Rotates log files when they exceed 100MB (configurable)
- **Log Retention**: Automatically deletes log files older than 30 days (configurable)
- **Stack Traces**: Automatically captures stack traces for ERROR level logs

### Usage

```typescript
import { logger } from './services/Logger.js';

// Basic logging
logger.info('User logged in', { userId: '123' });
logger.warn('Rate limit approaching', { current: 9, limit: 10 });
logger.error('Database connection failed', { error: err });
logger.debug('Processing request', { requestId: 'abc' });

// With correlation ID
const correlationId = logger.generateCorrelationId();
logger.info('Starting operation', { operation: 'backup' }, correlationId);

// Helper methods
logger.logApiRequest('GET', '/api/users', 200, 150, correlationId);
logger.logConfigChange('page', 'home', 'update', correlationId);
```

### Configuration

Configure via environment variables:

```bash
LOG_DIR=/opt/website-builder/logs    # Directory for log files
LOG_LEVEL=info                        # Minimum log level (error, warn, info, debug)
LOG_ROTATION_SIZE=100MB               # Max size before rotation
LOG_RETENTION_DAYS=30                 # Days to retain old logs
```

### Log Entry Format

Each log entry is a JSON object with the following structure:

```json
{
  "timestamp": "2024-01-15T10:30:45.123Z",
  "level": "INFO",
  "message": "API request",
  "correlationId": "550e8400-e29b-41d4-a716-446655440000",
  "metadata": {
    "method": "GET",
    "path": "/api/pages",
    "statusCode": 200,
    "duration": 150
  },
  "stack": "Error: ...\n    at ..."  // Only for ERROR level
}
```

### Middleware

The logging infrastructure includes Express middleware:

#### Correlation ID Middleware

Automatically generates or extracts correlation IDs from requests:

```typescript
import { correlationIdMiddleware } from './middleware/correlationId.js';

app.use(correlationIdMiddleware);

// Access in route handlers
app.get('/api/test', (req, res) => {
  console.log(req.correlationId); // Available on all requests
});
```

#### Request Logger Middleware

Automatically logs all API requests:

```typescript
import { requestLoggerMiddleware } from './middleware/requestLogger.js';

app.use(requestLoggerMiddleware);
// All requests are now automatically logged
```

### Requirements Validation

The Logger service validates the following requirements:

- **Requirement 30.1**: Logs all API requests and responses
- **Requirement 30.2**: Logs all configuration file modifications
- **Requirement 30.3**: Logs all errors with stack traces
- **Requirement 30.4**: Rotates log files when they exceed 100MB
- **Requirement 30.5**: Retains log files for 30 days

### Testing

The Logger service includes comprehensive tests:

- **Unit Tests**: `tests/unit/Logger.test.ts`
- **Property Tests**: `tests/property/logging.property.test.ts`

Run tests with:

```bash
npm test
```
