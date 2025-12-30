# AK Tasks - Talk App Setup

## Prerequisites
- [ ] Xcode 15+ installed
- [ ] macOS 14.0+ (Sonoma or later)
- [ ] Apple Developer account (for signing)

---

## Step 1: Build Whisper Framework ✅ DONE

Framework built and ready at:
```
Frameworks/whisper.xcframework (4.8 MB)
```

Model downloaded to:
```
~/Library/Application Support/Talk/Models/ggml-base.en.bin (141 MB)
```

---

## Step 2: Create Xcode Project (10 min)

1. Open Xcode
2. **File → New → Project**
3. Select **macOS → App**
4. Configure:
   - Product Name: `Talk`
   - Team: Your team
   - Organization Identifier: `com.yourname`
   - Interface: **SwiftUI**
   - Language: **Swift**
5. Save in: `/Users/ak/Documents/git-projects/talk`
6. **Delete** the auto-generated `ContentView.swift` and `TalkApp.swift`

---

## Step 3: Add Source Files (5 min)

1. In Xcode, right-click on `Talk` folder in navigator
2. **Add Files to "Talk"...**
3. Navigate to `/Users/ak/Documents/git-projects/talk/Talk`
4. Select **all .swift files** (Cmd+A)
5. Check: ✅ Copy items if needed
6. Check: ✅ Create folder references
7. Click **Add**

---

## Step 4: Add SPM Dependencies (5 min)

1. **File → Add Package Dependencies...**
2. Add these packages:

| Package URL | Version |
|------------|---------|
| `https://github.com/sindresorhus/KeyboardShortcuts` | 2.0.0+ |
| `https://github.com/sindresorhus/LaunchAtLogin-Modern` | 1.0.0+ |

---

## Step 5: Add Whisper Framework (5 min)

1. Drag `whisper.xcframework` into Xcode's `Frameworks` folder
2. Or: **File → Add Files** → select the framework
3. In target settings → **General → Frameworks**:
   - Ensure it's set to **Embed & Sign**

---

## Step 6: Configure Info.plist (5 min)

1. Select your target → **Info** tab
2. Add these keys (or copy from `Talk/Info.plist`):

| Key | Value |
|-----|-------|
| `LSUIElement` | `YES` (hides dock icon) |
| `NSMicrophoneUsageDescription` | Talk needs microphone access to record your voice. |

---

## Step 7: Configure Entitlements (5 min)

1. Select target → **Signing & Capabilities**
2. Click **+ Capability**
3. Add:
   - **App Sandbox**
   - Under App Sandbox, enable:
     - ✅ Audio Input (Microphone)
     - ✅ Outgoing Connections (Client)

**Note**: For paste functionality to work, you may need to:
- Disable App Sandbox, OR
- Distribute outside App Store with hardened runtime

---

## Step 8: Download Whisper Model ✅ DONE

Model already downloaded:
```
~/Library/Application Support/Talk/Models/ggml-base.en.bin (141 MB)
```

---

## Step 9: Build & Run (2 min)

1. Select **My Mac** as destination
2. **Cmd+R** to build and run
3. Grant permissions when prompted:
   - Microphone access
   - Accessibility access (System Settings → Privacy → Accessibility)

---

## Step 10: Test the App

1. Look for waveform icon in menu bar
2. Hold **Right Command** key to record
3. Speak something
4. Release to transcribe and paste

---

## Troubleshooting

### "whisper" module not found
- Ensure `whisper.xcframework` is added and embedded

### Paste doesn't work
- Grant Accessibility permission in System Settings
- May need to disable App Sandbox for CGEvent paste

### No audio recording
- Grant Microphone permission
- Check audio input device in Settings

### Model not loading
- Verify model exists at `~/Library/Application Support/Talk/Models/`
- Try downloading a different model size

---

## Optional: LLM Setup

### For Ollama (Local)
```bash
# Install Ollama
brew install ollama

# Start Ollama
ollama serve

# Pull a model
ollama pull llama3.2
```

### For Claude API
1. Get API key from [console.anthropic.com](https://console.anthropic.com)
2. Add in Talk Settings → Enhancement → Claude API Key

### For OpenAI API
1. Get API key from [platform.openai.com](https://platform.openai.com)
2. Add in Talk Settings → Enhancement → OpenAI API Key

---

## Time Estimate

| Task | Time |
|------|------|
| Build whisper.cpp | 30 min |
| Create Xcode project | 10 min |
| Add files & dependencies | 15 min |
| Configure & build | 10 min |
| **Total** | **~1 hour** |
