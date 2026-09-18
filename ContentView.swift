import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var vm: ChatViewModel

    var body: some View {
        TabView {
            ChatView()
                .tabItem { Label("JARVIS", systemImage: "sparkles") }

            ImageLabView()
                .tabItem { Label("Bilder", systemImage: "photo.artframe") }

            Model3DView()
                .tabItem { Label("3D", systemImage: "cube.transparent") }

            SettingsView()
                .tabItem { Label("Einstellungen", systemImage: "gearshape") }
        }
        .tint(.cyan)
        .task {
            await vm.speech.requestPermissions()
        }
    }
}

struct ChatView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var vm: ChatViewModel
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(vm.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            if vm.isLoading {
                                HStack {
                                    ProgressView()
                                    Text("JARVIS denkt nach…")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: vm.messages.count) { _, _ in
                        if let id = vm.messages.last?.id {
                            withAnimation { proxy.scrollTo(id, anchor: .bottom) }
                        }
                    }
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                HStack(spacing: 10) {
                    TextField("Nachricht an JARVIS…", text: $vm.input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .focused($focused)
                        .submitLabel(.send)

                    Button {
                        if vm.speech.isListening {
                            vm.speech.stop()
                            vm.input = vm.speech.transcript
                            focused = true
                        } else {
                            focused = false
                            vm.speech.start()
                        }
                    } label: {
                        Image(systemName: vm.speech.isListening ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 34))
                    }

                    Button {
                        Task { await vm.send(settings: settings) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                    }
                    .disabled(vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading)
                }
                .padding()
            }
            .navigationTitle("JARVIS")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundStyle(.cyan)
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .padding(12)
                .background(message.role == .user ? Color.blue.opacity(0.35) : Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}

struct ImageLabView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var vm: ChatViewModel
    @State private var prompt = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Text("Bild-Labor")
                        .font(.largeTitle.bold())

                    Text("Beschreibe ein Bild. JARVIS erzeugt es über die Bild-API.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    TextField("z. B. futuristische Stadt bei Nacht…", text: $prompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await vm.generateImage(settings: settings, prompt: prompt) }
                    } label: {
                        Label("Bild erzeugen", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isLoading || prompt.isEmpty)

                    if let image = vm.generatedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .contextMenu {
                                Button {
                                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                                } label: {
                                    Label("In Fotos speichern", systemImage: "square.and.arrow.down")
                                }
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Bilder")
        }
    }
}

struct Model3DView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 80))
                    .foregroundStyle(.cyan)
                Text("3D-Labor")
                    .font(.largeTitle.bold())
                Text("Version 1 enthält die 3D-Oberfläche als Grundlage. Der nächste Ausbau kann echte USDZ/RealityKit-Modelle aus KI-generierten Mesh-Daten laden.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
            }
            .navigationTitle("3D")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showKey = false

    var body: some View {
        NavigationStack {
            Form {
                Section("KI") {
                    HStack {
                        if showKey {
                            TextField("OpenAI API-Key", text: $settings.apiKey)
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("OpenAI API-Key", text: $settings.apiKey)
                        }
                        Button(showKey ? "Verbergen" : "Anzeigen") {
                            showKey.toggle()
                        }
                    }

                    TextField("Modell", text: $settings.model)
                        .textInputAutocapitalization(.never)

                    Text("Für einen echten App-Store-Release sollte der API-Key nicht direkt in der App gespeichert werden. Stattdessen sollte JARVIS über deinen eigenen sicheren Backend-Server mit der KI-API kommunizieren.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Version 1") {
                    Label("Text-Chat", systemImage: "message")
                    Label("Spracheingabe", systemImage: "mic")
                    Label("Sprachausgabe", systemImage: "speaker.wave.2")
                    Label("Bildgenerierung", systemImage: "photo")
                    Label("Basis-App-Steuerung", systemImage: "apps.iphone")
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}
