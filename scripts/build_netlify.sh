#!/bin/bash

# Exit on error
set -e

# Configuration
FLUTTER_SDK_DIR="$HOME/flutter"
PATH="$PATH:$FLUTTER_SDK_DIR/bin"

# 1. Install/Verify Flutter
FLUTTER_VERSION=${FLUTTER_VERSION:-"3.10.7"}
export FLUTTER_VERSION
bash scripts/install_flutter.sh

# 2. Install Melos
echo "Installing Melos..."
dart pub global activate melos
export PATH="$PATH":"$HOME/.pub-cache/bin"
# 3. Bootstrap Project
echo "Bootstrapping project with Melos..."
melos bootstrap

# 4. Build Web Application
echo "Building web application..."
cd apps/Web

# Pass environment variables to Flutter build
echo "Using environment variables:"
echo "SUPABASE_URL=${SUPABASE_URL}"
echo "GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}"

flutter build web --release --web-renderer html \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
  --dart-define=GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_API_KEY}"

echo "Build completed successfully."
