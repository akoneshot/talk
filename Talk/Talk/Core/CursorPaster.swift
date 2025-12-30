import AppKit
import Carbon.HIToolbox

/// Pastes text at the current cursor position in any application
class CursorPaster {

    /// Paste text at the current cursor position
    /// - Parameters:
    ///   - text: The text to paste
    ///   - preserveClipboard: If true, restores the original clipboard after pasting
    static func paste(_ text: String, preserveClipboard: Bool = true) {
        let pasteboard = NSPasteboard.general

        // Save current clipboard if needed
        var savedItems: [(NSPasteboard.PasteboardType, Data)] = []
        if preserveClipboard {
            savedItems = saveClipboard()
        }

        // Set new text to clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Small delay to ensure clipboard is ready
        usleep(50000)  // 50ms

        // Simulate Cmd+V
        simulatePaste()

        // Restore original clipboard after a delay
        if preserveClipboard {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                restoreClipboard(savedItems)
            }
        }
    }

    // MARK: - Keyboard Simulation

    private static func simulatePaste() {
        guard AXIsProcessTrusted() else {
            print("Accessibility permission not granted - cannot simulate paste")
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)

        // Virtual key codes
        let kVK_Command: CGKeyCode = 0x37
        let kVK_V: CGKeyCode = 0x09

        // Create key events
        guard let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: kVK_Command, keyDown: true),
              let vDown = CGEvent(keyboardEventSource: source, virtualKey: kVK_V, keyDown: true),
              let vUp = CGEvent(keyboardEventSource: source, virtualKey: kVK_V, keyDown: false),
              let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: kVK_Command, keyDown: false) else {
            print("Failed to create key events")
            return
        }

        // Set command flag on V key events
        vDown.flags = .maskCommand
        vUp.flags = .maskCommand

        // Post events
        cmdDown.post(tap: .cghidEventTap)
        vDown.post(tap: .cghidEventTap)
        vUp.post(tap: .cghidEventTap)
        cmdUp.post(tap: .cghidEventTap)
    }

    // MARK: - Clipboard Management

    private static func saveClipboard() -> [(NSPasteboard.PasteboardType, Data)] {
        let pasteboard = NSPasteboard.general
        var saved: [(NSPasteboard.PasteboardType, Data)] = []

        guard let items = pasteboard.pasteboardItems else { return saved }

        for item in items {
            for type in item.types {
                if let data = item.data(forType: type) {
                    saved.append((type, data))
                }
            }
        }

        return saved
    }

    private static func restoreClipboard(_ items: [(NSPasteboard.PasteboardType, Data)]) {
        guard !items.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let item = NSPasteboardItem()
        for (type, data) in items {
            item.setData(data, forType: type)
        }
        pasteboard.writeObjects([item])
    }
}

// MARK: - Paste Eligibility Service

class PasteEligibilityService {

    /// Check if the currently focused element can accept pasted text
    static func canPaste() -> Bool {
        guard AXIsProcessTrusted() else {
            // If we don't have accessibility permission, assume we can paste
            // The paste will just fail silently if we can't
            return true
        }

        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }

        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        var focusedElement: AnyObject?

        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard result == .success, let element = focusedElement else {
            return false
        }

        // Check if the value attribute is settable (i.e., it's an editable field)
        var isSettable: DarwinBoolean = false
        let settableResult = AXUIElementIsAttributeSettable(
            element as! AXUIElement,
            kAXValueAttribute as CFString,
            &isSettable
        )

        return settableResult == .success && isSettable.boolValue
    }

    /// Get the currently selected text (if any)
    static func getSelectedText() -> String? {
        guard AXIsProcessTrusted() else { return nil }

        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        var focusedElement: AnyObject?

        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard result == .success, let element = focusedElement else {
            return nil
        }

        var selectedText: AnyObject?
        let textResult = AXUIElementCopyAttributeValue(
            element as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )

        guard textResult == .success, let text = selectedText as? String else {
            return nil
        }

        return text.isEmpty ? nil : text
    }
}
