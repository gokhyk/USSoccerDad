//
//  PlayerRow.swift
//  YouthSoccerApp
//
//  Reusable player row component for lists
//

import SwiftUI

struct PlayerRow: View {
    let name: String
    let jerseyNumber: Int
    var timeInGame: TimeInterval? = nil
    var seasonTime: TimeInterval? = nil
    var isOnField: Bool = false
    var isSelected: Bool = false
    var showCheckbox: Bool = false
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: AppSpacing.md) {
                // Checkbox (if needed)
                if showCheckbox {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? AppColors.primary : AppColors.textTertiary)
                }
                
                // Jersey number badge
                ZStack {
                    Circle()
                        .fill(jerseyColor)
                    
                    Text("\(jerseyNumber)")
                        .font(AppTypography.labelLarge)
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)
                
                // Player info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AppSpacing.sm) {
                        Text(name)
                            .font(AppTypography.bodyLarge)
                            .foregroundColor(AppColors.textPrimary)
                        
                        if isOnField {
                            Image(systemName: AppIcons.playerOnField)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.success)
                        }
                    }
                    
                    if let timeInGame = timeInGame {
                        HStack(spacing: AppSpacing.md) {
                            HStack(spacing: 4) {
                                Image(systemName: AppIcons.clock)
                                    .font(.system(size: 12))
                                Text(formatTime(timeInGame))
                            }
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                            
                            if let seasonTime = seasonTime {
                                HStack(spacing: 4) {
                                    Image(systemName: AppIcons.calendar)
                                        .font(.system(size: 12))
                                    Text("\(Int(seasonTime / 60)) min")
                                }
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textTertiary)
                            }
                        }
                    } else if let seasonTime = seasonTime {
                        HStack(spacing: 4) {
                            Image(systemName: AppIcons.calendar)
                                .font(.system(size: 12))
                            Text("Season: \(Int(seasonTime / 60)) min")
                        }
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Trailing indicator
                if onTap != nil && !showCheckbox {
                    Image(systemName: AppIcons.chevronRight)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.vertical, AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onTap == nil)
    }
    
    private var jerseyColor: Color {
        if isOnField {
            return AppColors.primary
        } else if isSelected {
            return AppColors.primaryLight
        } else {
            return AppColors.textSecondary
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Specialized Variants

/// Player row with percentage display
struct PlayerStatsRow: View {
    let name: String
    let jerseyNumber: Int
    let timeInGame: TimeInterval
    let totalGameTime: TimeInterval
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Jersey badge
            ZStack {
                Circle()
                    .fill(AppColors.textSecondary)
                
                Text("\(jerseyNumber)")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 40)
            
            // Name
            Text(name)
                .font(AppTypography.bodyLarge)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(timeInGame))
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(percentage)%")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
    
    private var percentage: Int {
        guard totalGameTime > 0 else { return 0 }
        return Int((timeInGame / totalGameTime) * 100)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

/// Substitution row showing IN/OUT
struct SubstitutionRow: View {
    let playerOut: String
    let jerseyOut: Int
    let playerIn: String
    let jerseyIn: Int
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Player OUT
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("OUT")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.error)
                
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(AppColors.error.opacity(0.2))
                        
                        Text("\(jerseyOut)")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.error)
                    }
                    .frame(width: 32, height: 32)
                    
                    Text(playerOut)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            
            // Arrow
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 20))
                .foregroundColor(AppColors.textTertiary)
            
            // Player IN
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("IN")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.success)
                
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(AppColors.success.opacity(0.2))
                        
                        Text("\(jerseyIn)")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.success)
                    }
                    .frame(width: 32, height: 32)
                    
                    Text(playerIn)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.surfaceElevated)
        .cornerRadius(AppCornerRadius.medium)
    }
}

// MARK: - Player List Container
struct PlayerList<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let content: Content
    
    init(title: String, 
         subtitle: String? = nil,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Player list
            VStack(spacing: 0) {
                content
            }
        }
    }
}

// MARK: - Previews
struct PlayerRow_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Basic player row
                AppCard(padding: 0) {
                    VStack(spacing: 0) {
                        PlayerRow(
                            name: "John Smith",
                            jerseyNumber: 10,
                            isOnField: true
                        )
                        .padding(.horizontal, AppSpacing.md)
                        
                        Divider()
                        
                        PlayerRow(
                            name: "Jane Doe",
                            jerseyNumber: 7,
                            isOnField: false
                        )
                        .padding(.horizontal, AppSpacing.md)
                    }
                }
                
                // With time information
                AppCard(padding: 0) {
                    VStack(spacing: 0) {
                        PlayerRow(
                            name: "Sarah Johnson",
                            jerseyNumber: 15,
                            timeInGame: 1234,
                            seasonTime: 3600,
                            isOnField: true
                        )
                        .padding(.horizontal, AppSpacing.md)
                        
                        Divider()
                        
                        PlayerRow(
                            name: "Mike Wilson",
                            jerseyNumber: 3,
                            timeInGame: 567,
                            seasonTime: 2400,
                            isOnField: false
                        )
                        .padding(.horizontal, AppSpacing.md)
                    }
                }
                
                // With checkboxes
                AppCard(padding: 0) {
                    VStack(spacing: 0) {
                        PlayerRow(
                            name: "Alex Brown",
                            jerseyNumber: 22,
                            isSelected: true,
                            showCheckbox: true,
                            onTap: {}
                        )
                        .padding(.horizontal, AppSpacing.md)
                        
                        Divider()
                        
                        PlayerRow(
                            name: "Emma Davis",
                            jerseyNumber: 9,
                            isSelected: false,
                            showCheckbox: true,
                            onTap: {}
                        )
                        .padding(.horizontal, AppSpacing.md)
                    }
                }
                
                // Stats rows
                AppCard {
                    VStack(spacing: AppSpacing.sm) {
                        Text("Playing Time")
                            .font(AppTypography.heading4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        PlayerStatsRow(
                            name: "John Smith",
                            jerseyNumber: 10,
                            timeInGame: 2700,
                            totalGameTime: 3000
                        )
                        
                        PlayerStatsRow(
                            name: "Jane Doe",
                            jerseyNumber: 7,
                            timeInGame: 1800,
                            totalGameTime: 3000
                        )
                    }
                }
                
                // Substitution row
                SubstitutionRow(
                    playerOut: "John Smith",
                    jerseyOut: 10,
                    playerIn: "Mike Wilson",
                    jerseyIn: 3
                )
                
                // Player list container
                PlayerList(
                    title: "Starting Lineup",
                    subtitle: "7 players on field"
                ) {
                    ForEach(1...7, id: \.self) { i in
                        PlayerRow(
                            name: "Player \(i)",
                            jerseyNumber: i,
                            timeInGame: Double(i * 100),
                            isOnField: true
                        )
                        .padding(.horizontal, AppSpacing.md)
                        
                        if i < 7 {
                            Divider()
                                .padding(.horizontal, AppSpacing.md)
                        }
                    }
                }
                .background(AppColors.surface)
                .cornerRadius(AppCornerRadius.large)
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.background)
    }
}
