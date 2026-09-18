import SwiftUI

@main
struct JARVISApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var viewModel = ChatViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
