import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let text: String
    let createdAt: Date

    init(id: UUID = UUID(), role: MessageRole, text: String, createdAt: Date = .now) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

struct OpenAIResponse: Decodable {
    let output: [OutputItem]?
}

struct OutputItem: Decodable {
    let type: String?
    let content: [OutputContent]?
}

struct OutputContent: Decodable {
    let type: String?
    let text: String?
}

struct ImageGenerationResponse: Decodable {
    let data: [GeneratedImage]?
}

struct GeneratedImage: Decodable {
    let b64_json: String?
    let url: String?
}
