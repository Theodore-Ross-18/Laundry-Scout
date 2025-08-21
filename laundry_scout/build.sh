#!/bin/bash

# Exit on error
set -e

# Download and install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
export PATH="$PATH:$(pwd)/_flutter/bin"

# Check Flutter installation
flutter doctor -v

# Enable web support
flutter config --enable-web

# Get dependencies
flutter pub get

# Build web app
flutter build web --release

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
  }

  fs.readFile(path.resolve(__dirname, filePath), (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        // Page not found, serve index.html for SPA routing
        fs.readFile(path.resolve(__dirname, 'index.html'), (err, content) => {
          if (err) {
            res.writeHead(500);
            res.end('Error loading index.html');
          } else {
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(content, 'utf-8');
          }
        });
      } else {
        res.writeHead(500);
        res.end(`Server Error: ${err.code}`);
      }
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
}).listen(port, () => {
  console.log(`Server running at port ${port}`);
});
EOL

# Create a package.json file for Node.js dependencies
cat > build/web/package.json << 'EOL'
{
  "name": "laundry-scout-web",
  "version": "1.0.0",
  "description": "Laundry Scout Web App",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "engines": {
    "node": ">=14.0.0"
  }
}
EOL