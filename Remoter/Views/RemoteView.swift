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

    private var client: RokuClient { RokuClient(ipAddress: device.ipAddress) }

    var body: some View {
        ZStack {
            remoteBackdrop
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    optionsButton
                    directionalPad
                    playbackControls
                    if device.supportsVolume { volumeControls }
                    utilityControls
                    if let errorMessage { errorBanner(errorMessage) }
                    Text("Connected over your local Wi-Fi")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.35))
                        .padding(.top, 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 30)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
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
    }

    private var remoteBackdrop: some View {
        ZStack {
            Color(red: 0.025, green: 0.035, blue: 0.075)
            RadialGradient(colors: [Color(red: 0.29, green: 0.20, blue: 0.78).opacity(0.42), .clear],
                           center: .topTrailing, startRadius: 10, endRadius: 360)
            RadialGradient(colors: [Color(red: 0.10, green: 0.43, blue: 0.72).opacity(0.24), .clear],
                           center: .bottomLeading, startRadius: 5, endRadius: 330)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.08))
                Image(systemName: "tv").font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(red: 0.70, green: 0.65, blue: 1))
            }
            .frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 4) {
                Text(device.displayName).font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text(device.ipAddress).font(.caption.monospaced()).foregroundStyle(.white.opacity(0.55))
                }
            }
            Spacer()
            Menu {
                Button { refreshDevice() } label: { Label("Reconnect / refresh", systemImage: "arrow.clockwise") }
                Button { loadApps() } label: { Label("Apps on Roku", systemImage: "square.grid.2x2") }
                Button {
                    renameText = device.customName.isEmpty ? device.displayName : device.customName
                    showingRename = true
                } label: { Label("Rename device", systemImage: "pencil") }
                Button(role: .destructive) { store.remove(device) } label: {
                    Label("Remove device", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.09), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.08), lineWidth: 1))
            }
            .accessibilityLabel("Device options")
        }
    }

    private var optionsButton: some View {
        Button { send(.info) } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(.white.opacity(0.15)).frame(width: 48, height: 48)
                    Image(systemName: "star.fill").font(.system(size: 21, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("PICTURE & TV OPTIONS")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(1.1)
                    Text("Open your Roku TV picture menu")
                        .font(.caption).foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.headline.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                LinearGradient(colors: [Color(red: 0.40, green: 0.28, blue: 0.91), Color(red: 0.22, green: 0.42, blue: 0.82)],
                               startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: .purple.opacity(0.25), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Sends the Roku star or options command. On a Roku TV, choose Picture settings, then Picture mode.")
    }

    private var directionalPad: some View {
        VStack(spacing: 8) {
            Text("DIRECTIONAL CONTROL")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(.white.opacity(0.38))
                .padding(.bottom, 5)
            remoteKey(.up, icon: "chevron.up")
            HStack(spacing: 8) {
                remoteKey(.left, icon: "chevron.left")
                Button { send(.select) } label: {
                    ZStack {
                        Circle().fill(LinearGradient(colors: [Color.white, Color(red: 0.78, green: 0.79, blue: 0.91)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("OK").font(.system(size: 21, weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 0.10, green: 0.12, blue: 0.22))
                    }
                    .frame(width: 94, height: 94)
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select")
                remoteKey(.right, icon: "chevron.right")
            }
            remoteKey(.down, icon: "chevron.down")
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 34).stroke(.white.opacity(0.10), lineWidth: 1))
    }

    private func remoteKey(_ key: RokuKey, icon: String) -> some View {
        Button { send(key) } label: {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 68, height: 55)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 19).stroke(.white.opacity(0.07), lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: 19))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(key.rawValue)
    }

    private var playbackControls: some View {
        HStack(spacing: 10) {
            compactKey("Back", icon: "arrow.uturn.backward", key: .back)
            compactKey("Replay", icon: "gobackward.10", key: .instantReplay)
            compactKey("Play", icon: "playpause.fill", key: .play, prominent: true)
            compactKey("Rewind", icon: "backward.end.fill", key: .rewind)
            compactKey("Forward", icon: "forward.end.fill", key: .fastForward)
        }
    }

    private func compactKey(_ title: String, icon: String, key: RokuKey, prominent: Bool = false) -> some View {
        Button { send(key) } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(title).font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(prominent ? 1 : 0.82))
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(prominent ? Color.white.opacity(0.17) : Color.white.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.07), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var volumeControls: some View {
        HStack(spacing: 12) {
            Button { send(.volumeDown) } label: {
                Image(systemName: "speaker.fill").font(.title3)
                    .frame(width: 54, height: 52)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            }
            Button { send(.mute) } label: {
                Label("Mute", systemImage: "speaker.slash.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            }
            Button { send(.volumeUp) } label: {
                Image(systemName: "speaker.wave.3.fill").font(.title3)
                    .frame(width: 54, height: 52)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .foregroundStyle(.white)
    }

    private var utilityControls: some View {
        HStack(spacing: 12) {
            utilityTile("Home", detail: "Main screen", icon: "house.fill", tint: .indigo) { send(.home) }
            utilityTile("Keyboard", detail: "Type on TV", icon: "keyboard", tint: .cyan) { showingKeyboard = true }
            utilityTile("Apps", detail: "Launch channels", icon: "square.grid.2x2.fill", tint: .purple) { loadApps() }
        }
    }

    private func utilityTile(_ title: String, detail: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: icon).font(.title3.weight(.semibold)).foregroundStyle(tint)
                Text(title).font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(.white)
                Text(detail).font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.07), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message).font(.footnote)
            Spacer(minLength: 0)
            Button { errorMessage = nil } label: {
                Image(systemName: "xmark").font(.caption.bold())
            }
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
                    ContentUnavailableView("No apps loaded", systemImage: "square.grid.2x2",
                                           description: Text("Try again while your Roku is awake."))
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
