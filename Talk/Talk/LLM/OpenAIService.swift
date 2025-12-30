import Foundation
import SwiftUI
import Combine

@MainActor
class OpenAIService: ObservableObject, LLMProviderProtocol {
    static let shared = OpenAIService()

    // Settings
    @AppStorage("openaiAPIKey") private var apiKeyStorage: String = ""
    @AppStorage("openaiModel") var selectedModel: String = "gpt-4o-mini"

    var name: String { "OpenAI" }

    var isConfigured: Bool {
        !apiKeyStorage.isEmpty
    }

    var apiKey: String {
        get { apiKeyStorage }
        set { apiKeyStorage = newValue }
    }

    // Available models
    let availableModels = [
        "gpt-4o-mini",
        "gpt-4o",
        "gpt-4-turbo"
    ]

    private init() {}

    // MARK: - Generation

    func generate(text: String, systemPrompt: String) async throws -> String {
        guard isConfigured else {
            throw LLMError.notConfigured
        }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw LLMError.connectionFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": selectedModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3,
            "max_tokens": 4096
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw LLMError.requestFailed(errorResponse.error.message)
            }
            throw LLMError.requestFailed("HTTP \(httpResponse.statusCode)")
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let choice = openAIResponse.choices.first,
              let content = choice.message.content else {
            throw LLMError.noContent
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Response Types

struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
}

struct OpenAIChoice: Codable {
    let index: Int
    let message: OpenAIMessage
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String?
}

struct OpenAIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct OpenAIErrorResponse: Codable {
    let error: OpenAIError
}

struct OpenAIError: Codable {
    let message: String
    let type: String?
    let code: String?
}
