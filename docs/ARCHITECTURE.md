# Architecture

## Overview

Talk is a native macOS dictation app built with Swift/SwiftUI. It follows a clean architecture pattern with clear separation of concerns.

## Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                        TalkApp                               │
│                    (MenuBarExtra + Settings)                 │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
       ┌──────────┐    ┌──────────┐    ┌──────────┐
       │ AppState │    │ Hotkey   │    │ Whisper  │
       │ (Central │    │ Manager  │    │ State    │
       │  State)  │    │          │    │          │
       └──────────┘    └──────────┘    └──────────┘
              │               │               │
              ▼               ▼               ▼
       ┌──────────┐    ┌──────────┐    ┌──────────┐
       │ Recorder │    │ CGEvent  │    │ Whisper  │
       │          │    │ Paste    │    │ Context  │
       └──────────┘    └──────────┘    └──────────┘
```

## LLM Subsystem

```
┌─────────────────────────────────────────────────────────────┐
│                   AIEnhancementService                       │
│                   (Provider Orchestrator)                    │
└─────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
  │   Ollama    │      │   Claude    │      │   OpenAI    │
  │   Service   │      │   Service   │      │   Service   │
  └─────────────┘      └─────────────┘      └─────────────┘
         │
         ▼
  ┌─────────────┐
  │   Ollama    │  ← Lifecycle management
  │   Manager   │    (install detection, auto-launch, model download)
  └─────────────┘
```

## Data Flow

### Recording Flow
```
1. User presses hotkey
2. HotkeyManager detects key event
3. AppState.startRecording() called
4. Recorder starts AVAudioRecorder
5. MiniRecorderView shows recording UI
```

### Transcription Flow
```
1. User releases hotkey
2. Recorder.stopRecording() returns audio URL
3. WhisperState.transcribe() converts to samples
4. WhisperContext (actor) runs whisper.cpp
5. Returns transcribed text
```

### Processing Flow
```
1. Transcribed text received
2. Based on processingMode:
   - Simple: SimpleCleanupProcessor.process()
   - Advanced: AIEnhancementService.enhance()
3. Processed text ready
```

### Paste Flow
```
1. Save current clipboard (if preserveClipboard)
2. Set text to NSPasteboard
3. Simulate Cmd+V via CGEvent
4. Restore clipboard after 500ms delay
```

### Ollama Lifecycle Flow
```
1. App launches
2. AppDelegate calls OllamaManager.ensureRunning()
3. OllamaManager checks if Ollama is running (HTTP to localhost:11434)
4. If not running but installed:
   - Find ollama binary (multiple paths + which command)
   - Start `ollama serve` as background Process
   - Poll until ready (up to 10 seconds)
5. Refresh installed models list
6. User can download/delete models via Settings UI
```

## Key Design Patterns

### Singleton Services
```swift
class AppState: ObservableObject {
    static let shared = AppState()
}
```

All core services use singleton pattern for global access:
- `AppState.shared` - Central state
- `WhisperState.shared` - Transcription
- `HotkeyManager.shared` - Hotkeys
- `PermissionManager.shared` - Permissions
- `OllamaManager.shared` - Ollama lifecycle
- `OllamaService.shared` - Ollama API
- `ClaudeService.shared` - Claude API
- `OpenAIService.shared` - OpenAI API

### Actor for Thread Safety
```swift
actor WhisperContext {
    func transcribe(samples: [Float]) -> Bool
}
```

WhisperContext uses Swift's actor model to ensure thread-safe access to the whisper.cpp C library.

### Protocol for LLM Providers
```swift
protocol LLMProviderProtocol {
    var isConfigured: Bool { get }
    func generate(text: String, systemPrompt: String) async throws -> String
}
```

All LLM services (Ollama, Claude, OpenAI) conform to this protocol.

### Separation of Concerns: Manager vs Service
```swift
// OllamaManager - Lifecycle management
class OllamaManager: ObservableObject {
    func ensureRunning() async -> Bool
    func pullModel(_ name: String) async -> Bool
    func deleteModel(_ name: String) async -> Bool
}

// OllamaService - API communication
class OllamaService: ObservableObject, LLMProviderProtocol {
    func generate(text: String, systemPrompt: String) async throws -> String
}
```

OllamaManager handles installation detection, auto-launch, and model management.
OllamaService handles the actual LLM API calls for text generation.

## State Management

### @AppStorage for Persistence
```swift
@AppStorage("processingMode") var processingMode: ProcessingMode = .simple
@AppStorage("ollamaModel") var selectedModel: String = "qwen2.5:3b"
```

User preferences are automatically persisted to UserDefaults.

### @Published for Reactivity
```swift
@Published var isRecording = false
@Published var isDownloading = false
@Published var downloadProgress: Double = 0
```

Observable state changes trigger SwiftUI view updates.

### @MainActor for Thread Safety
```swift
@MainActor
class AppState: ObservableObject { }

@MainActor
class OllamaManager: ObservableObject { }
```

Ensures all state updates happen on the main thread.

## Module Breakdown

### Core/
- `Recorder.swift` - AVAudioRecorder wrapper, audio level metering
- `CursorPaster.swift` - CGEvent keyboard simulation, clipboard management
- `SoundManager.swift` - Audio feedback sounds

### Whisper/
- `WhisperContext.swift` - Actor wrapping whisper.cpp
- `WhisperState.swift` - Model loading, transcription orchestration

### Processing/
- `SimpleCleanupProcessor.swift` - Regex-based text cleanup

### LLM/
- `LLMProvider.swift` - Protocol and types
- `OllamaManager.swift` - Ollama lifecycle (install, launch, model management)
- `OllamaService.swift` - Local LLM via Ollama API
- `ClaudeService.swift` - Anthropic Claude API
- `OpenAIService.swift` - OpenAI API
- `AIEnhancementService.swift` - Provider orchestration

### Hotkey/
- `HotkeyManager.swift` - Global keyboard event monitoring

### Services/
- `PermissionManager.swift` - macOS permission handling

### Views/
- `SettingsView.swift` - Settings tabs + ModelBrowserView
- `MiniRecorderView.swift` - Recording overlay
- `PermissionsView.swift` - Onboarding permissions

## Dependencies

### Apple Frameworks
- AVFoundation (audio recording)
- AppKit (clipboard, events)
- Carbon (key codes)
- SwiftUI (UI)
- Combine (reactive state)

### External
- whisper.xcframework - Built from whisper.cpp

## Network Communication

### Ollama API (localhost:11434)
- `GET /` - Health check
- `GET /api/tags` - List installed models
- `POST /api/generate` - Generate text (non-streaming)
- `POST /api/pull` - Download model (streaming progress)
- `DELETE /api/delete` - Remove model

### Claude API (api.anthropic.com)
- `POST /v1/messages` - Generate text

### OpenAI API (api.openai.com)
- `POST /v1/chat/completions` - Generate text
