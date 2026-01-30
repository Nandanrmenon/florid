# Florid Backend Server

Backend server for the Florid web companion store feature. Handles device pairing, user authentication, and real-time communication between web and mobile clients.

## Features

- User authentication (JWT-based)
- Device pairing with time-limited codes
- Real-time WebSocket communication
- Install command queue management  
- Rate limiting for API protection

## Prerequisites

- Node.js 16+ and npm
- (Optional) Redis for production-ready session storage

## Installation

```bash
cd backend
npm install
```

## Configuration

Create a `.env` file in the backend directory:

```env
# Server configuration
PORT=3000
NODE_ENV=development

# Security
JWT_SECRET=your-super-secret-jwt-key-change-this

# CORS - comma-separated list of allowed origins
ALLOWED_ORIGINS=http://localhost:8080,https://your-web-app.com
```

**IMPORTANT**: Change the `JWT_SECRET` to a strong random string in production!

## Running the Server

### Development
```bash
npm run dev
```

### Production
```bash
npm start
```

## Deployment

### Heroku
```bash
heroku create florid-backend
heroku config:set JWT_SECRET=your-secret-key
heroku config:set NODE_ENV=production
git push heroku main
```

### Railway
1. Create a new project on Railway.app
2. Connect your GitHub repository
3. Set environment variables in Railway dashboard
4. Deploy automatically on push

### Render.com
1. Create a new Web Service
2. Connect your repository
3. Set environment variables
4. Deploy

## Production Considerations

### Security
- **Change JWT_SECRET**: Use a strong random string
- **HTTPS Only**: Always use HTTPS in production
- **Rate Limiting**: Already implemented, but adjust limits as needed
- **Input Validation**: Add more thorough validation

### Scalability
- **Database**: Replace in-memory storage with PostgreSQL, MongoDB, or similar
- **Redis**: Use Redis for session storage and pub/sub
- **Multiple Instances**: Use sticky sessions or Redis for WebSocket scaling

### Monitoring
- Add logging (Winston, Bunyan)
- Add error tracking (Sentry)
- Add uptime monitoring
- Add performance monitoring (New Relic, DataDog)

## API Documentation

See the full API documentation in the main Florid README.

## License

Same as Florid main project
