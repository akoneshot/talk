import SwiftUI

@main
struct TalkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var whisperState = WhisperState.shared
    @StateObject private var hotkeyManager = HotkeyManager.shared

    var body: some Scene {
        // Menu bar app
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(permissionManager)
                .environmentObject(whisperState)
        } label: {
            MenuBarIcon(isRecording: appState.isRecording)
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(permissionManager)
                .environmentObject(whisperState)
        }

        // Hidden window for permissions onboarding (shown on first launch)
        Window("Welcome to Talk", id: "onboarding") {
            PermissionsView()
                .environmentObject(permissionManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// MARK: - Menu Bar Icon
struct MenuBarIcon: View {
    let isRecording: Bool

    var body: some View {
        Image(systemName: isRecording ? "waveform.circle.fill" : "waveform.circle")
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(isRecording ? .red : .primary)
    }
}
