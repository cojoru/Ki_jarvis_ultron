import Foundation

@MainActor
final class AppSettings: ObservableObject {
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "openai_api_key") }
    }

    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: "openai_model") }
    }

    init() {
        self.apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        self.model = UserDefaults.standard.string(forKey: "openai_model") ?? "gpt-5.6-luna"
    }
}
