#!/bin/bash

# Exit on error
set -e

# Configuration
FLUTTER_SDK_DIR="$HOME/flutter"
PATH="$PATH:$FLUTTER_SDK_DIR/bin"

# 1. Install/Verify Flutter
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
flutter build web --release

echo "Build completed successfully."
