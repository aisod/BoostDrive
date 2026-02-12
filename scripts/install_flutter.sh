#!/bin/bash

# Configuration
FLUTTER_VERSION="stable"
FLUTTER_SDK_DIR="$HOME/flutter"

# Check if Flutter is already installed
if [ -d "$FLUTTER_SDK_DIR" ]; then
    echo "Flutter SDK already exists at $FLUTTER_SDK_DIR"
else
    echo "Downloading Flutter SDK ($FLUTTER_VERSION)..."
    git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION $FLUTTER_SDK_DIR
fi

# Add Flutter to PATH
export PATH="$PATH:$FLUTTER_SDK_DIR/bin"

# Verify installation
flutter --version
