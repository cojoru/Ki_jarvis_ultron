import Foundation
import UIKit

enum APIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case server(String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Bitte hinterlege zuerst deinen OpenAI API-Key in den Einstellungen."
        case .invalidResponse:
            return "Die API hat keine gültige Antwort geliefert."
        case .server(let message):
            return message
        case .decoding(let message):
            return "Antwort konnte nicht gelesen werden: \(message)"
        }
    }
}

final class OpenAIClient {
    private let session: URLSession
    private let baseURL = URL(string: "https://api.openai.com/v1")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func respond(apiKey: String, model: String, messages: [ChatMessage]) async throws -> String {
        guard !apiKey.isEmpty else { throw APIError.missingAPIKey }

        let url = baseURL.appendingPathComponent("responses")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let conversation = messages.map {
            [
                "role": $0.role == .user ? "user" : "assistant",
                "content": $0.text
            ]
        }

        let body: [String: Any] = [
            "model": model,
            "instructions": "Du bist JARVIS, ein hilfreicher, höflicher und präziser Assistent. Antworte standardmäßig auf Deutsch. Halte Antworten für Sprache kompakt, aber vollständig.",
            "input": conversation
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        do {
            let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            let text = decoded.output?
                .flatMap { $0.content ?? [] }
                .compactMap { $0.text }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let text, !text.isEmpty { return text }
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }

        throw APIError.invalidResponse
    }

    func generateImage(apiKey: String, prompt: String) async throws -> UIImage {
        guard !apiKey.isEmpty else { throw APIError.missingAPIKey }

        let url = baseURL.appendingPathComponent("images/generations")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-image-2",
            "prompt": prompt,
            "size": "1024x1024"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(ImageGenerationResponse.self, from: data)
        if let base64 = decoded.data?.first?.b64_json,
           let imageData = Data(base64Encoded: base64),
           let image = UIImage(data: imageData) {
            return image
        }

        if let urlString = decoded.data?.first?.url, let imageURL = URL(string: urlString) {
            let (imageData, _) = try await session.data(from: imageURL)
            if let image = UIImage(data: imageData) { return image }
        }

        throw APIError.invalidResponse
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw APIError.server(message)
            }
            let fallback = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw APIError.server(fallback)
        }
    }
}
