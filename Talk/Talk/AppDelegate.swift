import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var recordingPanel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set dock icon visibility based on user preference
        AppState.shared.updateDockIconVisibility()

        // Setup hotkey manager
        HotkeyManager.shared.setup()

        // Check permissions on launch
        PermissionManager.shared.checkAllPermissions()

        // Show onboarding if first launch or permissions missing
        if !PermissionManager.shared.allPermissionsGranted {
            showOnboarding()
        }

        // Load Whisper model
        Task {
            await WhisperState.shared.loadModel()
        }

        // Auto-launch Ollama if installed
        Task {
            await OllamaManager.shared.ensureRunning()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
        HotkeyManager.shared.cleanup()
    }

    // MARK: - Recording Panel

    func showRecordingPanel() {
        if recordingPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
                styleMask: [.nonactivatingPanel, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.titlebarAppearsTransparent = true
            panel.titleVisibility = .hidden

            let hostingView = NSHostingView(rootView:
                MiniRecorderView()
                    .environmentObject(AppState.shared)
                    .environmentObject(WhisperState.shared)
            )
            panel.contentView = hostingView

            recordingPanel = panel
        }

        // Position near mouse cursor
        if NSScreen.main != nil {
            let mouseLocation = NSEvent.mouseLocation
            let panelSize = recordingPanel!.frame.size
            let x = mouseLocation.x - panelSize.width / 2
            let y = mouseLocation.y + 20
            recordingPanel?.setFrameOrigin(NSPoint(x: x, y: y))
        }

        recordingPanel?.orderFront(nil)
    }

    func hideRecordingPanel() {
        recordingPanel?.orderOut(nil)
    }

    // MARK: - Onboarding

    private var onboardingWindow: NSWindow?

    private func showOnboarding() {
        if onboardingWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Talk Setup"
            window.center()
            window.identifier = NSUserInterfaceItemIdentifier("onboarding")

            let hostingView = NSHostingView(rootView:
                PermissionsView()
                    .environmentObject(PermissionManager.shared)
            )
            window.contentView = hostingView

            onboardingWindow = window
        }

        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
