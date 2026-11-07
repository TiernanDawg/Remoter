import SwiftUI

struct ManualConnectionView: View {
    @EnvironmentObject private var store: DeviceStore
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Roku IP address") {
                    TextField("192.168.1.25", text: $address)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    Text("On your Roku, open Settings → Network → About to find its IP address. Your iPhone and Roku must be on the same local network.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
                Section {
                    Button {
                        connect()
                    } label: {
                        HStack {
                            Spacer()
                            if isConnecting { ProgressView() } else { Text("Connect to Roku") }
                            Spacer()
                        }
                    }
                    .disabled(isConnecting || address.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Add by IP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func connect() {
        let ip = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let octets = ip.split(separator: ".")
        guard octets.count == 4, octets.allSatisfy({ UInt8($0) != nil }) else {
            errorMessage = "Enter an IPv4 address such as 192.168.1.25."
            return
        }
        isConnecting = true
        errorMessage = nil
        Task {
            do {
                let device = try await RokuClient(ipAddress: ip).verify()
                store.add(device)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isConnecting = false
        }
    }
}