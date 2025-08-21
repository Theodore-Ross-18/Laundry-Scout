#!/bin/bash

# Exit on error and print commands for debugging
set -ex

# Download and install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
export PATH="$PATH:$(pwd)/_flutter/bin"

# Configure Flutter for CI environment and disable analytics
flutter config --no-analytics
flutter config --enable-web

# Set environment variables for Flutter
export FLUTTER_ROOT="$(pwd)/_flutter"
export PUB_CACHE="$(pwd)/.pub-cache"

# Check Flutter installation (skip doctor to avoid root warnings)
echo "Flutter version:"
flutter --version

# Get dependencies
flutter pub get

# Build web app with environment variables passed from Vercel
# Note: Removed --web-renderer canvaskit as it's not a valid option
flutter build web --release \
  --dart-define=SUPABASE_URL=${SUPABASE_URL:-https://aoyaedzbgollhajvrxiu.supabase.co} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFveWFlZHpiZ29sbGhhanZyeGl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcyNzY1NzUsImV4cCI6MjA2Mjg1MjU3NX0.iShQfGX-jB7798jk6fLim6m_eGpupzPb8lVgEBTMd1U}

# Verify build output
echo "Build completed. Checking output directory:"
ls -la build/web/

# Copy .env file to build/web if it exists
if [ -f ".env" ]; then
  cp .env build/web/
fi

echo "Build completed successfully!"