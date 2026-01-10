import SwiftUI
import Combine

@MainActor
class UserRegistrationService: ObservableObject {
    static let shared = UserRegistrationService()

    // MARK: - Supabase Configuration
    private let supabaseURL = "https://uteakobjdkvttmwalkzp.supabase.co"
    private let supabaseAnonKey = "sb_publishable_I2qLXZVGjvxPNtegiaQ2LA_2BkcXNic"

    // MARK: - Published State
    @Published var isRegistered: Bool = false
    @Published var userEmail: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Store registration status locally
    @AppStorage("userRegistered") private var userRegisteredStorage: Bool = false
    @AppStorage("userEmail") private var userEmailStorage: String = ""

    private init() {
        isRegistered = userRegisteredStorage
        userEmail = userEmailStorage
    }

    // MARK: - Registration

    func register(email: String, name: String? = nil) async -> Bool {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return false
        }

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/users")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

            let body: [String: Any] = [
                "email": email,
                "name": name ?? "",
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw RegistrationError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200, 201:
                // Success
                userRegisteredStorage = true
                userEmailStorage = email
                isRegistered = true
                userEmail = email
                isLoading = false
                return true

            case 409:
                // Email already exists - that's fine, consider it registered
                userRegisteredStorage = true
                userEmailStorage = email
                isRegistered = true
                userEmail = email
                isLoading = false
                return true

            default:
                throw RegistrationError.serverError(httpResponse.statusCode)
            }

        } catch {
            isLoading = false
            errorMessage = "Registration failed: \(error.localizedDescription)"
            return false
        }
    }

    func skipRegistration() {
        // Allow users to skip, but we'll ask again later
        userRegisteredStorage = false
    }

    // MARK: - Validation

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    // MARK: - Errors

    enum RegistrationError: LocalizedError {
        case invalidResponse
        case serverError(Int)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid server response"
            case .serverError(let code):
                return "Server error: \(code)"
            }
        }
    }
}
