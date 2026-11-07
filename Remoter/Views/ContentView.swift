import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: DeviceStore
    @State private var showingScanner = false
    @State private var showingManualEntry = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if store.devices.isEmpty {
                    emptyState
                } else {
                    deviceList
                }
            }
            .navigationTitle("Remoter")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showingScanner = true } label: { Label("Find Roku devices", systemImage: "wifi") }
                        Button { showingManualEntry = true } label: { Label("Enter IP address", systemImage: "keyboard") }
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(.purple)
                    }
                }
            }
            .sheet(isPresented: $showingScanner) { DeviceScannerView() }
            .sheet(isPresented: $showingManualEntry) { ManualConnectionView() }
            .navigationDestination(for: RokuDevice.self) { device in
                RemoteView(device: device)
            }
        }
        .tint(.purple)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "appletvremote.gen2")
                .font(.system(size: 66))
                .foregroundStyle(.purple)
            Text("No Roku devices yet").font(.title2.bold())
            Text("Connect your iPhone to the same Wi-Fi network as your Roku, then scan or enter its IP address.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Button { showingScanner = true } label: {
                Label("Find Roku devices", systemImage: "wifi")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            Button("Enter IP address manually") { showingManualEntry = true }
                .font(.subheadline)
        }
        .padding()
    }

    private var deviceList: some View {
        List {
            Section("MY DEVICES") {
                ForEach(store.devices) { device in
                    NavigationLink(value: device) {
                        HStack(spacing: 14) {
                            Image(systemName: "tv")
                                .font(.title2)
                                .foregroundStyle(.purple)
                                .frame(width: 42, height: 42)
                                .background(.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.displayName).font(.headline)
                                Text("\(device.modelName.isEmpty ? "Roku" : device.modelName) · \(device.ipAddress)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if store.selectedDeviceID == device.id {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.purple)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .simultaneousGesture(TapGesture().onEnded { store.select(device) })
                    .contextMenu {
                        Button(role: .destructive) { store.remove(device) } label: {
                            Label("Remove device", systemImage: "trash")
                        }
                    }
                }
            }
            Section("ADD ANOTHER") {
                Button { showingScanner = true } label: { Label("Scan network", systemImage: "dot.radiowaves.left.and.right") }
                Button { showingManualEntry = true } label: { Label("Add by IP address", systemImage: "keyboard") }
            }
        }
        .scrollContentBackground(.hidden)
    }
}