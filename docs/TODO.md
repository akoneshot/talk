# TODO

## Completed

### Phase 1: Project Setup
- [x] Create project directory structure
- [x] Create TalkApp.swift entry point
- [x] Create AppDelegate.swift
- [x] Create AppState.swift central state
- [x] Create Info.plist
- [x] Create Talk.entitlements
- [x] Create Xcode project (.xcodeproj)

### Phase 2: Whisper Integration
- [x] Create WhisperState.swift
- [x] Create WhisperContext.swift (actor wrapper)
- [x] Build whisper.cpp xcframework
- [x] Add whisper.xcframework to project
- [x] Test transcription pipeline

### Phase 3: Audio Recording
- [x] Create Recorder.swift with AVAudioRecorder
- [x] Implement audio level metering
- [x] Create SoundManager.swift for feedback

### Phase 4: Menu Bar & Hotkey
- [x] Create HotkeyManager.swift
- [x] Create MenuBarView.swift
- [x] Implement push-to-talk mode
- [x] Implement toggle mode

### Phase 5: Recording UI
- [x] Create MiniRecorderView.swift
- [x] Create AudioVisualizerView.swift
- [x] Add cancel button
- [x] Add mode indicator

### Phase 6: Simple Processing
- [x] Create SimpleCleanupProcessor.swift
- [x] Implement filler word removal
- [x] Implement repeated word removal

### Phase 7: Paste Functionality
- [x] Create CursorPaster.swift
- [x] Implement CGEvent paste simulation
- [x] Implement clipboard preservation
- [x] Create PermissionManager.swift

### Phase 8: LLM Integration
- [x] Create LLMProvider.swift protocol
- [x] Create OllamaService.swift
- [x] Create ClaudeService.swift
- [x] Create OpenAIService.swift
- [x] Create AIEnhancementService.swift
- [x] Implement voice direction detection

### Phase 9: Settings UI
- [x] Create SettingsView.swift with tabs
- [x] Create GeneralSettingsTab
- [x] Create HotkeySettingsTab
- [x] Create TranscriptionSettingsTab
- [x] Create EnhancementSettingsTab
- [x] Create PermissionsSettingsTab

### Phase 10: Polish
- [x] Create PermissionsView.swift onboarding
- [x] Create app icon
- [x] Configure code signing
- [x] Create CLAUDE.md
- [x] Create docs/ARCHITECTURE.md
- [x] Create docs/DESIGN.md
- [x] Create docs/FEATURES.md

### Phase 11: Ollama Management (Dec 2024)
- [x] Create OllamaManager.swift for lifecycle management
- [x] Auto-detect Ollama installation (multiple paths + `which`)
- [x] Auto-launch Ollama on app start
- [x] Add Ollama status UI in Settings (installed/running)
- [x] Create ModelBrowserView for in-app model download
- [x] Implement model download with streaming progress
- [x] Implement model deletion
- [x] Add recommended models list (qwen2.5:3b, phi3, gemma2:2b, mistral, llama3.2)
- [x] Set qwen2.5:3b as default model

## Working MVP

The app is fully functional with:
- Voice recording via global hotkey
- Local Whisper transcription
- Simple text cleanup mode
- Advanced LLM enhancement mode (Ollama/Claude/OpenAI)
- Paste anywhere functionality
- Full Ollama lifecycle management

## Future Enhancements

### Core Features
- [ ] Transcription history with SwiftData
- [ ] Custom word replacements dictionary
- [ ] Multiple language support
- [ ] Audio file import
- [ ] Export transcriptions
- [ ] Siri Shortcuts integration

### Context-Aware Enhancement
- [ ] Use screen context for enhancement
- [ ] Use clipboard context for enhancement

### Advanced Audio
- [ ] Streaming transcription (real-time)
- [ ] Noise suppression
- [ ] Voice activity detection (auto start/stop)

### Platform
- [ ] iOS companion app
- [ ] Apple Watch quick record

### Distribution
- [ ] Release build configuration
- [ ] App notarization for distribution
- [ ] DMG installer creation
- [ ] Auto-update mechanism

## Technical Debt

### Testing
- [ ] Add unit tests for SimpleCleanupProcessor
- [ ] Add unit tests for voice direction detection
- [ ] Add integration tests for LLM services
- [ ] Add UI tests for critical flows

### Code Quality
- [ ] Add error tracking/logging
- [ ] Performance profiling
- [ ] Memory leak analysis

### Documentation
- [ ] Add inline code documentation
- [ ] Create user guide
- [ ] Add screenshots to README
