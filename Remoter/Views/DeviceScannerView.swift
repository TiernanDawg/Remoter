import SwiftUI

struct DeviceScannerView: View {
    @EnvironmentObject private var store: DeviceStore
    @Environment(\.dismiss) private var dismiss
    @State private var devices: [RokuDevice] = []
    @State private var isScanning = false
    @State private var progress = 0
    @State private var message = "Search your current Wi-Fi network for Roku devices."

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if isScanning {
                    ProgressView(value: Double(progress), total: 254).tint(.purple)
                    Text("Checking local network… \(progress)/254")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Image(systemName: "wifi").font(.system(size: 42)).foregroundStyle(.purple)
                }

                Text(message).multilineTextAlignment(.center).foregroundStyle(.secondary)

                if !devices.isEmpty {
                    List(devices) { device in
                        Button {
                            store.add(device)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.displayName).font(.headline)
                                Text("\(device.modelName) · \(device.ipAddress)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .tint(.primary)
                    }
                    .listStyle(.insetGrouped)
                }

                if !isScanning && devices.isEmpty {
                    Button("Scan again") { startScan() }.buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Find Roku")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
            }
            .task {
                if devices.isEmpty { startScan() }
            }
        }
    }

    private func startScan() {
        guard !isScanning else { return }
        isScanning = true
        progress = 0
        message = "Scanning the current Wi-Fi subnet. Keep your Roku awake."
        Task {
            let found = await RokuDiscovery.scan { count in
                Task { @MainActor in progress = count }
            }
            devices = found
            isScanning = false
            message = found.isEmpty
                ? "No Roku devices found. Confirm both devices use the same Wi-Fi and try entering the Roku IP manually."
                : "Select a Roku to save it."
        }
    }
}