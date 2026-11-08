import SwiftUI

struct RemoteView: View {
    @EnvironmentObject private var store: DeviceStore
    let device: RokuDevice

    @State private var errorMessage: String?
    @State private var showingKeyboard = false
    @State private var showingApps = false
    @State private var showingRename = false
    @State private var renameText = ""
    @State private var textToSend = ""
    @State private var apps: [RokuApp] = []
    @State private var isLoadingApps = false
    @State private var trackpadMoved = false

    private var client: RokuClient { RokuClient(ipAddress: device.ipAddress) }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 17) {
                        trackpad
                        primaryControls
                        mediaControls
                        quickActions
                        if device.supportsVolume { volumeControls }
                        if let errorMessage { errorBanner(errorMessage) }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingKeyboard) { keyboardSheet }
        .sheet(isPresented: $showingApps) { appsSheet }
        .alert("Rename Roku", isPresented: $showingRename) {
            TextField("Device name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") { store.rename(device, to: renameText) }
        }
        .preferredColorScheme(.dark)
    }

    private var background: some View {
        ZStack {
            Color(red: 0.025, green: 0.035, blue: 0.065)
            LinearGradient(colors: [Color(red: 0.10, green: 0.19, blue: 0.37).opacity(0.72), .clear,
                                    Color(red: 0.22, green: 0.15, blue: 0.38).opacity(0.38)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [Color.blue.opacity(0.16), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 420)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            HStack(spacing: 11) {
                Circle().fill(Color.green).frame(width: 9, height: 9)
                    .shadow(color: .green.opacity(0.65), radius: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connected").font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(device.displayName).font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))

            Spacer()

            Menu {
                Button { refreshDevice() } label: { Label("Reconnect", systemImage: "arrow.clockwise") }
                Button { loadApps() } label: { Label("Apps on Roku", systemImage: "square.grid.2x2") }
                Button {
                    renameText = device.customName.isEmpty ? device.displayName : device.customName
                    showingRename = true
                } label: { Label("Rename device", systemImage: "pencil") }
                if device.supportsFindRemote {
                    Button { send(.findRemote) } label: { Label("Find Roku remote", systemImage: "dot.radiowaves.left.and.right") }
                }
                Button(role: .destructive) { store.remove(device) } label: {
                    Label("Remove device", systemImage: "trash")
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
            }
            .accessibilityLabel("Settings")
        }
    }

    private var trackpad: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.12), .white.opacity(0.025)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.06)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)

                VStack(spacing: 0) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    HStack {
                        Image(systemName: "chevron.left")
                        Spacer()
                        Circle()
                            .fill(.white.opacity(0.09))
                            .frame(width: 82, height: 82)
                            .overlay(Circle().stroke(.white.opacity(0.20), lineWidth: 1))
                            .overlay(Image(systemName: "hand.tap").font(.system(size: 23, weight: .light))
                                .foregroundStyle(.white.opacity(0.68)))
                            .shadow(color: .black.opacity(0.18), radius: 12, y: 5)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.horizontal, 27)
                .padding(.vertical, 25)

                VStack {
                    Spacer()
                    Text("SWIPE TO NAVIGATE  ·  TAP TO SELECT")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.38))
                        .padding(.bottom, 13)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        guard !trackpadMoved else { return }
                        let dx = value.translation.width
                        let dy = value.translation.height
                        guard max(abs(dx), abs(dy)) > 28 else { return }
                        trackpadMoved = true
                        if abs(dx) > abs(dy) {
                            send(dx > 0 ? .right : .left)
                        } else {
                            send(dy > 0 ? .down : .up)
                        }
                    }
                    .onEnded { value in
                        if !trackpadMoved { send(.select) }
                        trackpadMoved = false
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("Roku trackpad")
            .accessibilityHint("Swipe up, down, left or right to navigate. Tap to select.")
        }
        .frame(height: min(UIScreen.main.bounds.height * 0.37, 330))
        .frame(minHeight: 245)
    }

    private var primaryControls: some View {
        HStack(spacing: 10) {
            primaryButton("Back", icon: "arrow.uturn.backward") { send(.back) }
            primaryButton("Home", icon: "house.fill") { send(.home) }
            primaryButton("Menu", icon: "line.3.horizontal") { send(.info) }
        }
    }

    private func primaryButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 19, weight: .semibold))
                Text(title).font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.91))
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 23).stroke(.white.opacity(0.11), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var mediaControls: some View {
        HStack(spacing: 0) {
            mediaButton("backward.end.fill", label: "Rewind", key: .rewind)
            Rectangle().fill(.white.opacity(0.10)).frame(width: 1, height: 32)
            mediaButton("playpause.fill", label: "Play / Pause", key: .play)
            Rectangle().fill(.white.opacity(0.10)).frame(width: 1, height: 32)
            mediaButton("forward.end.fill", label: "Fast forward", key: .fastForward)
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.11), lineWidth: 1))
    }

    private func mediaButton(_ icon: String, label: String, key: RokuKey) -> some View {
        Button { send(key) } label: {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.90))
                .frame(maxWidth: .infinity, minHeight: 43)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            quickAction("Keyboard", icon: "keyboard") { showingKeyboard = true }
            quickAction("Apps", icon: "square.grid.2x2") { loadApps() }
        }
    }

    private func quickAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var volumeControls: some View {
        HStack(spacing: 18) {
            Button { send(.volumeDown) } label: { Image(systemName: "speaker.fill") }
            Button { send(.mute) } label: { Image(systemName: "speaker.slash.fill") }
            Button { send(.volumeUp) } label: { Image(systemName: "speaker.wave.3.fill") }
        }
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(.white.opacity(0.82))
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(.white.opacity(0.055), in: Capsule())
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message).font(.footnote)
            Spacer(minLength: 0)
            Button { errorMessage = nil } label: { Image(systemName: "xmark").font(.caption.bold()) }
        }
        .foregroundStyle(.red.opacity(0.95))
        .padding(13)
        .background(.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
    }

    private var keyboardSheet: some View {
        NavigationStack {
            Form {
                Section("Send text to Roku") {
                    TextField("Search or enter text on your TV", text: $textToSend, axis: .vertical)
                        .lineLimit(2...4)
                    Button("Send text") {
                        let value = textToSend
                        Task {
                            do {
                                try await client.type(value)
                                textToSend = ""
                                showingKeyboard = false
                            } catch { errorMessage = error.localizedDescription }
                        }
                    }
                    .disabled(textToSend.isEmpty)
                }
                Section {
                    Text("The Roku must already be showing an on-screen keyboard. Text is sent one character at a time.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Roku Keyboard")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showingKeyboard = false } } }
        }
    }

    private var appsSheet: some View {
        NavigationStack {
            Group {
                if isLoadingApps {
                    ProgressView("Loading apps…")
                } else if apps.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "square.grid.2x2").font(.largeTitle).foregroundStyle(.secondary)
                        Text("No apps loaded").font(.headline)
                        Text("Try again while your Roku is awake.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding()
                } else {
                    List(apps) { app in
                        Button {
                            Task {
                                do {
                                    try await client.launch(app)
                                    showingApps = false
                                } catch { errorMessage = error.localizedDescription }
                            }
                        } label: { Text(app.name) }
                    }
                }
            }
            .navigationTitle("Apps on Roku")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showingApps = false } } }
        }
    }

    private func send(_ key: RokuKey) {
        Task {
            do {
                try await client.press(key)
                errorMessage = nil
            } catch { errorMessage = error.localizedDescription }
        }
    }

    private func loadApps() {
        showingApps = true
        isLoadingApps = true
        Task {
            do {
                apps = try await client.apps()
                if apps.isEmpty { errorMessage = "Roku returned no installed apps." }
            } catch { errorMessage = error.localizedDescription }
            isLoadingApps = false
        }
    }

    private func refreshDevice() {
        Task {
            do {
                let refreshed = try await client.verify()
                store.add(refreshed)
                errorMessage = nil
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
