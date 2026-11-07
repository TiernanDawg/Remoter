import Foundation

struct RokuDevice: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var ipAddress: String
    var modelName: String
    var modelNumber: String
    var serialNumber: String
    var deviceName: String
    var customName: String = ""
    var supportsVolume: Bool = false
    var supportsPower: Bool = false
    var supportsFindRemote: Bool = false

    var displayName: String {
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if !deviceName.isEmpty { return deviceName }
        return modelName.isEmpty ? "Roku device" : modelName
    }
}

enum RokuKey: String {
    case home = "Home", back = "Back"
    case up = "Up", down = "Down", left = "Left", right = "Right"
    case select = "Select", play = "Play", rewind = "Rev", fastForward = "Fwd"
    case instantReplay = "InstantReplay", info = "Info"
    case volumeUp = "VolumeUp", volumeDown = "VolumeDown", mute = "VolumeMute"
    case power = "PowerOff", channelUp = "ChannelUp", channelDown = "ChannelDown"
    case findRemote = "FindRemote"
}

struct RokuApp: Identifiable, Hashable {
    let id: String
    let name: String
}