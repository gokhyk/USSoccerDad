//
//  AppButton_Themed.swift
//  YouthSoccerApp
//
//  Theme-aware button component
//  Replace AppButton.swift with this version for theme support
//

import SwiftUI

struct AppButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    enum Style {
        case primary
        case secondary
        case outline
        case ghost
        case danger
    }
    
    enum Size {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 44
            case .medium: return 52
            case .large: return 56
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return AppSpacing.md
            case .medium: return AppSpacing.lg
            case .large: return AppSpacing.xl
            }
        }
        
        var font: Font {
            switch self {
            case .small: return AppTypography.labelSmall
            case .medium: return AppTypography.labelMedium
            case .large: return AppTypography.buttonLabel
            }
        }
    }
    
    let title: String
    let style: Style
    let size: Size
    let action: () -> Void
    var icon: String? = nil
    var iconPosition: IconPosition = .leading
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var fullWidth: Bool = false
    
    enum IconPosition {
        case leading, trailing
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon, iconPosition == .leading {
                        Image(systemName: icon)
                            .font(size.font)
                    }
                    
                    Text(title)
                        .font(size.font)
                    
                    if let icon = icon, iconPosition == .trailing {
                        Image(systemName: icon)
                            .font(size.font)
                    }
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .foregroundColor(textColor)
            .background(backgroundColor)
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .appShadow(shadowLevel)
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled && !isLoading ? 1.0 : 0.5)
        //.buttonPressEffect()
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return themeManager.colors.primary
        case .secondary: return themeManager.colors.secondary
        case .outline: return Color.clear
        case .ghost: return Color.clear
        case .danger: return themeManager.colors.error
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .danger: return .white
        case .secondary: return themeManager.colors.textPrimary
        case .outline, .ghost: return themeManager.colors.primary
        }
    }
    
    private var borderColor: Color {
        style == .outline ? themeManager.colors.primary : Color.clear
    }
    
    private var borderWidth: CGFloat {
        style == .outline ? 2 : 0
    }
    
    private var shadowLevel: AppShadow.ElevationLevel {
        switch style {
        case .primary, .danger: return .medium
        case .secondary: return .low
        case .outline, .ghost: return .none
        }
    }
}

// Convenience initializer
extension AppButton {
    init(title: String,
         action: @escaping () -> Void,
         isEnabled: Bool = true,
         isLoading: Bool = false,
         fullWidth: Bool = false) {
        self.title = title
        self.style = .primary
        self.size = .large
        self.action = action
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.fullWidth = fullWidth
    }
}
