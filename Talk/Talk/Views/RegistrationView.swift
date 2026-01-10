import SwiftUI

struct RegistrationView: View {
    @StateObject private var registrationService = UserRegistrationService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var name: String = ""
    @State private var hasAgreedToUpdates: Bool = true

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Stay Updated")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Get notified about new features and updates")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Registration Form
            VStack(alignment: .leading, spacing: 20) {
                Text("Enter your email to receive updates:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 16) {
                    // Name field (optional)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name (optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Your name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Email field (required)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("your@email.com", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                    }

                    // Agreement checkbox
                    Toggle(isOn: $hasAgreedToUpdates) {
                        Text("I'd like to receive updates about new versions and features")
                            .font(.caption)
                    }
                    .toggleStyle(.checkbox)
                }

                // Error message
                if let error = registrationService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(.quaternary)
            .cornerRadius(12)

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                Button {
                    Task {
                        let success = await registrationService.register(
                            email: email,
                            name: name.isEmpty ? nil : name
                        )
                        if success {
                            dismiss()
                        }
                    }
                } label: {
                    if registrationService.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Register")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || registrationService.isLoading)

                Button {
                    registrationService.skipRegistration()
                    dismiss()
                } label: {
                    Text("Skip for now")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            // Privacy note
            Text("Your email is only used to send product updates. We never share your data.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(width: 450, height: 520)
    }
}

// MARK: - Preview

#Preview {
    RegistrationView()
}
