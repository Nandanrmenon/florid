# Florid Web Store Backend Examples

This directory contains example backend server implementations for the Florid Web Store feature.

## Available Examples

### Node.js (Express)

A simple Express.js server with in-memory storage.

**Installation:**
```bash
npm install
```

**Run:**
```bash
npm start
```

**Development (with auto-reload):**
```bash
npm run dev
```

### Python (Flask)

A simple Flask server with in-memory storage.

**Installation:**
```bash
pip install -r requirements.txt
```

**Run:**
```bash
python server.py
```

**Production (with Gunicorn):**
```bash
gunicorn -w 4 -b 0.0.0.0:3000 server:app
```

## Configuration

Both servers run on port 3000 by default. You can change this by setting the `PORT` environment variable:

```bash
PORT=8080 npm start
# or
PORT=8080 python server.py
```

## API Endpoints

All servers implement the same REST API:

- `POST /api/pair` - Register a device with a pairing code
- `POST /api/pair/verify` - Verify a pairing code and return device ID
- `POST /api/device/:device_id/install` - Send an install request to a device
- `GET /api/device/:device_id/requests` - Get pending install requests for a device
- `DELETE /api/device/:device_id/requests/:request_id` - Acknowledge a processed request
- `GET /health` - Health check endpoint

## Production Deployment

⚠️ **Important**: These examples use in-memory storage and are **not suitable for production** use. For production:

1. **Use a real database** (PostgreSQL, MongoDB, Redis, etc.) instead of in-memory storage
2. **Add authentication** to protect the API endpoints
3. **Use HTTPS** with valid SSL certificates
4. **Implement rate limiting** to prevent abuse
5. **Add logging and monitoring**
6. **Set up proper error handling**
7. **Use environment variables** for configuration

### Example Production Setup

#### Using Docker with PostgreSQL

Create a `Dockerfile`:
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY server.js ./
EXPOSE 3000
CMD ["node", "server.js"]
```

Create a `docker-compose.yml`:
```yaml
version: '3.8'
services:
  backend:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/florid
    depends_on:
      - db
  
  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=florid
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

#### Deployment on Cloud Platforms

- **Heroku**: `git push heroku main` (add PostgreSQL addon)
- **Vercel**: Deploy as serverless function
- **Railway**: Connect GitHub repo and deploy
- **DigitalOcean App Platform**: Connect repo and deploy
- **AWS**: Use Elastic Beanstalk or Lambda + API Gateway
- **Google Cloud**: Use Cloud Run or App Engine

## Security Considerations

- Use HTTPS in production
- Implement API authentication (OAuth, JWT, API keys)
- Add rate limiting (e.g., with `express-rate-limit`)
- Validate all input data
- Use environment variables for sensitive config
- Implement CORS properly for your domain
- Add request logging and monitoring
- Set up security headers (helmet.js for Express)

## Database Schema Example

For production with PostgreSQL:

```sql
CREATE TABLE pairings (
    pairing_code VARCHAR(6) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE install_requests (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    package_name VARCHAR(255) NOT NULL,
    version_name VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_device_requests ON install_requests(device_id, status);
CREATE INDEX idx_pairing_expiry ON pairings(expires_at);
```

## Testing

Test the API with curl:

```bash
# Health check
curl http://localhost:3000/health

# Register pairing
curl -X POST http://localhost:3000/api/pair \
  -H "Content-Type: application/json" \
  -d '{"device_id":"test123","pairing_code":"123456","expires_at":"2024-12-31T23:59:59Z"}'

# Verify pairing
curl -X POST http://localhost:3000/api/pair/verify \
  -H "Content-Type: application/json" \
  -d '{"pairing_code":"123456"}'

# Send install request
curl -X POST http://localhost:3000/api/device/test123/install \
  -H "Content-Type: application/json" \
  -d '{"package_name":"org.fdroid.fdroid","version_name":"1.20.0"}'

# Get pending requests
curl http://localhost:3000/api/device/test123/requests
```

## License

Same as the main Florid project (GPL-3.0)
