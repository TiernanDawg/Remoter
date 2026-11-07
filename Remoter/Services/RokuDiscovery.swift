import Foundation
import Darwin

enum RokuDiscovery {
    static func scan(progress: @escaping @Sendable (Int) -> Void = { _ in }) async -> [RokuDevice] {
        guard let prefix = localIPv4Prefix() else { return [] }
        let hosts = (1...254).map { "\(prefix).\($0)" }
        var found: [RokuDevice] = []
        var completed = 0

        await withTaskGroup(of: RokuDevice?.self) { group in
            var next = 0
            let concurrency = 24

            func add(_ host: String) {
                group.addTask {
                    try? await RokuClient(ipAddress: host).verify()
                }
            }

            while next < min(concurrency, hosts.count) {
                add(hosts[next])
                next += 1
            }

            while let result = await group.next() {
                if let result, !found.contains(where: { $0.ipAddress == result.ipAddress }) {
                    found.append(result)
                }
                completed += 1
                progress(completed)
                if next < hosts.count {
                    add(hosts[next])
                    next += 1
                }
            }
        }

        return found.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private static func localIPv4Prefix() -> String? {
        var first: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&first) == 0, let start = first else { return nil }
        defer { freeifaddrs(first) }

        var current: UnsafeMutablePointer<ifaddrs>? = start
        while let item = current {
            let entry = item.pointee
            current = entry.ifa_next
            guard let address = entry.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_INET),
                  String(cString: entry.ifa_name) == "en0" else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                address,
                socklen_t(address.pointee.sa_len),
                &host,
                socklen_t(host.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            guard result == 0 else { continue }
            let parts = String(cString: host).split(separator: ".")
            guard parts.count == 4, parts[0] != "169" else { continue }
            return parts.prefix(3).joined(separator: ".")
        }
        return nil
    }
}