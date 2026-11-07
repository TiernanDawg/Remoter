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
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(device.displayName).font(.title2.bold())
                            Text(device.ipAddress).font(.caption).foregroundStyle(.secondary)
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
                            Image(systemName: "ellipsis.circle").font(.title2)
                        }
                    }

                    HStack(spacing: 12) {
                        actionButton("Home", icon: "house.fill", key: .home)
                        actionButton("Back", icon: "arrow.uturn.backward", key: .back)
                        actionButton("Replay", icon: "gobackward", key: .instantReplay)
                    }

                    directionalPad

                    HStack(spacing: 12) {
                        actionButton("Rewind", icon: "backward.end.fill", key: .rewind)
                        actionButton("Play / Pause", icon: "playpause.fill", key: .play)
                        actionButton("Forward", icon: "forward.end.fill", key: .fastForward)
                    }

                    if device.supportsVolume {
                        HStack(spacing: 12) {
                            actionButton("Vol −", icon: "speaker.wave.1", key: .volumeDown)
                            actionButton("Mute", icon: "speaker.slash.fill", key: .mute)
                            actionButton("Vol +", icon: "speaker.wave.3.fill", key: .volumeUp)
                        }
                    }

                    if device.supportsPower || device.supportsFindRemote {
                        HStack(spacing: 12) {
                            if device.supportsPower {
                                actionButton("Power", icon: "power", key: .power)
                            }
                            if device.supportsFindRemote {
                                actionButton("Find Remote", icon: "dot.radiowaves.left.and.right", key: .findRemote)
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        utilityButton("Keyboard", icon: "keyboard") { showingKeyboard = true }
                        utilityButton("Apps", icon: "square.grid.2x2") { loadApps() }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingKeyboard) { keyboardSheet }
        .sheet(isPresented: $showingApps) { appsSheet }
        .alert("Rename Roku", isPresented: $showingRename) {
            TextField("Device name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") { store.rename(device, to: renameText) }
        }
    }

    private var directionalPad: some View {
        VStack(spacing: 7) {
            remoteKey(.up, icon: "chevron.up")
            HStack(spacing: 7) {
                remoteKey(.left, icon: "chevron.left")
                Button { send(.select) } label: {
                    Text("OK")
                        .font(.title2.bold())
                        .frame(width: 92, height: 76)
                        .background(.purple, in: RoundedRectangle(cornerRadius: 24))
                }
                .buttonStyle(.plain)
                remoteKey(.right, icon: "chevron.right")
            }
            remoteKey(.down, icon: "chevron.down")
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 30))
    }

    private func remoteKey(_ key: RokuKey, icon: String) -> some View {
        Button { send(key) } label: {
            Image(systemName: icon)
                .font(.title2.bold())
                .frame(width: 76, height: 64)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 20))
                .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func actionButton(_ title: String, icon: String, key: RokuKey) -> some View {
        Button { send(key) } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func utilityButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(.purple.opacity(0.20), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
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
                if apps.isEmpty { errorMessage = "Roku returned no installed apps." }
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