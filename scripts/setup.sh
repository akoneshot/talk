#!/bin/bash

# Talk App Setup Script
# This script sets up the development environment for the Talk dictation app

set -e

echo "🎙️ Talk App Setup"
echo "=================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 1. Check for Xcode
echo ""
echo "1️⃣ Checking Xcode..."
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi
XCODE_VERSION=$(xcodebuild -version | head -1)
echo "✅ $XCODE_VERSION"

# 2. Build whisper.cpp
echo ""
echo "2️⃣ Setting up whisper.cpp..."

WHISPER_DIR="$PROJECT_DIR/vendor/whisper.cpp"
FRAMEWORK_DIR="$PROJECT_DIR/Frameworks"

if [ ! -d "$FRAMEWORK_DIR/whisper.xcframework" ]; then
    echo "Building whisper.cpp xcframework..."

    # Clone if not exists
    if [ ! -d "$WHISPER_DIR" ]; then
        mkdir -p "$PROJECT_DIR/vendor"
        git clone https://github.com/ggerganov/whisper.cpp.git "$WHISPER_DIR"
    fi

    # Build xcframework
    cd "$WHISPER_DIR"

    # Create build script for macOS only
    mkdir -p build-macos
    cd build-macos

    cmake .. \
        -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
        -DWHISPER_METAL=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_BUILD_TYPE=Release

    cmake --build . --config Release

    # Create xcframework
    mkdir -p "$FRAMEWORK_DIR"

    echo "⚠️  Manual step required:"
    echo "   The whisper.xcframework needs to be created manually."
    echo "   See: https://github.com/ggerganov/whisper.cpp/tree/master/examples/whisper.swiftui"
    echo ""
    echo "   Alternatively, copy a pre-built whisper.xcframework to:"
    echo "   $FRAMEWORK_DIR/whisper.xcframework"

else
    echo "✅ whisper.xcframework already exists"
fi

# 3. Download a whisper model
echo ""
echo "3️⃣ Downloading Whisper model..."

MODELS_DIR="$HOME/Library/Application Support/Talk/Models"
MODEL_FILE="$MODELS_DIR/ggml-base.en.bin"

if [ ! -f "$MODEL_FILE" ]; then
    mkdir -p "$MODELS_DIR"
    echo "Downloading base.en model..."
    curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin" \
        -o "$MODEL_FILE" \
        --progress-bar
    echo "✅ Model downloaded to $MODEL_FILE"
else
    echo "✅ Model already exists"
fi

# 4. Create Xcode project
echo ""
echo "4️⃣ Xcode Project..."

if [ ! -f "$PROJECT_DIR/Talk.xcodeproj/project.pbxproj" ]; then
    echo "⚠️  Xcode project needs to be created manually:"
    echo ""
    echo "   1. Open Xcode"
    echo "   2. File → New → Project"
    echo "   3. Select 'macOS' → 'App'"
    echo "   4. Product Name: Talk"
    echo "   5. Interface: SwiftUI"
    echo "   6. Language: Swift"
    echo "   7. Save in: $PROJECT_DIR"
    echo ""
    echo "   Then:"
    echo "   - Delete the auto-generated files"
    echo "   - Add existing Swift files from Talk/ folder"
    echo "   - Add whisper.xcframework from Frameworks/"
    echo "   - Configure entitlements (see Talk.entitlements)"
    echo ""
else
    echo "✅ Xcode project exists"
fi

# 5. Summary
echo ""
echo "=================="
echo "🎉 Setup Summary"
echo "=================="
echo ""
echo "Files created:"
find "$PROJECT_DIR/Talk" -name "*.swift" | wc -l | xargs echo "  - Swift files:"
echo ""
echo "Next steps:"
echo "  1. Open/create Talk.xcodeproj in Xcode"
echo "  2. Add Swift files from Talk/ folder"
echo "  3. Add whisper.xcframework"
echo "  4. Configure signing and entitlements"
echo "  5. Build and run!"
echo ""
