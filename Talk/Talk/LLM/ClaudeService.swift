import Foundation
import SwiftUI
import Combine

@MainActor
class ClaudeService: ObservableObject, LLMProviderProtocol {
    static let shared = ClaudeService()

    // Settings
    @AppStorage("claudeAPIKey") private var apiKeyStorage: String = ""
    @AppStorage("claudeModel") var selectedModel: String = "claude-sonnet-4-20250514"

    var name: String { "Claude" }

    var isConfigured: Bool {
        !apiKeyStorage.isEmpty
    }

    var apiKey: String {
        get { apiKeyStorage }
        set { apiKeyStorage = newValue }
    }

    // Available models
    let availableModels = [
        "claude-sonnet-4-20250514",
        "claude-opus-4-20250514",
        "claude-haiku-3-5-latest"
    ]

    private init() {}

    // MARK: - Generation

    func generate(text: String, systemPrompt: String) async throws -> String {
        guard isConfigured else {
            throw LLMError.notConfigured
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw LLMError.connectionFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": selectedModel,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": text]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                throw LLMError.requestFailed(errorResponse.error.message)
            }
            throw LLMError.requestFailed("HTTP \(httpResponse.statusCode)")
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let content = claudeResponse.content.first,
              case .text(let text) = content else {
            throw LLMError.noContent
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Response Types

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
    }
}

enum ClaudeContent: Codable {
    case text(String)
    case other([String: String])

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        if type == "text" {
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        } else {
            self = .other(["type": type])
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .other(let dict):
            for (key, value) in dict {
                try container.encode(value, forKey: CodingKeys(stringValue: key)!)
            }
        }
    }

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case type, text

        init?(stringValue: String) {
            switch stringValue {
            case "type": self = .type
            case "text": self = .text
            default: return nil
            }
        }
    }
}

struct ClaudeErrorResponse: Codable {
    let type: String
    let error: ClaudeError
}

struct ClaudeError: Codable {
    let type: String
    let message: String
}
