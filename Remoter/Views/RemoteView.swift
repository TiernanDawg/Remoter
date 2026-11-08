import SwiftUI

struct RemoteView: View {
    @EnvironmentObject private var store: DeviceStore
    @AppStorage("remoter.remoteTheme") private var selectedTheme = RemoteTheme.glass.rawValue

    let device: RokuDevice

    @State private var errorMessage: String?
    @State private var showingKeyboard = false
    @State private var showingApps = false
    @State private var showingThemes = false
    @State private var showingRename = false
    @State private var renameText = ""
    @State private var textToSend = ""
    @State private var apps: [RokuApp] = []
    @State private var isLoadingApps = false
    @State private var trackpadCommandSent = false

    private var theme: RemoteTheme {
        RemoteTheme(rawValue: selectedTheme) ?? .glass
    }

    private var client: RokuClient {
        RokuClient(ipAddress: device.ipAddress)
    }

    var body: some View {
        ZStack {
            screenBackground
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 17)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        trackpad
                        primaryControls
                        mediaControls
                        quickActions
                        if device.supportsVolume {
                            volumeControls
                        }
                        if device.supportsPower || device.supportsFindRemote {
                            deviceControls
                        }
                        if let errorMessage {
                            errorBanner(errorMessage)
                        }
                    }
                    .padding(.horizontal, 19)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 540)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingKeyboard) { keyboardSheet }
        .sheet(isPresented: $showingApps) { appsSheet }
        .sheet(isPresented: $showingThemes) {
            ThemePickerView(selection: $selectedTheme)
        }
        .alert("Rename Roku", isPresented: $showingRename) {
            TextField("Device name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") { store.rename(device, to: renameText) }
        }
        .preferredColorScheme(theme.isLight ? .light : .dark)
        .animation(.easeInOut(duration: 0.22), value: selectedTheme)
    }

    private var screenBackground: some View {
        ZStack {
            LinearGradient(colors: [theme.backgroundTop, theme.backgroundBottom],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            if theme == .glass {
                RadialGradient(colors: [theme.accentSecondary.opacity(0.24), .clear],
                               center: .topTrailing, startRadius: 0, endRadius: 420)
            } else if theme == .arcade {
                RadialGradient(colors: [theme.accentSecondary.opacity(0.15), .clear],
                               center: .bottomTrailing, startRadius: 0, endRadius: 340)
            }
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 9, height: 9)
                    .shadow(color: .green.opacity(0.65), radius: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connected")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(theme.foreground)
                    Text(device.displayName)
                        .font(.caption)
                        .foregroundStyle(theme.muted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(theme.panel, in: Capsule())
            .overlay(Capsule().stroke(theme.border, lineWidth: 1))

            Spacer()

            Menu {
                Button { showingThemes = true } label: {
                    Label("Appearance & themes", systemImage: "paintpalette")
                }
                Button { refreshDevice() } label: {
                    Label("Reconnect", systemImage: "arrow.clockwise")
                }
                Button { loadApps() } label: {
                    Label("Apps on Roku", systemImage: "square.grid.2x2")
                }
                Button {
                    renameText = device.customName.isEmpty ? device.displayName : device.customName
                    showingRename = true
                } label: {
                    Label("Rename device", systemImage: "pencil")
                }
                if device.supportsFindRemote {
                    Button { send(.findRemote) } label: {
                        Label("Find Roku remote", systemImage: "dot.radiowaves.left.and.right")
                    }
                }
                Button(role: .destructive) { store.remove(device) } label: {
                    Label("Remove device", systemImage: "trash")
                }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(theme.foreground)
                    .frame(width: 46, height: 46)
                    .background(theme.panel, in: Circle())
                    .overlay(Circle().stroke(theme.border, lineWidth: 1))
            }
            .accessibilityLabel("Settings and appearance")
        }
    }

    private var trackpad: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(theme.panel)
                .overlay {
                    if theme.usesGlass {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.56)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [theme.border.opacity(1.8), theme.border.opacity(0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .gesture(trackpadGesture)

            VStack(spacing: 0) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(theme.muted.opacity(0.9))
                Spacer(minLength: 16)
                HStack {
                    Image(systemName: "chevron.left")
                    Spacer(minLength: 24)
                    okButton
                    Spacer(minLength: 24)
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(theme.muted.opacity(0.9))
                Spacer(minLength: 16)
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(theme.muted.opacity(0.9))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 25)

            VStack {
                HStack {
                    Text("TOUCH SURFACE")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(theme.muted.opacity(0.72))
                    Spacer()
                    Image(systemName: "hand.draw")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.muted.opacity(0.65))
                }
                Spacer()
                Text("SWIPE TO NAVIGATE")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(theme.muted.opacity(0.65))
            }
            .padding(19)
            .allowsHitTesting(false)
        }
        .frame(height: 286)
        .accessibilityHint("Swipe in any direction to navigate. Press the centered OK button to select.")
    }

    private var okButton: some View {
        Button {
            send(.select)
        } label: {
            ZStack {
                Circle()
                    .fill(theme.centerFill)
                Circle()
                    .stroke(theme.border.opacity(1.25), lineWidth: 1)
                Text("OK")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.foreground)
            }
            .frame(width: 82, height: 82)
            .shadow(color: theme.accent.opacity(theme == .arcade ? 0.24 : 0.10), radius: 12, y: 5)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("OK — Select")
        .accessibilityHint("Sends the Select command to your Roku.")
    }

    private var trackpadGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard !trackpadCommandSent else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                guard max(abs(dx), abs(dy)) >= 30 else { return }

                trackpadCommandSent = true
                if abs(dx) > abs(dy) {
                    send(dx > 0 ? .right : .left)
                } else {
                    send(dy > 0 ? .down : .up)
                }
            }
            .onEnded { _ in
                trackpadCommandSent = false
            }
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
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(title).font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundStyle(theme.foreground)
            .frame(maxWidth: .infinity, minHeight: 68)
            .background(theme.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var mediaControls: some View {
        HStack(spacing: 0) {
            mediaButton("backward.end.fill", label: "Rewind", key: .rewind)
            Rectangle().fill(theme.border).frame(width: 1, height: 29)
            mediaButton("playpause.fill", label: "Play / Pause", key: .play)
            Rectangle().fill(theme.border).frame(width: 1, height: 29)
            mediaButton("forward.end.fill", label: "Fast forward", key: .fastForward)
        }
        .padding(.vertical, 7)
        .background(theme.panel, in: Capsule())
        .overlay(Capsule().stroke(theme.border, lineWidth: 1))
    }

    private func mediaButton(_ icon: String, label: String, key: RokuKey) -> some View {
        Button { send(key) } label: {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .frame(maxWidth: .infinity, minHeight: 42)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            quickAction("Keyboard", icon: "keyboard") { showingKeyboard = true }
            quickAction("Apps", icon: "square.grid.2x2") { loadApps() }
        }
    }

    private func quickAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.foreground)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(theme.panel, in: Capsule())
                .overlay(Capsule().stroke(theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var volumeControls: some View {
        HStack(spacing: 0) {
            volumeButton("speaker.fill", label: "Volume down", key: .volumeDown)
            volumeButton("speaker.slash.fill", label: "Mute", key: .mute)
            volumeButton("speaker.wave.3.fill", label: "Volume up", key: .volumeUp)
        }
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(theme.foreground)
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(theme.panel, in: Capsule())
        .overlay(Capsule().stroke(theme.border, lineWidth: 1))
    }

    private func volumeButton(_ icon: String, label: String, key: RokuKey) -> some View {
        Button { send(key) } label: {
            Image(systemName: icon)
                .frame(maxWidth: .infinity, minHeight: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var deviceControls: some View {
        HStack(spacing: 10) {
            if device.supportsPower {
                primaryButton("Power", icon: "power") { send(.power) }
            }
            if device.supportsFindRemote {
                primaryButton("Find remote", icon: "dot.radiowaves.left.and.right") { send(.findRemote) }
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message).font(.footnote)
            Spacer(minLength: 0)
            Button { errorMessage = nil } label: {
                Image(systemName: "xmark").font(.caption.bold())
            }
            .accessibilityLabel("Dismiss error")
        }
        .foregroundStyle(.red)
        .padding(13)
        .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
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
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .disabled(textToSend.isEmpty)
                }
                Section {
                    Text("The Roku must already be showing an on-screen keyboard. Text is sent one character at a time.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Roku Keyboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingKeyboard = false }
                }
            }
        }
        .preferredColorScheme(theme.isLight ? .light : .dark)
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
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        } label: {
                            Text(app.name)
                        }
                    }
                }
            }
            .navigationTitle("Apps on Roku")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingApps = false }
                }
            }
        }
        .preferredColorScheme(theme.isLight ? .light : .dark)
    }

    private func send(_ key: RokuKey) {
        Task {
            do {
                try await client.press(key)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadApps() {
        showingApps = true
        isLoadingApps = true
        Task {
            do {
                apps = try await client.apps()
                if apps.isEmpty {
                    errorMessage = "Roku returned no installed apps."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoadingApps = false
        }
    }

    private func refreshDevice() {
        Task {
            do {
                let refreshed = try await client.verify()
                store.add(refreshed)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
