#!/bin/bash
#
# Build whisper.cpp xcframework for macOS only
# This is faster than the full build script
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WHISPER_DIR="$PROJECT_DIR/vendor/whisper.cpp"

echo "🔨 Building whisper.cpp for macOS"
echo "=================================="

# Check prerequisites
echo ""
echo "1️⃣ Checking prerequisites..."

if ! command -v cmake &> /dev/null; then
    echo "❌ CMake not found. Install with: brew install cmake"
    exit 1
fi
echo "✅ CMake found"

if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Install Xcode from App Store"
    exit 1
fi
XCODE_VERSION=$(xcodebuild -version | head -n1)
echo "✅ $XCODE_VERSION"

# Navigate to whisper.cpp
cd "$WHISPER_DIR"
echo ""
echo "2️⃣ Building for macOS (arm64 + x86_64)..."

# Clean previous builds
rm -rf build-macos
rm -rf build-apple

# Build for macOS with Metal support
cmake -B build-macos -G Xcode \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -DBUILD_SHARED_LIBS=OFF \
    -DWHISPER_BUILD_EXAMPLES=OFF \
    -DWHISPER_BUILD_TESTS=OFF \
    -DWHISPER_BUILD_SERVER=OFF \
    -DGGML_METAL=ON \
    -DGGML_METAL_EMBED_LIBRARY=ON \
    -DGGML_BLAS=ON \
    -DGGML_OPENMP=OFF \
    -DWHISPER_COREML=ON \
    -DWHISPER_COREML_ALLOW_FALLBACK=ON \
    -S .

echo ""
echo "3️⃣ Compiling (this may take a few minutes)..."
cmake --build build-macos --config Release -- -quiet

echo ""
echo "4️⃣ Creating framework structure..."

FRAMEWORK_DIR="build-macos/framework/whisper.framework"
mkdir -p "$FRAMEWORK_DIR/Versions/A/Headers"
mkdir -p "$FRAMEWORK_DIR/Versions/A/Modules"
mkdir -p "$FRAMEWORK_DIR/Versions/A/Resources"

# Create symbolic links
ln -sf A "$FRAMEWORK_DIR/Versions/Current"
ln -sf Versions/Current/Headers "$FRAMEWORK_DIR/Headers"
ln -sf Versions/Current/Modules "$FRAMEWORK_DIR/Modules"
ln -sf Versions/Current/Resources "$FRAMEWORK_DIR/Resources"
ln -sf Versions/Current/whisper "$FRAMEWORK_DIR/whisper"

# Copy headers
cp include/whisper.h "$FRAMEWORK_DIR/Versions/A/Headers/"
cp ggml/include/ggml.h "$FRAMEWORK_DIR/Versions/A/Headers/"
cp ggml/include/ggml-alloc.h "$FRAMEWORK_DIR/Versions/A/Headers/"
cp ggml/include/ggml-backend.h "$FRAMEWORK_DIR/Versions/A/Headers/"
cp ggml/include/ggml-metal.h "$FRAMEWORK_DIR/Versions/A/Headers/"
cp ggml/include/ggml-cpu.h "$FRAMEWORK_DIR/Versions/A/Headers/"
cp ggml/include/ggml-blas.h "$FRAMEWORK_DIR/Versions/A/Headers/"
cp ggml/include/gguf.h "$FRAMEWORK_DIR/Versions/A/Headers/"

# Create module map
cat > "$FRAMEWORK_DIR/Versions/A/Modules/module.modulemap" << 'EOF'
framework module whisper {
    header "whisper.h"
    header "ggml.h"
    header "ggml-alloc.h"
    header "ggml-backend.h"
    header "ggml-metal.h"
    header "ggml-cpu.h"
    header "ggml-blas.h"
    header "gguf.h"

    link "c++"
    link framework "Accelerate"
    link framework "Metal"
    link framework "Foundation"
    link framework "CoreML"

    export *
}
EOF

# Create Info.plist
cat > "$FRAMEWORK_DIR/Versions/A/Resources/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>whisper</string>
    <key>CFBundleIdentifier</key>
    <string>org.ggml.whisper</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>whisper</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>14.0</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>MacOSX</string>
    </array>
</dict>
</plist>
EOF

echo ""
echo "5️⃣ Combining static libraries..."

# Combine all static libraries
TEMP_DIR="build-macos/temp"
mkdir -p "$TEMP_DIR"

LIBS=(
    "build-macos/src/Release/libwhisper.a"
    "build-macos/ggml/src/Release/libggml.a"
    "build-macos/ggml/src/Release/libggml-base.a"
    "build-macos/ggml/src/Release/libggml-cpu.a"
    "build-macos/ggml/src/ggml-metal/Release/libggml-metal.a"
    "build-macos/ggml/src/ggml-blas/Release/libggml-blas.a"
)

# Add CoreML library if it exists
if [ -f "build-macos/src/Release/libwhisper.coreml.a" ]; then
    LIBS+=("build-macos/src/Release/libwhisper.coreml.a")
fi

libtool -static -o "$TEMP_DIR/combined.a" "${LIBS[@]}" 2>/dev/null

echo ""
echo "6️⃣ Creating dynamic library..."

xcrun -sdk macosx clang++ -dynamiclib \
    -isysroot $(xcrun --sdk macosx --show-sdk-path) \
    -arch arm64 -arch x86_64 \
    -mmacosx-version-min=14.0 \
    -Wl,-force_load,"$TEMP_DIR/combined.a" \
    -framework Foundation \
    -framework Metal \
    -framework Accelerate \
    -framework CoreML \
    -install_name "@rpath/whisper.framework/Versions/Current/whisper" \
    -o "$FRAMEWORK_DIR/Versions/A/whisper"

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "7️⃣ Creating xcframework..."

mkdir -p build-apple
xcodebuild -create-xcframework \
    -framework "$(pwd)/build-macos/framework/whisper.framework" \
    -output "$(pwd)/build-apple/whisper.xcframework"

echo ""
echo "8️⃣ Copying to project..."

# Copy to project Frameworks directory
mkdir -p "$PROJECT_DIR/Frameworks"
rm -rf "$PROJECT_DIR/Frameworks/whisper.xcframework"
cp -R "$(pwd)/build-apple/whisper.xcframework" "$PROJECT_DIR/Frameworks/"

echo ""
echo "=================================="
echo "✅ Build complete!"
echo ""
echo "Framework location:"
echo "  $PROJECT_DIR/Frameworks/whisper.xcframework"
echo ""
echo "Next steps:"
echo "  1. Open your Xcode project"
echo "  2. Drag whisper.xcframework into your project"
echo "  3. Set 'Embed & Sign' in target settings"
echo ""
