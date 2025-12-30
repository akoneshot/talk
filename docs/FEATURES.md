# Features

## Core Features

### 1. Voice Recording
- **Global Hotkey**: Record from any application with a keyboard shortcut
- **Push-to-Talk**: Hold key to record, release to transcribe
- **Toggle Mode**: Press to start, press again to stop
- **Visual Feedback**: Floating panel shows recording status and audio level
- **Audio Feedback**: Sound effects for start/stop/success/error

### 2. Local Transcription
- **Whisper Models**: Support for tiny, base, small, medium (English + multilingual)
- **Metal Acceleration**: GPU-accelerated on Apple Silicon
- **Offline**: No internet required for transcription
- **Model Management**: Download and switch between models

### 3. Two Processing Modes

#### Simple Mode
- Remove filler words (um, uh, hmm, ahh, like, you know)
- Remove repeated words ("the the" → "the")
- Clean up extra whitespace
- Basic punctuation cleanup
- Capitalize first letter

#### Advanced Mode
- Grammar correction
- Punctuation enhancement
- Sentence structure improvement
- Paragraph formatting
- Voice direction support ("make this formal")

### 4. Paste Anywhere
- Simulates Cmd+V to paste in any application
- Optional clipboard preservation (restores original content)
- Optional trailing space after paste
- Paste eligibility detection

### 5. LLM Integration

#### Ollama (Local) - Full Lifecycle Management
- **Auto-Detection**: Checks if Ollama is installed on startup
- **Auto-Launch**: Starts Ollama automatically if installed but not running
- **In-App Model Browser**: Download models without using terminal
- **Model Management**: Switch between installed models, delete unused ones
- **Download Progress**: Real-time progress bar during model downloads
- **Recommended Models**: Curated list optimized for text enhancement

| Model | Size | Best For |
|-------|------|----------|
| qwen2.5:3b | 1.9 GB | Fast, excellent text quality (default) |
| phi3 | 2.2 GB | Very fast, Microsoft |
| gemma2:2b | 1.6 GB | Lightweight, Google |
| mistral | 4.1 GB | High quality, balanced |
| llama3.2 | 2.0 GB | Good all-around, Meta |

#### Claude API
- Anthropic Claude integration
- Model selection (Sonnet, Opus, Haiku)
- API key management

#### OpenAI API
- GPT-4o, GPT-4o-mini, GPT-4-turbo
- API key management

## User Settings

### General
- Launch at login
- Processing mode (Simple/Advanced)
- Recording mode (Push-to-talk/Toggle)
- Sound feedback on/off
- Preserve clipboard on/off
- Add trailing space on/off

### Hotkeys
- Primary hotkey selection
- Available keys: Right/Left Command, Option, Control, fn, Caps Lock

### Transcription
- Whisper model selection
- Language selection
- Model download management

### Enhancement (Advanced Mode)
- LLM provider selection (Ollama/Claude/OpenAI)
- **Ollama Status Panel**: Shows installation and running status
- **Model Browser**: Download recommended models with one click
- **Model Picker**: Select from installed models
- API key configuration for Claude/OpenAI
- Custom system prompt

### Permissions
- Microphone permission status
- Accessibility permission status
- Quick links to System Preferences

## Voice Directions

In Advanced mode, you can give instructions in your speech:

```
"make this formal: hey can you help me with something"
→ "Dear [Name], I am writing to request your assistance with a matter."

"format as bullet points: first do this then do that and finally finish up"
→ • First, do this
  • Then, do that
  • Finally, finish up

"reply to this email: sounds good lets meet tomorrow at 3"
→ "Thank you for your message. I would be happy to meet tomorrow at 3:00 PM.
   Please let me know if this time works for you.
   Best regards"
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Right ⌘ (hold) | Record (push-to-talk mode) |
| Right ⌘ (press) | Toggle recording (toggle mode) |
| ⌘, | Open Settings |
| Esc | Cancel recording |

## Menu Bar

The menu bar dropdown provides:
- Current mode indicator
- Quick mode toggle
- Last transcription preview
- Settings access
- Quit option

## First-Time Setup

1. **Launch App**: Click on menu bar icon or use hotkey
2. **Grant Permissions**: Microphone and Accessibility access
3. **Download Whisper Model**: Automatic on first launch (~148 MB)
4. **Configure LLM** (for Advanced mode):
   - Ollama: Install from ollama.com, app auto-launches it
   - Or: Enter Claude/OpenAI API key in Settings
5. **Download LLM Model** (for Ollama): Use Settings → Enhancement → "Download More Models..."

## Future Features (Planned)

- [ ] History of transcriptions
- [ ] Custom word replacements
- [ ] Multiple language support
- [ ] Audio file import
- [ ] Export transcriptions
- [ ] Siri Shortcuts integration
- [ ] Context-aware enhancement (use clipboard content)
- [ ] iOS companion app
- [ ] Apple Watch quick record
