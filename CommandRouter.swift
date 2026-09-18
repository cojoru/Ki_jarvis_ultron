import Foundation
import UIKit

@MainActor
final class CommandRouter {
    func handle(_ text: String) -> String? {
        let command = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if command.contains("öffne safari") || command == "safari öffnen" {
            open("https://www.apple.com/safari/")
            return "Ich öffne Safari."
        }

        if command.contains("öffne musik") || command.contains("öffne apple music") {
            open("music://")
            return "Ich öffne Musik."
        }

        if command.contains("öffne youtube") {
            open("youtube://")
            return "Ich öffne YouTube, falls die App installiert ist."
        }

        if command.contains("öffne spotify") {
            open("spotify://")
            return "Ich öffne Spotify, falls die App installiert ist."
        }

        if command.contains("öffne einstellungen") {
            open("App-Prefs:root=")
            return "Ich öffne die Einstellungen."
        }

        if command.contains("kamera öffnen") || command.contains("öffne kamera") {
            open("camera://")
            return "Die Kamera kann von Drittanbieter-Apps nicht direkt über eine private URL garantiert geöffnet werden. Nutze dafür am zuverlässigsten einen Kurzbefehl."
        }

        return nil
    }

    private func open(_ rawURL: String) {
        guard let url = URL(string: rawURL) else { return }
        UIApplication.shared.open(url)
    }
}
