# AI Website Builder - Backend Application

## Server Configuration

The Express.js server is configured with the following features:

### Middleware
- **CORS**: Configured with environment-based allowed origins
- **Body Parser**: JSON and URL-encoded request parsing
- **File Upload**: Express-fileupload with 5MB file size limit

### Network Configuration
- **Port**: Configurable via `PORT` environment variable (default: 3000)
- **Bind Address**: Configurable via `BIND_ADDRESS` environment variable (default: 0.0.0.0)
  - For Tailscale VPN integration, set `BIND_ADDRESS` to the Tailscale IP address
  - This ensures the builder interface is only accessible through the VPN

### Error Handling
- Global error handling middleware catches all unhandled errors
- Development mode includes detailed error messages
- Production mode returns generic error messages for security

### Environment Variables
See `.env.example` for all required environment variables.

### Running the Server

Development mode:
```bash
npm run dev
```

Production mode:
```bash
npm run build
npm start
```

### Health Check
The server includes a health check endpoint at `/health` that returns:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```
