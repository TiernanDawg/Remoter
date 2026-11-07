import Foundation
import SwiftUI

@MainActor
final class DeviceStore: ObservableObject {
    @Published private(set) var devices: [RokuDevice] = []
    @Published var selectedDeviceID: UUID?

    private let storageKey = "remoter.savedRokuDevices"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([RokuDevice].self, from: data) {
            devices = saved
        }
        selectedDeviceID = devices.first?.id
    }

    func add(_ device: RokuDevice) {
        if let index = devices.firstIndex(where: { $0.ipAddress == device.ipAddress }) {
            var updated = device
            updated.id = devices[index].id
            updated.customName = devices[index].customName
            devices[index] = updated
        } else {
            devices.append(device)
        }
        selectedDeviceID = devices.first(where: { $0.ipAddress == device.ipAddress })?.id
        persist()
    }

    func rename(_ device: RokuDevice, to name: String) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }
        devices[index].customName = name
        persist()
    }

    func remove(_ device: RokuDevice) {
        devices.removeAll { $0.id == device.id }
        if selectedDeviceID == device.id { selectedDeviceID = devices.first?.id }
        persist()
    }

    func select(_ device: RokuDevice) {
        selectedDeviceID = device.id
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(devices) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}