import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: DeviceStore
    @State private var showingScanner = false
    @State private var showingManualEntry = false

    var body: some View {
        NavigationStack {
            ZStack {
                homeBackdrop
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        header
                        if store.devices.isEmpty {
                            emptyState
                        } else {
                            deviceList
                            addDeviceButtons
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 22)
                    .padding(.bottom, 36)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingScanner) { DeviceScannerView() }
            .sheet(isPresented: $showingManualEntry) { ManualConnectionView() }
            .navigationDestination(for: RokuDevice.self) { device in
                RemoteView(device: device)
            }
        }
        .tint(Color(red: 0.68, green: 0.60, blue: 1))
    }

    private var homeBackdrop: some View {
        ZStack {
            Color(red: 0.025, green: 0.035, blue: 0.075)
            RadialGradient(colors: [Color.purple.opacity(0.34), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 360)
            RadialGradient(colors: [Color.blue.opacity(0.18), .clear],
                           center: .bottomLeading, startRadius: 0, endRadius: 330)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(red: 0.72, green: 0.64, blue: 1))
                    Text("REMOTER")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(2.2)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                Menu {
                    Button { showingScanner = true } label: { Label("Find Roku devices", systemImage: "wifi") }
                    Button { showingManualEntry = true } label: { Label("Enter IP address", systemImage: "keyboard") }
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(.white.opacity(0.10), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.10), lineWidth: 1))
                }
                .accessibilityLabel("Add Roku device")
            }
            Text("Your TV.\nUnder control.")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .tracking(-1.4)
                .foregroundStyle(.white)
            Text("A fast, focused remote for your Roku devices.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(.white.opacity(0.06))
                Image(systemName: "tv.and.mediabox")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(Color(red: 0.72, green: 0.64, blue: 1))
            }
            .frame(height: 190)
            VStack(alignment: .leading, spacing: 7) {
                Text("No Roku connected").font(.title2.bold()).foregroundStyle(.white)
                Text("Connect your iPhone to the same Wi-Fi network as your Roku. We’ll find it automatically.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.55))
            }
            Button { showingScanner = true } label: {
                Label("Find my Roku", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(LinearGradient(colors: [.purple, Color.blue.opacity(0.85)],
                                               startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            Button("Enter IP address instead") { showingManualEntry = true }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.09), lineWidth: 1))
    }

    private var deviceList: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("YOUR DEVICES")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
                Text("\(store.devices.count) SAVED")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
            ForEach(store.devices) { device in
                NavigationLink(value: device) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16).fill(.purple.opacity(0.19))
                            Image(systemName: "tv.fill")
                                .font(.title3)
                                .foregroundStyle(Color(red: 0.77, green: 0.70, blue: 1))
                        }
                        .frame(width: 52, height: 52)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(device.displayName).font(.headline).foregroundStyle(.white)
                            Text("\(device.modelName.isEmpty ? "Roku" : device.modelName)  ·  \(device.ipAddress)")
                                .font(.caption).foregroundStyle(.white.opacity(0.48))
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .padding(15)
                    .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.07), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { store.select(device) })
                .contextMenu {
                    Button(role: .destructive) { store.remove(device) } label: {
                        Label("Remove device", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var addDeviceButtons: some View {
        HStack(spacing: 12) {
            Button { showingScanner = true } label: {
                Label("Scan network", systemImage: "wifi")
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered)
            Button { showingManualEntry = true } label: {
                Label("Add by IP", systemImage: "keyboard")
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered)
        }
        .tint(.white.opacity(0.85))
    }
}
