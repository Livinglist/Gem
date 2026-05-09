import SwiftUI
enum PreferredColorScheme: CaseIterable, Hashable {
    case dark, light, system
    
    var label: String {
        switch self {
        case .dark: "Dark"
        case .light: "Light"
        case .system: "System"
        }
    }
}

extension PreferredColorScheme {
    static func fromString(_ str: String) -> PreferredColorScheme {
        switch str {
        case "dark": .dark
        case "light": .light
        default: .system
        }
    }
    
    func toString() -> String {
        switch self {
        case .dark: "dark"
        case .light: "light"
        case .system: "system"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .dark: .dark
        case .light: .light
        case .system: nil
        }
    }
}
