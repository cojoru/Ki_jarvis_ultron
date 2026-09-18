import Foundation
import UIKit

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Guten Tag. Ich bin JARVIS. Wie kann ich Ihnen helfen?")
    ]
    @Published var input = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var generatedImage: UIImage?

    let client = OpenAIClient()
    let speech = SpeechManager()
    let synthesizer = SpeechSynthesizer()
    private let router = CommandRouter()

    func send(settings: AppSettings, speakResponse: Bool = true) async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        input = ""

        if let localResponse = router.handle(text) {
            messages.append(ChatMessage(role: .user, text: text))
            messages.append(ChatMessage(role: .assistant, text: localResponse))
            if speakResponse { synthesizer.speak(localResponse) }
            return
        }

        messages.append(ChatMessage(role: .user, text: text))
        isLoading = true
        errorMessage = nil

        do {
            let response = try await client.respond(
                apiKey: settings.apiKey,
                model: settings.model,
                messages: messages
            )
            messages.append(ChatMessage(role: .assistant, text: response))
            if speakResponse { synthesizer.speak(response) }
        } catch {
            errorMessage = error.localizedDescription
            messages.append(ChatMessage(role: .assistant, text: "Entschuldigung. \(error.localizedDescription)"))
        }

        isLoading = false
    }

    func generateImage(settings: AppSettings, prompt: String) async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            generatedImage = try await client.generateImage(apiKey: settings.apiKey, prompt: prompt)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
