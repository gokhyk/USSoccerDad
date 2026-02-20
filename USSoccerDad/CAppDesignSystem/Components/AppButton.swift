////
////  AppButton.swift
////  YouthSoccerApp
////
////  Reusable button component with consistent styling
////
//
//import SwiftUI
//
//struct AppButton: View {
//    // MARK: - Style
//    enum Style {
//        case primary
//        case secondary
//        case outline
//        case ghost
//        case danger
//        
//        var backgroundColor: Color {
//            switch self {
//            case .primary: return AppColors.primary
//            case .secondary: return AppColors.secondary
//            case .outline: return Color.clear
//            case .ghost: return Color.clear
//            case .danger: return AppColors.error
//            }
//        }
//        
//        var textColor: Color {
//            switch self {
//            case .primary, .danger: return .white
//            case .secondary: return AppColors.textPrimary
//            case .outline, .ghost: return AppColors.primary
//            }
//        }
//        
//        var borderColor: Color {
//            switch self {
//            case .outline: return AppColors.primary
//            default: return Color.clear
//            }
//        }
//        
//        var borderWidth: CGFloat {
//            self == .outline ? 2 : 0
//        }
//        
//        var shadowLevel: AppShadow.ElevationLevel {
//            switch self {
//            case .primary, .danger: return .medium
//            case .secondary: return .low
//            case .outline, .ghost: return .none
//            }
//        }
//    }
//    
//    // MARK: - Size
//    enum Size {
//        case small
//        case medium
//        case large
//        
//        var height: CGFloat {
//            switch self {
//            case .small: return 44
//            case .medium: return 52
//            case .large: return 56
//            }
//        }
//        
//        var horizontalPadding: CGFloat {
//            switch self {
//            case .small: return AppSpacing.md
//            case .medium: return AppSpacing.lg
//            case .large: return AppSpacing.xl
//            }
//        }
//        
//        var font: Font {
//            switch self {
//            case .small: return AppTypography.labelSmall
//            case .medium: return AppTypography.labelMedium
//            case .large: return AppTypography.buttonLabel
//            }
//        }
//    }
//    
//    // MARK: - Properties
//    let title: String
//    let style: Style
//    let size: Size
//    let action: () -> Void
//    var icon: String? = nil
//    var iconPosition: IconPosition = .leading
//    var isEnabled: Bool = true
//    var isLoading: Bool = false
//    var fullWidth: Bool = false
//    
//    enum IconPosition {
//        case leading, trailing
//    }
//    
//    // MARK: - Body
//    var body: some View {
//        Button(action: action) {
//            HStack(spacing: AppSpacing.sm) {
//                if isLoading {
//                    ProgressView()
//                        .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
//                        .scaleEffect(0.9)
//                } else {
//                    if let icon = icon, iconPosition == .leading {
//                        Image(systemName: icon)
//                            .font(size.font)
//                    }
//                    
//                    Text(title)
//                        .font(size.font)
//                    
//                    if let icon = icon, iconPosition == .trailing {
//                        Image(systemName: icon)
//                            .font(size.font)
//                    }
//                }
//            }
//            .frame(maxWidth: fullWidth ? .infinity : nil)
//            .frame(height: size.height)
//            .padding(.horizontal, size.horizontalPadding)
//            .foregroundColor(style.textColor)
//            .background(style.backgroundColor)
//            .cornerRadius(AppCornerRadius.medium)
//            .overlay(
//                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
//                    .stroke(style.borderColor, lineWidth: style.borderWidth)
//            )
//            .appShadow(style.shadowLevel)
//        }
//        .disabled(!isEnabled || isLoading)
//        .opacity(isEnabled && !isLoading ? 1.0 : 0.5)
//        .buttonPressEffect()
//    }
//}
//
//// MARK: - Convenience Initializers
//extension AppButton {
//    /// Primary button with default size
//    init(title: String, 
//         action: @escaping () -> Void,
//         isEnabled: Bool = true,
//         isLoading: Bool = false,
//         fullWidth: Bool = false) {
//        self.title = title
//        self.style = .primary
//        self.size = .large
//        self.action = action
//        self.isEnabled = isEnabled
//        self.isLoading = isLoading
//        self.fullWidth = fullWidth
//    }
//}
//
//// MARK: - Button Press Effect Modifier
//struct ButtonPressEffect: ViewModifier {
//    @GestureState private var isPressed = false
//    
//    func body(content: Content) -> some View {
//        content
//            .scaleEffect(isPressed ? 0.96 : 1.0)
//            .animation(AppAnimations.buttonPress, value: isPressed)
//            .simultaneousGesture(
//                DragGesture(minimumDistance: 0)
//                    .updating($isPressed) { _, state, _ in
//                        state = true
//                    }
//            )
//    }
//}
//
//extension View {
//    func buttonPressEffect() -> some View {
//        modifier(ButtonPressEffect())
//    }
//}
//
//// MARK: - Previews
//struct AppButton_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack(spacing: AppSpacing.lg) {
//            // Primary
//            AppButton(
//                title: "Start Game",
//                style: .primary,
//                size: .large,
//                action: {},
//                fullWidth: true
//            )
//            
//            // Secondary
//            AppButton(
//                title: "Cancel",
//                style: .secondary,
//                size: .large,
//                action: {},
//                fullWidth: true
//            )
//            
//            // Outline
//            AppButton(
//                title: "Settings",
//                style: .outline,
//                size: .medium,
//                action: {},
//                icon: AppIcons.settings,
//                iconPosition: .leading
//            )
//            
//            // Ghost
//            AppButton(
//                title: "Learn More",
//                style: .ghost,
//                size: .medium,
//                action: {},
//                icon: AppIcons.chevronRight,
//                iconPosition: .trailing
//            )
//            
//            // Danger
//            AppButton(
//                title: "Delete Game",
//                style: .danger,
//                size: .medium,
//                action: {},
//                icon: AppIcons.delete,
//                iconPosition: .leading
//            )
//            
//            // Loading state
//            AppButton(
//                title: "Loading...",
//                style: .primary,
//                size: .large,
//                action: {},
//                isLoading: true,
//                fullWidth: true
//            )
//            
//            // Disabled state
//            AppButton(
//                title: "Disabled",
//                style: .primary,
//                size: .large,
//                action: {},
//                isEnabled: false,
//                fullWidth: true
//            )
//            
//            // Small size
//            HStack {
//                AppButton(
//                    title: "Save",
//                    style: .primary,
//                    size: .small,
//                    action: {},
//                    icon: AppIcons.checkmark
//                )
//                
//                AppButton(
//                    title: "Cancel",
//                    style: .outline,
//                    size: .small,
//                    action: {}
//                )
//            }
//        }
//        .padding(AppSpacing.lg)
//        .background(AppColors.background)
//    }
//}
