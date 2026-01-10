import SwiftUI
import AVFoundation

struct PermissionsView: View {
    @EnvironmentObject var permissionManager: PermissionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Welcome to DictAI")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Voice dictation with AI enhancement")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Permissions
            VStack(alignment: .leading, spacing: 20) {
                Text("DictAI needs a few permissions to work:")
                    .font(.headline)

                // Microphone Permission
                PermissionRow(
                    icon: "mic.fill",
                    title: "Microphone",
                    description: "To record your voice for transcription",
                    isGranted: permissionManager.microphoneStatus == .authorized,
                    action: {
                        print("[PermissionsView] Microphone Grant button tapped")
                        Task {
                            await permissionManager.requestMicrophonePermission()
                        }
                    }
                )

                // Accessibility Permission
                PermissionRow(
                    icon: "accessibility",
                    title: "Accessibility",
                    description: "To paste text wherever your cursor is",
                    isGranted: permissionManager.accessibilityEnabled,
                    action: {
                        print("[PermissionsView] Accessibility Grant button tapped")
                        permissionManager.requestAccessibilityPermission()
                    }
                )
            }
            .padding()
            .background(.quaternary)
            .cornerRadius(12)

            Spacer()

            // Continue Button
            VStack(spacing: 12) {
                if permissionManager.allPermissionsGranted {
                    Button {
                        dismiss()
                        // Show registration if not already registered
                        if !UserRegistrationService.shared.isRegistered {
                            if let appDelegate = NSApp.delegate as? AppDelegate {
                                appDelegate.showRegistration()
                            }
                        }
                    } label: {
                        Text("Get Started")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Text("Please grant all permissions to continue")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        permissionManager.checkAllPermissions()
                    } label: {
                        Text("Check Permissions")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
        .padding(32)
        .frame(width: 450, height: 550)
        .onAppear {
            permissionManager.checkAllPermissions()
        }
    }
}

// MARK: - Permission Row

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isGranted ? .green : .blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            } else {
                Button("Grant") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PermissionsView()
        .environmentObject(PermissionManager.shared)
}
