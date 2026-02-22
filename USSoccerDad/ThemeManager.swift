//
//  ThemeManager.swift
//  YouthSoccerApp
//
//  Multi-theme support with instant switching
//  Usage: @EnvironmentObject var themeManager: ThemeManager
//

import SwiftUI

// MARK: - Theme Protocol
protocol Theme {
    var name: String { get }
    var isDark: Bool { get }
    var primary: Color { get }
    var primaryLight: Color { get }
    var primaryDark: Color { get }
    var secondary: Color { get }
    var secondaryLight: Color { get }
    var accent: Color { get }
    var background: Color { get }
    var surface: Color { get }
    var surfaceElevated: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var info: Color { get }
    var trafficGreen: Color { get }
    var trafficOrange: Color { get }
    var trafficRed: Color { get }
}

extension Theme {
    var isDark: Bool { false }
}

// MARK: - Soccer Field Theme (Original)
struct SoccerFieldTheme: Theme {
    let name = "Soccer Field"
    
    let primary = Color(red: 0.20, green: 0.55, blue: 0.25)      // Green
    let primaryLight = Color(red: 0.25, green: 0.65, blue: 0.30)
    let primaryDark = Color(red: 0.15, green: 0.45, blue: 0.20)
    let secondary = Color(red: 0.95, green: 0.77, blue: 0.06)    // Yellow
    let secondaryLight = Color(red: 1.0, green: 0.85, blue: 0.30)
    let accent = Color(red: 0.20, green: 0.45, blue: 0.80)       // Blue
    
    let background = Color(red: 0.97, green: 0.97, blue: 0.97)
    let surface = Color.white
    let surfaceElevated = Color(red: 0.98, green: 0.98, blue: 0.98)
    
    let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.11)
    let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.45)
    let textTertiary = Color(red: 0.67, green: 0.67, blue: 0.67)
    
    let success = Color(red: 0.20, green: 0.73, blue: 0.29)
    let warning = Color(red: 0.95, green: 0.61, blue: 0.07)
    let error = Color(red: 0.90, green: 0.22, blue: 0.21)
    let info = Color(red: 0.20, green: 0.60, blue: 0.86)
    
    let trafficGreen = Color(red: 0.13, green: 0.77, blue: 0.45)
    let trafficOrange = Color(red: 1.0, green: 0.60, blue: 0.00)
    let trafficRed = Color(red: 0.96, green: 0.26, blue: 0.21)
}

// MARK: - Ocean Blue Theme
struct OceanBlueTheme: Theme {
    let name = "Ocean Blue"
    
    let primary = Color(red: 0.15, green: 0.45, blue: 0.75)      // Ocean Blue
    let primaryLight = Color(red: 0.25, green: 0.55, blue: 0.85)
    let primaryDark = Color(red: 0.10, green: 0.35, blue: 0.65)
    let secondary = Color(red: 0.00, green: 0.75, blue: 0.80)    // Teal
    let secondaryLight = Color(red: 0.20, green: 0.85, blue: 0.90)
    let accent = Color(red: 0.95, green: 0.55, blue: 0.20)       // Coral
    
    let background = Color(red: 0.96, green: 0.98, blue: 1.00)
    let surface = Color.white
    let surfaceElevated = Color(red: 0.98, green: 0.99, blue: 1.00)
    
    let textPrimary = Color(red: 0.08, green: 0.15, blue: 0.25)
    let textSecondary = Color(red: 0.40, green: 0.45, blue: 0.55)
    let textTertiary = Color(red: 0.65, green: 0.68, blue: 0.75)
    
    let success = Color(red: 0.15, green: 0.70, blue: 0.45)
    let warning = Color(red: 0.95, green: 0.65, blue: 0.15)
    let error = Color(red: 0.85, green: 0.25, blue: 0.25)
    let info = Color(red: 0.20, green: 0.60, blue: 0.90)
    
    let trafficGreen = Color(red: 0.13, green: 0.77, blue: 0.45)
    let trafficOrange = Color(red: 1.0, green: 0.60, blue: 0.00)
    let trafficRed = Color(red: 0.96, green: 0.26, blue: 0.21)
}

// MARK: - Sunset Orange Theme
struct SunsetOrangeTheme: Theme {
    let name = "Sunset Orange"
    
    let primary = Color(red: 0.95, green: 0.45, blue: 0.15)      // Vibrant Orange
    let primaryLight = Color(red: 1.00, green: 0.55, blue: 0.25)
    let primaryDark = Color(red: 0.85, green: 0.35, blue: 0.10)
    let secondary = Color(red: 0.90, green: 0.20, blue: 0.35)    // Red-Pink
    let secondaryLight = Color(red: 1.00, green: 0.35, blue: 0.50)
    let accent = Color(red: 0.35, green: 0.20, blue: 0.75)       // Purple
    
    let background = Color(red: 1.00, green: 0.98, blue: 0.96)
    let surface = Color.white
    let surfaceElevated = Color(red: 1.00, green: 0.99, blue: 0.98)
    
    let textPrimary = Color(red: 0.20, green: 0.10, blue: 0.10)
    let textSecondary = Color(red: 0.55, green: 0.40, blue: 0.40)
    let textTertiary = Color(red: 0.75, green: 0.65, blue: 0.65)
    
    let success = Color(red: 0.25, green: 0.75, blue: 0.35)
    let warning = Color(red: 0.95, green: 0.65, blue: 0.15)
    let error = Color(red: 0.90, green: 0.25, blue: 0.25)
    let info = Color(red: 0.35, green: 0.55, blue: 0.85)
    
    let trafficGreen = Color(red: 0.13, green: 0.77, blue: 0.45)
    let trafficOrange = Color(red: 1.0, green: 0.60, blue: 0.00)
    let trafficRed = Color(red: 0.96, green: 0.26, blue: 0.21)
}

// MARK: - Midnight Dark Theme
struct MidnightDarkTheme: Theme {
    let name = "Midnight"
    let isDark = true

    let primary = Color(red: 0.40, green: 0.60, blue: 0.95)      // Bright Blue
    let primaryLight = Color(red: 0.50, green: 0.70, blue: 1.00)
    let primaryDark = Color(red: 0.30, green: 0.50, blue: 0.85)
    let secondary = Color(red: 0.60, green: 0.35, blue: 0.95)    // Purple
    let secondaryLight = Color(red: 0.70, green: 0.45, blue: 1.00)
    let accent = Color(red: 0.00, green: 0.90, blue: 0.70)       // Cyan
    
    let background = Color(red: 0.08, green: 0.08, blue: 0.12)   // Deep dark
    let surface = Color(red: 0.12, green: 0.12, blue: 0.16)
    let surfaceElevated = Color(red: 0.16, green: 0.16, blue: 0.20)
    
    let textPrimary = Color(red: 0.95, green: 0.95, blue: 0.97)
    let textSecondary = Color(red: 0.65, green: 0.65, blue: 0.70)
    let textTertiary = Color(red: 0.45, green: 0.45, blue: 0.50)
    
    let success = Color(red: 0.30, green: 0.85, blue: 0.50)
    let warning = Color(red: 0.95, green: 0.70, blue: 0.20)
    let error = Color(red: 0.95, green: 0.35, blue: 0.35)
    let info = Color(red: 0.40, green: 0.70, blue: 0.95)
    
    let trafficGreen = Color(red: 0.20, green: 0.85, blue: 0.55)
    let trafficOrange = Color(red: 1.0, green: 0.65, blue: 0.10)
    let trafficRed = Color(red: 0.96, green: 0.35, blue: 0.35)
}

// MARK: - Forest Green Theme
struct ForestGreenTheme: Theme {
    let name = "Forest"
    
    let primary = Color(red: 0.15, green: 0.50, blue: 0.30)      // Forest Green
    let primaryLight = Color(red: 0.25, green: 0.60, blue: 0.40)
    let primaryDark = Color(red: 0.10, green: 0.40, blue: 0.25)
    let secondary = Color(red: 0.55, green: 0.45, blue: 0.25)    // Earth Brown
    let secondaryLight = Color(red: 0.65, green: 0.55, blue: 0.35)
    let accent = Color(red: 0.85, green: 0.65, blue: 0.30)       // Gold
    
    let background = Color(red: 0.96, green: 0.97, blue: 0.95)
    let surface = Color(red: 0.99, green: 0.99, blue: 0.98)
    let surfaceElevated = Color.white
    
    let textPrimary = Color(red: 0.15, green: 0.20, blue: 0.15)
    let textSecondary = Color(red: 0.45, green: 0.50, blue: 0.45)
    let textTertiary = Color(red: 0.65, green: 0.70, blue: 0.65)
    
    let success = Color(red: 0.25, green: 0.75, blue: 0.40)
    let warning = Color(red: 0.90, green: 0.65, blue: 0.20)
    let error = Color(red: 0.85, green: 0.30, blue: 0.25)
    let info = Color(red: 0.30, green: 0.55, blue: 0.75)
    
    let trafficGreen = Color(red: 0.20, green: 0.80, blue: 0.45)
    let trafficOrange = Color(red: 0.95, green: 0.65, blue: 0.15)
    let trafficRed = Color(red: 0.90, green: 0.30, blue: 0.25)
}

// MARK: - Monochrome Theme
struct MonochromeTheme: Theme {
    let name = "Monochrome"
    
    let primary = Color(red: 0.20, green: 0.20, blue: 0.20)      // Dark Gray
    let primaryLight = Color(red: 0.35, green: 0.35, blue: 0.35)
    let primaryDark = Color(red: 0.10, green: 0.10, blue: 0.10)
    let secondary = Color(red: 0.55, green: 0.55, blue: 0.55)    // Mid Gray
    let secondaryLight = Color(red: 0.70, green: 0.70, blue: 0.70)
    let accent = Color(red: 0.15, green: 0.15, blue: 0.15)
    
    let background = Color(red: 0.98, green: 0.98, blue: 0.98)
    let surface = Color.white
    let surfaceElevated = Color(red: 0.99, green: 0.99, blue: 0.99)
    
    let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.10)
    let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.45)
    let textTertiary = Color(red: 0.70, green: 0.70, blue: 0.70)
    
    let success = Color(red: 0.30, green: 0.30, blue: 0.30)
    let warning = Color(red: 0.50, green: 0.50, blue: 0.50)
    let error = Color(red: 0.20, green: 0.20, blue: 0.20)
    let info = Color(red: 0.40, green: 0.40, blue: 0.40)
    
    let trafficGreen = Color(red: 0.40, green: 0.40, blue: 0.40)
    let trafficOrange = Color(red: 0.60, green: 0.60, blue: 0.60)
    let trafficRed = Color(red: 0.25, green: 0.25, blue: 0.25)
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme {
        didSet {
            saveThemePreference()
        }
    }
    
    static let availableThemes: [Theme] = [
        SoccerFieldTheme(),
        OceanBlueTheme(),
        SunsetOrangeTheme(),
        MidnightDarkTheme(),
        ForestGreenTheme(),
        MonochromeTheme()
    ]
    
    init() {
        // Load saved theme preference or default to Soccer Field
        if let savedThemeName = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = Self.availableThemes.first(where: { $0.name == savedThemeName }) {
            self.currentTheme = theme
        } else {
            self.currentTheme = SoccerFieldTheme()
        }
    }
    
    func setTheme(_ theme: Theme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }
    
    private func saveThemePreference() {
        UserDefaults.standard.set(currentTheme.name, forKey: "selectedTheme")
    }
}

// MARK: - Theme-aware Color Access
extension ThemeManager {
    var colors: ThemeColors {
        ThemeColors(theme: currentTheme)
    }

    var colorScheme: ColorScheme {
        currentTheme.isDark ? .dark : .light
    }
}

struct ThemeColors {
    private let theme: Theme
    
    init(theme: Theme) {
        self.theme = theme
    }
    
    var primary: Color { theme.primary }
    var primaryLight: Color { theme.primaryLight }
    var primaryDark: Color { theme.primaryDark }
    var secondary: Color { theme.secondary }
    var secondaryLight: Color { theme.secondaryLight }
    var accent: Color { theme.accent }
    var background: Color { theme.background }
    var surface: Color { theme.surface }
    var surfaceElevated: Color { theme.surfaceElevated }
    var textPrimary: Color { theme.textPrimary }
    var textSecondary: Color { theme.textSecondary }
    var textTertiary: Color { theme.textTertiary }
    var success: Color { theme.success }
    var warning: Color { theme.warning }
    var error: Color { theme.error }
    var info: Color { theme.info }
    var trafficGreen: Color { theme.trafficGreen }
    var trafficOrange: Color { theme.trafficOrange }
    var trafficRed: Color { theme.trafficRed }
}

// MARK: - Environment Key
private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View Extension for Easy Access
extension View {
    func withThemeManager(_ themeManager: ThemeManager) -> some View {
        self.environmentObject(themeManager)
    }
}
