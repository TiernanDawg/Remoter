import SwiftUI
import UIKit

enum RemoteTheme: String, CaseIterable, Identifiable {
    case glass
    case porcelain
    case oled
    case arcade

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glass: return "Midnight Glass"
        case .porcelain: return "Porcelain"
        case .oled: return "Pure OLED"
        case .arcade: return "Neon Pulse"
        }
    }

    var subtitle: String {
        switch self {
        case .glass: return "Soft blue light and liquid surfaces"
        case .porcelain: return "Warm, minimal and understated"
        case .oled: return "Pure black with crisp white controls"
        case .arcade: return "Electric violet and cyan accents"
        }
    }

    var isLight: Bool { self == .porcelain }
    var usesGlass: Bool { self == .glass }

    var backgroundTop: Color {
        switch self {
        case .glass: return Color(red: 0.035, green: 0.065, blue: 0.13)
        case .porcelain: return Color(red: 0.94, green: 0.95, blue: 0.98)
        case .oled: return .black
        case .arcade: return Color(red: 0.055, green: 0.025, blue: 0.10)
        }
    }

    var backgroundBottom: Color {
        switch self {
        case .glass: return Color(red: 0.075, green: 0.055, blue: 0.15)
        case .porcelain: return Color(red: 0.86, green: 0.89, blue: 0.95)
        case .oled: return Color(red: 0.025, green: 0.025, blue: 0.035)
        case .arcade: return Color(red: 0.12, green: 0.025, blue: 0.17)
        }
    }

    var accent: Color {
        switch self {
        case .glass: return Color(red: 0.62, green: 0.68, blue: 1.0)
        case .porcelain: return Color(red: 0.26, green: 0.34, blue: 0.72)
        case .oled: return Color(red: 0.94, green: 0.95, blue: 1.0)
        case .arcade: return Color(red: 0.76, green: 0.36, blue: 1.0)
        }
    }

    var accentSecondary: Color {
        switch self {
        case .glass: return Color(red: 0.34, green: 0.58, blue: 0.92)
        case .porcelain: return Color(red: 0.34, green: 0.56, blue: 0.76)
        case .oled: return Color(red: 0.68, green: 0.72, blue: 0.78)
        case .arcade: return Color(red: 0.15, green: 0.88, blue: 0.91)
        }
    }

    var panel: Color {
        switch self {
        case .glass: return Color.white.opacity(0.075)
        case .porcelain: return Color.white.opacity(0.76)
        case .oled: return Color(red: 0.075, green: 0.075, blue: 0.085)
        case .arcade: return Color(red: 0.16, green: 0.075, blue: 0.23)
        }
    }

    var panelRaised: Color {
        switch self {
        case .glass: return Color.white.opacity(0.13)
        case .porcelain: return Color.white.opacity(0.96)
        case .oled: return Color(red: 0.13, green: 0.13, blue: 0.15)
        case .arcade: return Color(red: 0.22, green: 0.09, blue: 0.32)
        }
    }

    var foreground: Color {
        isLight ? Color(red: 0.12, green: 0.14, blue: 0.20) : Color(red: 0.96, green: 0.97, blue: 1.0)
    }

    var muted: Color {
        isLight ? Color(red: 0.34, green: 0.38, blue: 0.47) : Color(red: 0.70, green: 0.73, blue: 0.82)
    }

    var border: Color {
        isLight ? Color(red: 0.40, green: 0.44, blue: 0.55).opacity(0.16) : Color.white.opacity(0.13)
    }

    var centerFill: Color {
        switch self {
        case .glass: return Color(red: 0.70, green: 0.75, blue: 0.98).opacity(0.22)
        case .porcelain: return Color(red: 0.89, green: 0.92, blue: 0.99)
        case .oled: return Color.white.opacity(0.10)
        case .arcade: return Color(red: 0.35, green: 0.12, blue: 0.52)
        }
    }
}

struct ThemePickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    private var selectedTheme: RemoteTheme {
        RemoteTheme(rawValue: selection) ?? .glass
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose the look that feels right. Your selection is saved on this iPhone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)

                    ForEach(RemoteTheme.allCases) { theme in
                        Button {
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                                selection = theme.rawValue
                            }
                        } label: {
                            themeCard(theme)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func themeCard(_ theme: RemoteTheme) -> some View {
        let isSelected = selection == theme.rawValue

        return HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(LinearGradient(colors: [theme.backgroundTop, theme.backgroundBottom],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                VStack(spacing: 5) {
                    HStack(spacing: 4) {
                        Circle().fill(theme.accent).frame(width: 5, height: 5)
                        RoundedRectangle(cornerRadius: 3).fill(theme.panelRaised).frame(width: 28, height: 5)
                    }
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.panel)
                        .overlay(Circle().fill(theme.centerFill).frame(width: 20, height: 20))
                        .frame(width: 58, height: 37)
                    HStack(spacing: 3) {
                        ForEach(0..<3) { _ in
                            Capsule().fill(theme.panelRaised).frame(width: 18, height: 7)
                        }
                    }
                }
            }
            .frame(width: 92, height: 88)

            VStack(alignment: .leading, spacing: 5) {
                Text(theme.title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(theme.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 5) {
                    Circle().fill(theme.accent).frame(width: 7, height: 7)
                    Circle().fill(theme.accentSecondary).frame(width: 7, height: 7)
                    Text(isSelected ? "CURRENT THEME" : "TAP TO PREVIEW")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.7)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.45))
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(isSelected ? Color.accentColor.opacity(0.7) : Color.primary.opacity(0.06),
                    lineWidth: isSelected ? 1.5 : 1))
    }
}
