//
//  AppCard.swift
//  YouthSoccerApp
//
//  Reusable card component with elevation and padding
//

import SwiftUI

struct AppCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppSpacing.md
    var elevation: AppShadow.ElevationLevel = .medium
    var backgroundColor: Color = AppColors.surface
    var cornerRadius: CGFloat = AppCornerRadius.large
    
    init(padding: CGFloat = AppSpacing.md,
         elevation: AppShadow.ElevationLevel = .medium,
         backgroundColor: Color = AppColors.surface,
         cornerRadius: CGFloat = AppCornerRadius.large,
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.elevation = elevation
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .appShadow(elevation)
    }
}

// MARK: - Tappable Card Variant
struct TappableCard<Content: View>: View {
    let content: Content
    let action: () -> Void
    var padding: CGFloat = AppSpacing.md
    var elevation: AppShadow.ElevationLevel = .medium
    var backgroundColor: Color = AppColors.surface
    
    init(action: @escaping () -> Void,
         padding: CGFloat = AppSpacing.md,
         elevation: AppShadow.ElevationLevel = .medium,
         backgroundColor: Color = AppColors.surface,
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.action = action
        self.padding = padding
        self.elevation = elevation
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        Button(action: action) {
            AppCard(
                padding: padding,
                elevation: elevation,
                backgroundColor: backgroundColor
            ) {
                content
            }
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Card Button Style
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppAnimations.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - Specialized Card Variants

/// Card with header and optional footer
struct SectionCard<Header: View, Content: View, Footer: View>: View {
    let header: Header
    let content: Content
    let footer: Footer?
    
    init(@ViewBuilder header: () -> Header,
         @ViewBuilder content: () -> Content,
         @ViewBuilder footer: () -> Footer) {
        self.header = header()
        self.content = content()
        self.footer = footer()
    }
    
    init(@ViewBuilder header: () -> Header,
         @ViewBuilder content: () -> Content) where Footer == EmptyView {
        self.header = header()
        self.content = content()
        self.footer = nil
    }
    
    var body: some View {
        AppCard(padding: 0) {
            VStack(spacing: 0) {
                // Header
                header
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surfaceElevated)
                
                // Content
                content
                    .padding(AppSpacing.md)
                
                // Footer (if provided)
                if let footer = footer {
                    Divider()
                        .background(AppColors.textTertiary.opacity(0.3))
                    
                    footer
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
}

/// Game summary card with phase indicator
struct GameCard: View {
    let title: String
    let subtitle: String?
    let phase: GamePhase
    let action: () -> Void
    
    enum GamePhase {
        case upcoming
        case active
        case completed
        
        var color: Color {
            switch self {
            case .upcoming: return AppColors.phasePreGame
            case .active: return AppColors.phaseActive
            case .completed: return AppColors.phaseComplete
            }
        }
        
        var icon: String {
            switch self {
            case .upcoming: return AppIcons.calendar
            case .active: return AppIcons.play
            case .completed: return AppIcons.checkmark
            }
        }
        
        var text: String {
            switch self {
            case .upcoming: return "UPCOMING"
            case .active: return "ACTIVE"
            case .completed: return "COMPLETED"
            }
        }
    }
    
    var body: some View {
        TappableCard(action: action) {
            HStack(spacing: AppSpacing.md) {
                // Phase indicator
                VStack {
                    Image(systemName: phase.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .frame(width: 56, height: 56)
                .background(phase.color)
                .cornerRadius(AppCornerRadius.medium)
                
                // Game info
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.heading4)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    // Phase badge
                    Text(phase.text)
                        .font(AppTypography.caption)
                        .foregroundColor(phase.color)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(phase.color.opacity(0.15))
                        .cornerRadius(AppCornerRadius.small)
                }
                
                Spacer()
                
                Image(systemName: AppIcons.chevronRight)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
}

// MARK: - Previews
struct AppCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Basic card
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Basic Card")
                            .font(AppTypography.heading3)
                        Text("This is a simple card with default styling")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                // Elevated card
                AppCard(elevation: .high) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Elevated Card")
                            .font(AppTypography.heading3)
                        Text("This card has higher elevation")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                // Tappable card
                TappableCard(action: {}) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Tappable Card")
                                .font(AppTypography.heading4)
                            Text("Tap to interact")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: AppIcons.chevronRight)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                // Section card with header
                SectionCard(
                    header: {
                        Text("Starting Lineup")
                            .font(AppTypography.heading4)
                    },
                    content: {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Player 1")
                            Text("Player 2")
                            Text("Player 3")
                        }
                        .font(AppTypography.bodyMedium)
                    },
                    footer: {
                        Text("7 players")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                )
                
                // Game cards
                GameCard(
                    title: "vs Red Dragons",
                    subtitle: "Saturday, 2:00 PM",
                    phase: .upcoming,
                    action: {}
                )
                
                GameCard(
                    title: "vs Blue Sharks",
                    subtitle: "In progress - Period 1",
                    phase: .active,
                    action: {}
                )
                
                GameCard(
                    title: "vs Green Lions",
                    subtitle: "Won 3-2",
                    phase: .completed,
                    action: {}
                )
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.background)
    }
}
