#!/bin/bash

# Exit on error and print commands for debugging
set -ex

# Download and install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
export PATH="$PATH:$(pwd)/_flutter/bin"

# Configure Flutter for CI environment and disable analytics
flutter config --no-analytics
flutter config --enable-web

# Accept Android licenses and disable interactive prompts
export FLUTTER_ROOT="$(pwd)/_flutter"
export PUB_CACHE="$(pwd)/.pub-cache"

# Check Flutter installation (skip doctor to avoid root warnings)
echo "Flutter version:"
flutter --version

# Get dependencies
flutter pub get

# Build web app with environment variables passed from Vercel
flutter build web --release \
  --dart-define=SUPABASE_URL=${SUPABASE_URL:-https://aoyaedzbgollhajvrxiu.supabase.co} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFveWFlZHpiZ29sbGhhanZyeGl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcyNzY1NzUsImV4cCI6MjA2Mjg1MjU3NX0.iShQfGX-jB7798jk6fLim6m_eGpupzPb8lVgEBTMd1U} \
  --web-renderer canvaskit

# Copy .env file to build/web if it exists
if [ -f ".env" ]; then
  cp .env build/web/
fi

# Create a simple server.js file for Vercel to serve the Flutter web app
cat > build/web/server.js << 'EOL'
const http = require('http');
const fs = require('fs');
const path = require('path');

const port = process.env.PORT || 3000;

http.createServer((req, res) => {
  let filePath = '.' + req.url;
  if (filePath === './') {
    filePath = './index.html';
  }

  const extname = path.extname(filePath);
  let contentType = 'text/html';
  
  switch (extname) {
    case '.js':
      contentType = 'text/javascript';
      break;
    case '.css':
      contentType = 'text/css';
      break;
    case '.json':
      contentType = 'application/json';
      break;
    case '.png':
      contentType = 'image/png';
      break;
    case '.jpg':
      contentType = 'image/jpg';
      break;
    case '.wav':
      contentType = 'audio/wav';
      break;
  }

  fs.readFile(filePath, (error, content) => {
    if (error) {
      if (error.code == 'ENOENT') {
        fs.readFile('./index.html', (error, content) => {
          res.writeHead(200, { 'Content-Type': 'text/html' });
          res.end(content, 'utf-8');
        });
      } else {
        res.writeHead(500);
        res.end('Sorry, check with the site admin for error: ' + error.code + ' ..');
      }
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
}).listen(port);

console.log(`Server running at http://localhost:${port}/`);
EOL

# Create package.json for Node.js server
cat > build/web/package.json << 'EOL'
{
  "name": "laundry-scout-web",
  "version": "1.0.0",
  "description": "Flutter web app server",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "engines": {
    "node": ">=14.0.0"
  }
}
EOL

echo "Build completed successfully!"