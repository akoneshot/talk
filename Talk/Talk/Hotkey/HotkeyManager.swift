import AppKit
import SwiftUI
import Carbon.HIToolbox
import Combine

@MainActor
class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()

    // Settings - Two hotkeys for different modes
    @Published var simpleHotkey: HotkeyType {
        didSet {
            UserDefaults.standard.set(simpleHotkey.rawValue, forKey: "simpleHotkey")
        }
    }

    @Published var advancedHotkey: HotkeyType {
        didSet {
            UserDefaults.standard.set(advancedHotkey.rawValue, forKey: "advancedHotkey")
        }
    }

    // State
    @Published var isHotkeyPressed = false
    @Published var activeHotkeyMode: ProcessingMode? = nil  // Which mode's hotkey is currently pressed

    private var eventMonitor: Any?
    private var flagsMonitor: Any?
    private var isRecording = false
    private var keyDownTime: Date?
    private var recordingMode: ProcessingMode? = nil  // Mode for current recording session
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Initialize from UserDefaults
        if let savedValue = UserDefaults.standard.string(forKey: "simpleHotkey"),
           let hotkey = HotkeyType(rawValue: savedValue) {
            self.simpleHotkey = hotkey
        } else {
            self.simpleHotkey = .rightCommand
        }

        if let savedValue = UserDefaults.standard.string(forKey: "advancedHotkey"),
           let hotkey = HotkeyType(rawValue: savedValue) {
            self.advancedHotkey = hotkey
        } else {
            self.advancedHotkey = .rightOption
        }

        // Observe UserDefaults changes for sync across instances
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let savedValue = UserDefaults.standard.string(forKey: "simpleHotkey"),
                   let hotkey = HotkeyType(rawValue: savedValue),
                   hotkey != self.simpleHotkey {
                    self.simpleHotkey = hotkey
                }
                if let savedValue = UserDefaults.standard.string(forKey: "advancedHotkey"),
                   let hotkey = HotkeyType(rawValue: savedValue),
                   hotkey != self.advancedHotkey {
                    self.advancedHotkey = hotkey
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Setup

    func setup() {
        setupFlagsMonitor()
    }

    func cleanup() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
    }

    // MARK: - Modifier Key Monitoring

    private func setupFlagsMonitor() {
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in
                self?.handleFlagsChanged(event)
            }
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let flags = event.modifierFlags
        let keyCode = event.keyCode

        // Check both hotkeys
        let simplePressed = isHotkeyActive(hotkey: simpleHotkey, flags: flags, keyCode: keyCode)
        let advancedPressed = isHotkeyActive(hotkey: advancedHotkey, flags: flags, keyCode: keyCode)

        // Determine which mode's hotkey is active (simple takes priority if both somehow pressed)
        let newMode: ProcessingMode? = simplePressed ? .simple : (advancedPressed ? .advanced : nil)
        let isPressed = newMode != nil

        if isPressed != isHotkeyPressed || (isPressed && newMode != activeHotkeyMode) {
            let wasPressed = isHotkeyPressed
            isHotkeyPressed = isPressed
            activeHotkeyMode = newMode

            if isPressed && !wasPressed {
                handleHotkeyDown(mode: newMode!)
            } else if !isPressed && wasPressed {
                handleHotkeyUp()
            }
        }
    }

    private func isHotkeyActive(hotkey: HotkeyType, flags: NSEvent.ModifierFlags, keyCode: UInt16) -> Bool {
        switch hotkey {
        case .rightCommand:
            return keyCode == kVK_RightCommand && flags.contains(.command)
        case .leftCommand:
            return keyCode == kVK_Command && flags.contains(.command)
        case .rightOption:
            return keyCode == kVK_RightOption && flags.contains(.option)
        case .leftOption:
            return keyCode == kVK_Option && flags.contains(.option)
        case .rightControl:
            return keyCode == kVK_RightControl && flags.contains(.control)
        case .leftControl:
            return keyCode == kVK_Control && flags.contains(.control)
        case .fn:
            return flags.contains(.function)
        case .capsLock:
            return keyCode == kVK_CapsLock
        }
    }

    // MARK: - Hotkey Actions

    private func handleHotkeyDown(mode: ProcessingMode) {
        keyDownTime = Date()
        recordingMode = mode

        switch AppState.shared.recordingMode {
        case .pushToTalk:
            // Start recording immediately with the specified processing mode
            startRecording(processingMode: mode)
        case .toggle:
            // Do nothing on down - wait for up
            break
        }
    }

    private func handleHotkeyUp() {
        switch AppState.shared.recordingMode {
        case .pushToTalk:
            // Stop recording on release
            if isRecording {
                stopRecording()
            }
        case .toggle:
            // Toggle recording on release (after short press)
            if let downTime = keyDownTime,
               Date().timeIntervalSince(downTime) < 0.5 {
                // Short press - toggle
                if isRecording {
                    stopRecording()
                } else if let mode = recordingMode {
                    startRecording(processingMode: mode)
                }
            }
        }

        keyDownTime = nil
    }

    private func startRecording(processingMode: ProcessingMode) {
        guard !isRecording else { return }
        isRecording = true
        AppState.shared.startRecording(withMode: processingMode)
    }

    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        recordingMode = nil
        AppState.shared.stopRecording()
    }
}

// MARK: - Hotkey Types

enum HotkeyType: String, CaseIterable, Codable {
    case rightCommand = "Right ⌘"
    case leftCommand = "Left ⌘"
    case rightOption = "Right ⌥"
    case leftOption = "Left ⌥"
    case rightControl = "Right ⌃"
    case leftControl = "Left ⌃"
    case fn = "fn"
    case capsLock = "Caps Lock"

    var description: String {
        rawValue
    }
}

// MARK: - Virtual Key Codes

private let kVK_Command: UInt16 = 0x37
private let kVK_RightCommand: UInt16 = 0x36
private let kVK_Option: UInt16 = 0x3A
private let kVK_RightOption: UInt16 = 0x3D
private let kVK_Control: UInt16 = 0x3B
private let kVK_RightControl: UInt16 = 0x3E
private let kVK_CapsLock: UInt16 = 0x39
