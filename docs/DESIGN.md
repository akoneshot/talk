# Design System

## UI Philosophy

Talk follows macOS Human Interface Guidelines with a focus on:
- **Minimal footprint** - Lives in menu bar, no dock icon
- **Quick access** - Global hotkey for instant recording
- **Non-intrusive** - Small floating panel during recording
- **Native feel** - Uses system fonts, colors, and controls

## Color Palette

### Primary Colors
```swift
// Recording state
Color.red           // Active recording indicator
Color.green         // Success/connected state
Color.orange        // Processing/warning state

// UI Elements
Color.primary       // Text and icons
Color.secondary     // Muted text
Color.accentColor   // Interactive elements
```

### Background
```swift
// Panels and cards
.background(.ultraThinMaterial)
.background(.regularMaterial)
```

## Typography

Uses system fonts throughout:
```swift
.font(.headline)     // Section headers
.font(.body)         // Primary text
.font(.subheadline)  // Secondary text
.font(.caption)      // Labels, hints
.font(.system(.body, design: .monospaced))  // Code/transcription
```

## Components

### Menu Bar Icon
```swift
Image(systemName: "waveform.circle")        // Idle
Image(systemName: "waveform.circle.fill")   // Recording
    .foregroundStyle(.red)
```

### Recording Panel
- Size: 300x100 points
- Style: Floating panel with blur background
- Position: Near mouse cursor
- Components:
  - Audio level visualizer
  - Recording duration
  - Mode indicator (Simple/Advanced)
  - Cancel button

### Settings Window
- Style: Standard macOS settings with tab navigation
- Tabs:
  - General (launch at login, mode)
  - Hotkeys (shortcut configuration)
  - Transcription (model selection)
  - Enhancement (LLM settings)
  - Audio (input device)
  - Permissions (status)

## Iconography

Uses SF Symbols exclusively:
```swift
// Core actions
"waveform.circle"       // App icon / recording
"mic.fill"              // Microphone
"doc.on.clipboard"      // Paste

// Modes
"wand.and.rays"         // Simple mode
"sparkles"              // Advanced mode

// Status
"checkmark.circle.fill" // Success
"xmark.circle.fill"     // Error
"exclamationmark.triangle.fill"  // Warning

// Settings
"gear"                  // Settings
"keyboard"              // Hotkeys
"cpu"                   // Model
"brain"                 // LLM
"speaker.wave.2"        // Audio
"lock.shield"           // Permissions
```

## Animations

### Recording Pulse
```swift
.animation(.easeInOut(duration: 0.5).repeatForever(), value: isRecording)
```

### Audio Level Visualizer
```swift
// Bar height animated based on audioLevel (0-1)
.animation(.linear(duration: 0.05), value: audioLevel)
```

### State Transitions
```swift
.transition(.opacity.combined(with: .scale))
.animation(.spring(response: 0.3), value: state)
```

## Layout Patterns

### Card Style
```swift
VStack {
    // Content
}
.padding()
.background(.regularMaterial)
.cornerRadius(12)
```

### Settings Row
```swift
HStack {
    Label("Setting Name", systemImage: "icon")
    Spacer()
    Toggle("", isOn: $setting)
}
```

### Status Indicator
```swift
HStack(spacing: 6) {
    Circle()
        .fill(isActive ? .green : .red)
        .frame(width: 8, height: 8)
    Text(statusText)
        .font(.caption)
}
```

## Accessibility

- All interactive elements have labels
- Keyboard navigation support
- VoiceOver compatible
- Reduced motion respects system setting:
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion
```

## Dark/Light Mode

Uses semantic colors that adapt automatically:
```swift
Color.primary          // Adapts to light/dark
Color.secondary        // Adapts to light/dark
.background(.regularMaterial)  // Adapts with blur
```

## Spacing

Uses consistent spacing scale:
```swift
4   // Tight spacing
8   // Default spacing
12  // Comfortable spacing
16  // Section spacing
20  // Large spacing
```
