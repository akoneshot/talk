# Talk - Mac Dictation App

A native macOS menu bar app for voice dictation with local Whisper transcription and intelligent text processing.

## Quick Start

```bash
# Build and run (no Xcode GUI needed)
cd Talk
xcodebuild -scheme Talk -configuration Debug -derivedDataPath /tmp/TalkBuild build
open /tmp/TalkBuild/Build/Products/Debug/Talk.app

# Or open in Xcode
open Talk/Talk.xcodeproj
```

## Building whisper.xcframework (if needed)

The whisper.xcframework is already included in `Talk/Talk/whisper.xcframework/`. If you need to rebuild:

```bash
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp && ./build-xcframework.sh
# Copy whisper.xcframework to Talk/Talk/
```

## Project Structure

```
Talk/
├── Talk.xcodeproj/
├── Talk/
│   ├── TalkApp.swift              # @main entry point with MenuBarExtra
│   ├── AppDelegate.swift          # App lifecycle, recording panel, auto-launch Ollama
│   ├── AppState.swift             # Central state management
│   │
│   ├── Core/
│   │   ├── Recorder.swift         # AVAudioRecorder (16kHz, mono, PCM)
│   │   ├── CursorPaster.swift     # CGEvent Cmd+V simulation
│   │   └── SoundManager.swift     # Audio feedback
│   │
│   ├── Whisper/
│   │   ├── WhisperContext.swift   # Actor wrapping whisper.cpp
│   │   └── WhisperState.swift     # Transcription state machine
│   │
│   ├── Processing/
│   │   └── SimpleCleanupProcessor.swift  # Filler word removal
│   │
│   ├── LLM/
│   │   ├── LLMProvider.swift      # Protocol + LLMProviderType enum
│   │   ├── OllamaManager.swift    # Ollama lifecycle: install detection, auto-launch, model download
│   │   ├── OllamaService.swift    # Ollama API calls
│   │   ├── ClaudeService.swift    # Claude API
│   │   ├── OpenAIService.swift    # OpenAI API
│   │   └── AIEnhancementService.swift  # Provider orchestration
│   │
│   ├── Hotkey/
│   │   └── HotkeyManager.swift    # Global hotkey (Right Cmd)
│   │
│   ├── MenuBar/
│   │   └── MenuBarView.swift      # Menu bar UI
│   │
│   ├── Services/
│   │   └── PermissionManager.swift # Mic + Accessibility permissions
│   │
│   ├── Views/
│   │   ├── MiniRecorderView.swift # Recording overlay
│   │   ├── SettingsView.swift     # Preferences (5 tabs) + ModelBrowserView
│   │   └── PermissionsView.swift  # Onboarding
│   │
│   ├── Assets.xcassets/           # App icons
│   ├── Talk.entitlements          # Entitlements file
│   └── whisper.xcframework/       # Built from whisper.cpp
│
└── docs/
    ├── ARCHITECTURE.md
    ├── DESIGN.md
    ├── FEATURES.md
    └── TODO.md
```

## Key Technologies

- **Swift/SwiftUI** - Native macOS 14.0+ app
- **whisper.cpp** - Local speech-to-text (Metal-accelerated)
- **Ollama** - Local LLM with auto-launch and in-app model management
- **Claude/OpenAI** - Cloud LLM alternatives
- **CGEvent** - Keyboard simulation for paste

## Two Processing Modes

1. **Simple**: Regex-based filler word removal, repeated word cleanup
2. **Advanced**: LLM-powered grammar, punctuation, structure enhancement

## Ollama Integration

The app has full Ollama lifecycle management:
- **Auto-detection**: Checks if Ollama is installed
- **Auto-launch**: Starts Ollama on app launch if installed but not running
- **In-app model browser**: Download recommended models without terminal
- **Model management**: Switch between installed models, delete unused ones

### Recommended Models for Text Enhancement
| Model | Size | Description |
|-------|------|-------------|
| qwen2.5:3b | 1.9 GB | Excellent for text tasks, fast (default) |
| phi3 | 2.2 GB | Microsoft, very fast |
| gemma2:2b | 1.6 GB | Google, lightweight |
| mistral | 4.1 GB | High quality, balanced |
| llama3.2 | 2.0 GB | Meta, good all-around |

## Permissions Required

- **Microphone** - For audio recording
- **Accessibility** - For simulating Cmd+V paste

## Development Commands

```bash
# Build only
cd Talk
xcodebuild -scheme Talk -configuration Debug -derivedDataPath /tmp/TalkBuild build

# Build and run
pkill -9 Talk 2>/dev/null
xcodebuild -scheme Talk -configuration Debug -derivedDataPath /tmp/TalkBuild build
open /tmp/TalkBuild/Build/Products/Debug/Talk.app

# Copy to Desktop for sharing
cp -R /tmp/TalkBuild/Build/Products/Debug/Talk.app ~/Desktop/

# Clean extended attributes (if code signing fails)
xattr -cr Talk Talk.xcodeproj

# Check if Ollama is running
curl -s http://localhost:11434

# List Ollama models
curl -s http://localhost:11434/api/tags | jq '.models[].name'
```

## Sharing the App

1. Build: `xcodebuild -scheme Talk -configuration Debug -derivedDataPath /tmp/TalkBuild build`
2. Copy: `cp -R /tmp/TalkBuild/Build/Products/Debug/Talk.app ~/Desktop/`
3. Zip: `cd ~/Desktop && zip -r Talk.zip Talk.app`

Recipients need to:
1. Install Ollama from https://ollama.com/download
2. Right-click → Open (first time, to bypass Gatekeeper)
3. Grant Microphone + Accessibility permissions
4. Download a model via Settings → Enhancement → "Download More Models..."

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - System design and data flow
- [Design System](docs/DESIGN.md) - UI/UX guidelines
- [Features](docs/FEATURES.md) - Complete feature list
- [TODO](docs/TODO.md) - Remaining tasks and future plans
