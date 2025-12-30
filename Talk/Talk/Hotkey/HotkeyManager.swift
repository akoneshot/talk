import AppKit
import SwiftUI
import Carbon.HIToolbox
import Combine

@MainActor
class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()

    // Settings - Use Published with UserDefaults observation for reliable updates
    @Published var primaryHotkey: HotkeyType {
        didSet {
            UserDefaults.standard.set(primaryHotkey.rawValue, forKey: "primaryHotkey")
        }
    }

    // State
    @Published var isHotkeyPressed = false

    private var eventMonitor: Any?
    private var flagsMonitor: Any?
    private var isRecording = false
    private var keyDownTime: Date?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Initialize from UserDefaults
        if let savedValue = UserDefaults.standard.string(forKey: "primaryHotkey"),
           let hotkey = HotkeyType(rawValue: savedValue) {
            self.primaryHotkey = hotkey
        } else {
            self.primaryHotkey = .rightCommand
        }

        // Observe UserDefaults changes for sync across instances
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let savedValue = UserDefaults.standard.string(forKey: "primaryHotkey"),
                   let hotkey = HotkeyType(rawValue: savedValue),
                   hotkey != self.primaryHotkey {
                    self.primaryHotkey = hotkey
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

        // Check if the configured hotkey is pressed
        let isPressed = isHotkeyActive(flags: flags, keyCode: event.keyCode)

        if isPressed != isHotkeyPressed {
            isHotkeyPressed = isPressed

            if isPressed {
                handleHotkeyDown()
            } else {
                handleHotkeyUp()
            }
        }
    }

    private func isHotkeyActive(flags: NSEvent.ModifierFlags, keyCode: UInt16) -> Bool {
        switch primaryHotkey {
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

    private func handleHotkeyDown() {
        keyDownTime = Date()

        switch AppState.shared.recordingMode {
        case .pushToTalk:
            // Start recording immediately
            startRecording()
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
                } else {
                    startRecording()
                }
            }
        }

        keyDownTime = nil
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        AppState.shared.startRecording()
    }

    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
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
