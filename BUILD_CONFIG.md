# Build Configuration

This document explains how to configure the server URLs when building the Florid app for different environments.

## Configuration Options

The app uses compile-time environment variables to configure the backend server URLs. This allows you to build different versions of the app for development, staging, and production environments without changing the code.

### Default Configuration

By default, the app uses:
- Server URL: `http://localhost:3000`
- WebSocket URL: `ws://localhost:3000`

These defaults are defined in `lib/constants.dart`.

## Building with Custom Server URLs

### Android/iOS Build

To build the app with custom server URLs:

```bash
flutter build apk --dart-define=SERVER_URL=https://your-server.com --dart-define=WS_URL=wss://your-server.com
```

For iOS:
```bash
flutter build ios --dart-define=SERVER_URL=https://your-server.com --dart-define=WS_URL=wss://your-server.com
```

### Web Build

For web deployment:

```bash
flutter build web --dart-define=SERVER_URL=https://your-server.com --dart-define=WS_URL=wss://your-server.com
```

### Development Builds

For development, you can use the default localhost URLs:

```bash
flutter run
```

Or specify local network URLs for testing on physical devices:

```bash
flutter run --dart-define=SERVER_URL=http://192.168.1.100:3000 --dart-define=WS_URL=ws://192.168.1.100:3000
```

## Production Configuration

For production deployments:

1. **Use HTTPS/WSS**: Always use secure connections in production
2. **Deploy the backend server**: See `server/README.md` for deployment instructions
3. **Configure CORS**: Set `ALLOWED_ORIGINS` in server environment variables
4. **Build with production URLs**: Use the build commands above with your production server URLs

### Example Production Build

```bash
# Build Android APK for production
flutter build apk --release \
  --dart-define=SERVER_URL=https://florid-api.yourcompany.com \
  --dart-define=WS_URL=wss://florid-api.yourcompany.com

# Build Web for production
flutter build web --release \
  --dart-define=SERVER_URL=https://florid-api.yourcompany.com \
  --dart-define=WS_URL=wss://florid-api.yourcompany.com
```

## Server Deployment

The backend server should be deployed with the following considerations:

1. **SSL/TLS Certificate**: Required for HTTPS/WSS
2. **Environment Variables**: Configure via `.env` file (see `server/.env.example`)
3. **CORS Configuration**: Set allowed origins to your web app domain
4. **Rate Limiting**: Adjust based on your usage patterns
5. **Session Management**: Configure session expiry time

See `server/README.md` and `WEB_STORE.md` for detailed server deployment instructions.

## Testing Different Environments

You can maintain different build scripts for different environments:

### `scripts/build-dev.sh`
```bash
#!/bin/bash
flutter build apk \
  --dart-define=SERVER_URL=http://localhost:3000 \
  --dart-define=WS_URL=ws://localhost:3000
```

### `scripts/build-staging.sh`
```bash
#!/bin/bash
flutter build apk \
  --dart-define=SERVER_URL=https://staging.florid-api.yourcompany.com \
  --dart-define=WS_URL=wss://staging.florid-api.yourcompany.com
```

### `scripts/build-prod.sh`
```bash
#!/bin/bash
flutter build apk --release \
  --dart-define=SERVER_URL=https://florid-api.yourcompany.com \
  --dart-define=WS_URL=wss://florid-api.yourcompany.com
```

## Troubleshooting

### Connection Issues

If you can't connect to the server:
1. Check that the server is running and accessible
2. Verify the URLs are correct (http/https, ws/wss)
3. Check firewall settings
4. Verify CORS configuration on the server

### SSL Certificate Issues

For development with self-signed certificates, you may need to handle certificate validation. For production, always use valid SSL certificates from a trusted CA.

### Network Configuration

When testing on physical devices:
- Ensure the device and server are on the same network
- Use the server machine's IP address instead of `localhost`
- Check that the port is not blocked by firewall

## Future Improvements

Potential enhancements for server configuration:
- Runtime configuration through settings UI
- QR code-based server configuration
- Multiple server profiles
- Automatic server discovery
