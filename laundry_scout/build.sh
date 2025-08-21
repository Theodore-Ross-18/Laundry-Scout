#!/bin/bash

# Exit on error and print commands for debugging
set -e

# Function to print colored output
print_status() {
    echo "[BUILD] $1"
}

# Download and install Flutter
print_status "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
export PATH="$PATH:$(pwd)/_flutter/bin"

# Configure Flutter for CI environment
print_status "Configuring Flutter..."
flutter config --no-analytics
flutter config --enable-web

# Set environment variables for Flutter
export FLUTTER_ROOT="$(pwd)/_flutter"
export PUB_CACHE="$(pwd)/.pub-cache"

# Check Flutter installation
print_status "Checking Flutter version..."
flutter --version

# Clean any previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies with verbose output
print_status "Getting dependencies..."
flutter pub get --verbose

# Check for any analysis issues
print_status "Running Flutter analyze..."
flutter analyze --no-fatal-infos || true

# Build web app with detailed output
print_status "Building web app..."
echo "Environment variables:"
echo "SUPABASE_URL: ${SUPABASE_URL:-https://aoyaedzbgollhajvrxiu.supabase.co}"
echo "SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFveWFlZHpiZ29sbGhhanZyeGl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcyNzY1NzUsImV4cCI6MjA2Mjg1MjU3NX0.iShQfGX-jB7798jk6fLim6m_eGpupzPb8lVgEBTMd1U}"

flutter build web --release --verbose \
  --dart-define=SUPABASE_URL=${SUPABASE_URL:-https://aoyaedzbgollhajvrxiu.supabase.co} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFveWFlZHpiZ29sbGhhanZyeGl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcyNzY1NzUsImV4cCI6MjA2Mjg1MjU3NX0.iShQfGX-jB7798jk6fLim6m_eGpupzPb8lVgEBTMd1U}

# Verify build output
print_status "Verifying build output..."
if [ -d "build/web" ]; then
    echo "Build directory contents:"
    ls -la build/web/
    echo "Build completed successfully!"
else
    echo "ERROR: build/web directory not found!"
    exit 1
fi