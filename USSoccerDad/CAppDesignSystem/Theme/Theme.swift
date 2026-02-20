//
//  Theme.swift
//  YouthSoccerApp
//
//  Design System - Core Theme Constants
//  Use these throughout the app for consistent look and feel
//

import SwiftUI

// MARK: - Colors
struct AppColors {
    // MARK: Primary Colors - Soccer Field Green
    static let primary = Color(red: 0.20, green: 0.55, blue: 0.25)      // #33CC66
    static let primaryLight = Color(red: 0.25, green: 0.65, blue: 0.30) // #40D94D
    static let primaryDark = Color(red: 0.15, green: 0.45, blue: 0.20)  // #267333
    
    // MARK: Secondary Colors - Referee Yellow
    static let secondary = Color(red: 0.95, green: 0.77, blue: 0.06)    // #F2C410
    static let secondaryLight = Color(red: 1.0, green: 0.85, blue: 0.30) // #FFD94D
    
    // MARK: Accent - Whistle Blue
    static let accent = Color(red: 0.20, green: 0.45, blue: 0.80)       // #3372CC
    
    // MARK: Backgrounds
    static let background = Color(red: 0.97, green: 0.97, blue: 0.97)   // #F7F7F7
    static let surface = Color.white
    static let surfaceElevated = Color(red: 0.98, green: 0.98, blue: 0.98)
    
    // MARK: Text Colors
    static let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.11)  // #1C1C1C
    static let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.45) // #737373
    static let textTertiary = Color(red: 0.67, green: 0.67, blue: 0.67)  // #ABABAB
    
    // MARK: Status Colors
    static let success = Color(red: 0.20, green: 0.73, blue: 0.29)      // #33BA4A
    static let warning = Color(red: 0.95, green: 0.61, blue: 0.07)      // #F29C12
    static let error = Color(red: 0.90, green: 0.22, blue: 0.21)        // #E63835
    static let info = Color(red: 0.20, green: 0.60, blue: 0.86)         // #3399DB
    
    // MARK: Game Phase Colors
    static let phasePreGame = Color(red: 0.45, green: 0.67, blue: 0.92) // #7AAAEA
    static let phaseActive = success
    static let phaseBreak = secondary
    static let phaseComplete = Color(red: 0.55, green: 0.55, blue: 0.55) // #8C8C8C
    
    // MARK: Traffic Light System (Substitution Countdown)
    static let trafficGreen = Color(red: 0.13, green: 0.77, blue: 0.45) // #22C572
    static let trafficOrange = Color(red: 1.0, green: 0.60, blue: 0.00) // #FF9900
    static let trafficRed = Color(red: 0.96, green: 0.26, blue: 0.21)   // #F54336
    
    // MARK: Dark Mode Variants
    static let backgroundDark = Color(red: 0.11, green: 0.11, blue: 0.11) // #1C1C1C
    static let surfaceDark = Color(red: 0.15, green: 0.15, blue: 0.15)    // #262626
    static let surfaceElevatedDark = Color(red: 0.18, green: 0.18, blue: 0.18) // #2E2E2E
}

// MARK: - Typography
struct AppTypography {
    // MARK: Display - Large numbers, hero text
    static let displayLarge = Font.system(size: 57, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 45, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)
    
    // MARK: Headings
    static let heading1 = Font.system(size: 32, weight: .semibold, design: .default)
    static let heading2 = Font.system(size: 28, weight: .semibold, design: .default)
    static let heading3 = Font.system(size: 24, weight: .semibold, design: .default)
    static let heading4 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: Body Text
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    // MARK: Labels
    static let labelLarge = Font.system(size: 17, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 15, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 13, weight: .medium, design: .default)
    
    // MARK: Special Purpose
    static let timerDisplay: Font = {
        Font.system(size: 64, weight: .bold, design: .rounded)
            .monospacedDigit()
    }()
    
    static let statNumber: Font = {
        Font.system(size: 48, weight: .bold, design: .rounded)
            .monospacedDigit()
    }()
    
    static let buttonLabel = Font.system(size: 17, weight: .semibold, design: .default)
    
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
}

// MARK: - Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    
    // MARK: Semantic Spacing
    static let cardPadding: CGFloat = md          // 16
    static let screenPadding: CGFloat = lg        // 24
    static let sectionSpacing: CGFloat = xl       // 32
    static let itemSpacing: CGFloat = md          // 16
    
    // MARK: Touch Targets
    static let minTouchTarget: CGFloat = 44      // iOS minimum
    static let recommendedTouchTarget: CGFloat = 56  // Outdoor/gloves
}

// MARK: - Corner Radius
struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 24
    static let pill: CGFloat = 999  // Fully rounded
}

// MARK: - Shadows
struct AppShadow {
    static func elevation(_ level: ElevationLevel) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        switch level {
        case .none:
            return (Color.clear, 0, 0, 0)
        case .low:
            return (Color.black.opacity(0.05), 2, 0, 1)
        case .medium:
            return (Color.black.opacity(0.08), 4, 0, 2)
        case .high:
            return (Color.black.opacity(0.12), 8, 0, 4)
        case .extraHigh:
            return (Color.black.opacity(0.16), 12, 0, 6)
        }
    }
    
    enum ElevationLevel {
        case none, low, medium, high, extraHigh
    }
}

// MARK: - Animations
struct AppAnimations {
    // MARK: Durations
    static let fast: Double = 0.2
    static let normal: Double = 0.3
    static let slow: Double = 0.5
    
    // MARK: Standard Animations
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let easeOut = Animation.easeOut(duration: normal)
    static let easeInOut = Animation.easeInOut(duration: normal)
    
    // MARK: Specific Use Cases
    static let buttonPress = Animation.easeOut(duration: fast)
    static let cardAppear = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let phaseTransition = Animation.easeInOut(duration: slow)
    static let slideIn = Animation.spring(response: 0.6, dampingFraction: 0.8)
}

// MARK: - Icons (SF Symbols)
struct AppIcons {
    // MARK: Navigation
    static let home = "house.fill"
    static let settings = "gearshape.fill"
    static let calendar = "calendar"
    static let person = "person.fill"
    static let list = "list.bullet"
    
    // MARK: Game Actions
    static let whistle = "megaphone.fill"
    static let play = "play.fill"
    static let pause = "pause.fill"
    static let stop = "stop.fill"
    
    // MARK: Players
    static let playerOnField = "figure.run.circle.fill"
    static let playerBench = "figure.stand"
    static let substitute = "arrow.left.arrow.right.circle.fill"
    
    // MARK: Time
    static let clock = "clock.fill"
    static let timer = "timer"
    static let stopwatch = "stopwatch.fill"
    
    // MARK: Stats
    static let chartBar = "chart.bar.fill"
    static let trophy = "trophy.fill"
    static let star = "star.fill"
    static let trendUp = "chart.line.uptrend.xyaxis"
    
    // MARK: Actions
    static let checkmark = "checkmark.circle.fill"
    static let xmark = "xmark.circle.fill"
    static let warning = "exclamationmark.triangle.fill"
    static let info = "info.circle.fill"
    static let share = "square.and.arrow.up"
    static let plus = "plus.circle.fill"
    static let minus = "minus.circle.fill"
    static let edit = "pencil.circle.fill"
    static let delete = "trash.fill"
    
    // MARK: Navigation Chevrons
    static let chevronLeft = "chevron.left"
    static let chevronRight = "chevron.right"
    static let chevronDown = "chevron.down"
    static let chevronUp = "chevron.up"
}

// MARK: - Helper Extensions
extension Color {
    /// Creates a color from hex string (e.g., "#33CC66")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    /// Apply design system shadow
    func appShadow(_ level: AppShadow.ElevationLevel) -> some View {
        let shadow = AppShadow.elevation(level)
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}
