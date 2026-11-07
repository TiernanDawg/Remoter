import Foundation

enum RokuClientError: LocalizedError {
    case invalidAddress, notRoku, commandRejected(Int), emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidAddress: return "Enter a valid IPv4 address."
        case .notRoku: return "No Roku device responded at that address. Check the IP and make sure the Roku is awake and on the same Wi-Fi."
        case .commandRejected(let code): return "The Roku rejected the request (HTTP \(code)). Check its Control by mobile apps setting."
        case .emptyResponse: return "The Roku returned an empty response."
        }
    }
}

struct RokuClient {
    let ipAddress: String
    private var baseURL: URL { URL(string: "http://\(ipAddress):8060")! }

    func verify() async throws -> RokuDevice {
        let data = try await get("/query/device-info")
        guard let xml = String(data: data, encoding: .utf8),
              xml.localizedCaseInsensitiveContains("<device-info") else {
            throw RokuClientError.notRoku
        }

        func value(_ tag: String) -> String {
            guard let range = xml.range(of: "<\(tag)>[\\s\\S]*?</\(tag)>", options: .regularExpression) else { return "" }
            return String(xml[range])
                .replacingOccurrences(of: "<\(tag)>", with: "")
                .replacingOccurrences(of: "</\(tag)>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
        }

        let modelName = value("model-name")
        let isRokuTV = modelName.localizedCaseInsensitiveContains("TV")
        let isStreambar = modelName.localizedCaseInsensitiveContains("Streambar")

        return RokuDevice(
            ipAddress: ipAddress,
            modelName: modelName,
            modelNumber: value("model-number"),
            serialNumber: value("serial-number"),
            deviceName: value("user-device-name"),
            supportsVolume: value("supports-audio-volume-control") == "true" || isRokuTV || isStreambar,
            supportsPower: value("supports-tv-power-control") == "true" || isRokuTV,
            supportsFindRemote: value("supports-find-remote") == "true"
        )
    }

    func press(_ key: RokuKey) async throws {
        _ = try await post("/keypress/\(key.rawValue)")
    }

    func type(_ text: String) async throws {
        for character in text.prefix(120) {
            let encoded = String(character).addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            guard !encoded.isEmpty else { continue }
            _ = try await post("/keypress/Lit_\(encoded)")
            try await Task.sleep(nanoseconds: 35_000_000)
        }
    }

    func apps() async throws -> [RokuApp] {
        let data = try await get("/query/apps")
        guard let xml = String(data: data, encoding: .utf8) else { throw RokuClientError.emptyResponse }
        let regex = try NSRegularExpression(pattern: #"<app[^>]*id="([^"]+)"[^>]*>([^<]+)</app>"#, options: [.caseInsensitive])
        let ns = xml as NSString
        return regex.matches(in: xml, range: NSRange(location: 0, length: ns.length)).compactMap { match in
            guard match.numberOfRanges == 3 else { return nil }
            return RokuApp(id: ns.substring(with: match.range(at: 1)), name: ns.substring(with: match.range(at: 2)))
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func launch(_ app: RokuApp) async throws {
        _ = try await post("/launch/\(app.id)")
    }

    private func get(_ path: String) async throws -> Data {
        guard let url = URL(string: baseURL.absoluteString + path) else { throw RokuClientError.invalidAddress }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 2
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return data
    }

    private func post(_ path: String) async throws -> Data {
        guard let url = URL(string: baseURL.absoluteString + path) else { throw RokuClientError.invalidAddress }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data()
        request.timeoutInterval = 2
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return data
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw RokuClientError.emptyResponse }
        guard (200..<300).contains(http.statusCode) else { throw RokuClientError.commandRejected(http.statusCode) }
    }
}