import Foundation
import SwiftUI
import Combine

/// Manages Ollama lifecycle: installation detection, auto-launch, and model management
@MainActor
class OllamaManager: ObservableObject {
    static let shared = OllamaManager()

    // MARK: - State

    @Published var isInstalled = false
    @Published var isRunning = false
    @Published var installedModels: [OllamaModelInfo] = []
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var downloadingModel: String?
    @Published var lastError: String?

    // Popular models for text enhancement
    static let recommendedModels: [RecommendedModel] = [
        RecommendedModel(name: "qwen2.5:3b", size: "1.9 GB", description: "Excellent for text tasks, fast"),
        RecommendedModel(name: "phi3", size: "2.2 GB", description: "Microsoft, very fast"),
        RecommendedModel(name: "gemma2:2b", size: "1.6 GB", description: "Google, lightweight"),
        RecommendedModel(name: "mistral", size: "4.1 GB", description: "High quality, balanced"),
        RecommendedModel(name: "llama3.2", size: "2.0 GB", description: "Meta, good all-around")
    ]

    private var ollamaProcess: Process?
    private let ollamaPaths = [
        "/opt/homebrew/bin/ollama",
        "/usr/local/bin/ollama",
        "/usr/bin/ollama"
    ]

    private init() {
        Task {
            await checkInstallation()
            await checkStatus()
        }
    }

    // MARK: - Installation Check

    func checkInstallation() async {
        isInstalled = findOllamaPath() != nil
    }

    private func findOllamaPath() -> String? {
        for path in ollamaPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        // Try which command as fallback
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ollama"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let path = path, !path.isEmpty, FileManager.default.fileExists(atPath: path) {
                return path
            }
        } catch {
            // Ignore
        }
        return nil
    }

    // MARK: - Status Check

    func checkStatus() async {
        guard let url = URL(string: "http://localhost:11434") else {
            isRunning = false
            return
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                isRunning = httpResponse.statusCode == 200
            } else {
                isRunning = false
            }

            if isRunning {
                await refreshInstalledModels()
            }
        } catch {
            isRunning = false
        }
    }

    // MARK: - Auto-Launch

    func startOllama() async -> Bool {
        guard let ollamaPath = findOllamaPath() else {
            lastError = "Ollama not found. Please install it first."
            return false
        }

        // Check if already running
        await checkStatus()
        if isRunning {
            return true
        }

        // Start ollama serve in background
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ollamaPath)
        process.arguments = ["serve"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            ollamaProcess = process

            // Wait for it to start (up to 10 seconds)
            for _ in 0..<20 {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                await checkStatus()
                if isRunning {
                    return true
                }
            }

            lastError = "Ollama started but not responding"
            return false
        } catch {
            lastError = "Failed to start Ollama: \(error.localizedDescription)"
            return false
        }
    }

    func ensureRunning() async -> Bool {
        await checkStatus()
        if isRunning {
            return true
        }
        return await startOllama()
    }

    // MARK: - Model Management

    func refreshInstalledModels() async {
        guard let url = URL(string: "http://localhost:11434/api/tags") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
            installedModels = response.models.map { model in
                OllamaModelInfo(
                    name: model.name,
                    size: formatBytes(model.size ?? 0),
                    modifiedAt: model.modifiedAt ?? ""
                )
            }
        } catch {
            installedModels = []
        }
    }

    func pullModel(_ modelName: String) async -> Bool {
        guard let url = URL(string: "http://localhost:11434/api/pull") else {
            lastError = "Invalid URL"
            return false
        }

        isDownloading = true
        downloadingModel = modelName
        downloadProgress = 0
        lastError = nil

        defer {
            isDownloading = false
            downloadingModel = nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 3600 // 1 hour for large models

        let body = ["name": modelName, "stream": true] as [String: Any]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (bytes, _) = try await URLSession.shared.bytes(for: request)

            for try await line in bytes.lines {
                if let data = line.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                    // Check for error
                    if let error = json["error"] as? String {
                        lastError = error
                        return false
                    }

                    // Update progress
                    if let total = json["total"] as? Int64,
                       let completed = json["completed"] as? Int64,
                       total > 0 {
                        downloadProgress = Double(completed) / Double(total)
                    }

                    // Check if done
                    if let status = json["status"] as? String, status == "success" {
                        await refreshInstalledModels()
                        return true
                    }
                }
            }

            await refreshInstalledModels()
            return true
        } catch {
            lastError = "Download failed: \(error.localizedDescription)"
            return false
        }
    }

    func deleteModel(_ modelName: String) async -> Bool {
        guard let url = URL(string: "http://localhost:11434/api/delete") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["name": modelName])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                await refreshInstalledModels()
                return true
            }
        } catch {
            // Ignore
        }
        return false
    }

    func isModelInstalled(_ modelName: String) -> Bool {
        installedModels.contains { $0.name == modelName || $0.name.hasPrefix(modelName + ":") }
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Int) -> String {
        let gb = Double(bytes) / 1_000_000_000
        if gb >= 1 {
            return String(format: "%.1f GB", gb)
        }
        let mb = Double(bytes) / 1_000_000
        return String(format: "%.0f MB", mb)
    }
}

// MARK: - Models

struct OllamaModelInfo: Identifiable {
    let id = UUID()
    let name: String
    let size: String
    let modifiedAt: String
}

struct RecommendedModel: Identifiable {
    let id = UUID()
    let name: String
    let size: String
    let description: String
}
