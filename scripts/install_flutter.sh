#!/bin/bash

# Configuration
FLUTTER_VERSION=${FLUTTER_VERSION:-"stable"}
FLUTTER_SDK_DIR="$HOME/flutter"

# Check if Flutter is already installed
if [ -d "$FLUTTER_SDK_DIR/.git" ]; then
    echo "Updating Flutter SDK to ($FLUTTER_VERSION)..."
    cd "$FLUTTER_SDK_DIR"
    git fetch origin
    git checkout "$FLUTTER_VERSION"
    cd -
elif [ -d "$FLUTTER_SDK_DIR" ]; then
    echo "Directory exists but is not a git repo. Reinstalling..."
    rm -rf "$FLUTTER_SDK_DIR"
    git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" "$FLUTTER_SDK_DIR"
else
    echo "Downloading Flutter SDK ($FLUTTER_VERSION)..."
    git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" "$FLUTTER_SDK_DIR"
fi

# Add Flutter to PATH
export PATH="$FLUTTER_SDK_DIR/bin:$PATH"

# Verify installation
flutter --version
