import SwiftUI
import Combine

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@MainActor
final class AppearancePreferences: ObservableObject {
    static let key = "TwinTrack.appearance.v1"
    private let defaults: UserDefaults
    @Published var selection: AppAppearance {
        didSet { defaults.set(selection.rawValue, forKey: Self.key) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selection = defaults.string(forKey: Self.key).flatMap(AppAppearance.init(rawValue:)) ?? .system
    }

    static func forApp() -> AppearancePreferences {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--synthetic-appearance-ui-tests"),
           arguments.indices.contains(index + 1), let id = UUID(uuidString: arguments[index + 1]),
           let defaults = UserDefaults(suiteName: "TwinTrack.AppearanceUITests.\(id.uuidString)") {
            return AppearancePreferences(defaults: defaults)
        }
#endif
        return AppearancePreferences()
    }
}

extension EnvironmentValues {
    @Entry var appearanceSelection: Binding<AppAppearance> = .constant(.system)
}

// Test-only accessibility metadata observes the actual rendered environment,
// not the saved preference. It introduces no per-screen theme preference.
private struct AppearanceTestValue: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--synthetic-appearance-ui-tests") {
            content.accessibilityValue(colorScheme == .dark ? "Dark appearance" : "Light appearance")
        } else { content }
#else
        content
#endif
    }
}

extension View {
    func appearanceTestValue() -> some View { modifier(AppearanceTestValue()) }
}
