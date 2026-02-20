//
//  ThemePicker.swift
//  YouthSoccerApp
//
//  Theme selection interface - add this to your settings screen
//

import SwiftUI

struct ThemePicker: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingThemeSheet = false
    
    var body: some View {
        Button(action: { showingThemeSheet = true }) {
            HStack(spacing: AppSpacing.md) {
                // Theme preview circle
                Circle()
                    .fill(themeManager.colors.primary)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .fill(themeManager.colors.secondary)
                            .frame(width: 16, height: 16)
                            .offset(x: 8, y: 8)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Theme")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(themeManager.colors.textSecondary)
                    
                    Text(themeManager.currentTheme.name)
                        .font(AppTypography.labelLarge)
                        .foregroundColor(themeManager.colors.textPrimary)
                }
                
                Spacer()
                
                Image(systemName: AppIcons.chevronRight)
                    .foregroundColor(themeManager.colors.textTertiary)
            }
            .padding(AppSpacing.md)
            .background(themeManager.colors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingThemeSheet) {
            ThemeSelectionSheet()
        }
    }
}

// MARK: - Theme Selection Sheet
struct ThemeSelectionSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    ForEach(ThemeManager.availableThemes.indices, id: \.self) { index in
                        let theme = ThemeManager.availableThemes[index]
                        ThemePreviewCard(
                            theme: theme,
                            isSelected: theme.name == themeManager.currentTheme.name,
                            action: {
                                themeManager.setTheme(theme)
                                // Auto-dismiss after slight delay to show animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            }
                        )
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(themeManager.colors.background)
            .navigationTitle("Choose Theme")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.colors.primary)
                }
            }
        }
    }
}

// MARK: - Theme Preview Card
struct ThemePreviewCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.md) {
                // Theme name
                HStack {
                    Text(theme.name)
                        .font(AppTypography.heading4)
                        .foregroundColor(themeManager.colors.textPrimary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(themeManager.colors.primary)
                    }
                }
                
                // Color palette preview
                HStack(spacing: AppSpacing.sm) {
                    ColorSwatch(color: theme.primary, label: "Primary")
                    ColorSwatch(color: theme.secondary, label: "Secondary")
                    ColorSwatch(color: theme.accent, label: "Accent")
                    ColorSwatch(color: theme.success, label: "Success")
                }
                
                // UI Component Preview
                VStack(spacing: AppSpacing.sm) {
                    // Sample button
                    HStack {
                        sampleButton(color: theme.primary, text: "Primary")
                        sampleButton(color: theme.secondary, text: "Secondary")
                    }
                    
                    // Sample card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sample Card")
                                .font(AppTypography.labelMedium)
                                .foregroundColor(theme.textPrimary)
                            Text("Preview text")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(theme.textSecondary)
                        }
                        Spacer()
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 32, height: 32)
                    }
                    .padding(AppSpacing.sm)
                    .background(theme.surface)
                    .cornerRadius(AppCornerRadius.small)
                }
            }
            .padding(AppSpacing.md)
            .background(themeManager.colors.surface)
            .cornerRadius(AppCornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .stroke(
                        isSelected ? themeManager.colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
            .appShadow(isSelected ? .medium : .low)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func sampleButton(color: Color, text: String) -> some View {
        Text(text)
            .font(AppTypography.labelSmall)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(color)
            .cornerRadius(AppCornerRadius.small)
    }
}

// MARK: - Color Swatch
struct ColorSwatch: View {
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Quick Theme Switcher (for debug/testing)
struct QuickThemeSwitcher: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Menu {
            ForEach(ThemeManager.availableThemes.indices, id: \.self) { index in
                let theme = ThemeManager.availableThemes[index]
                Button(action: { themeManager.setTheme(theme) }) {
                    HStack {
                        Text(theme.name)
                        if theme.name == themeManager.currentTheme.name {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 20))
                .foregroundColor(themeManager.colors.primary)
        }
    }
}

// MARK: - Previews
struct ThemePicker_Previews: PreviewProvider {
    static var previews: some View {
        let themeManager = ThemeManager()
        
        return Group {
            // Theme picker button
            VStack {
                ThemePicker()
                    .padding()
            }
            .background(themeManager.colors.background)
            .environmentObject(themeManager)
            
            // Theme selection sheet
            ThemeSelectionSheet()
                .environmentObject(themeManager)
            
            // Quick switcher
            NavigationView {
                VStack {
                    Text("Sample Screen")
                        .font(AppTypography.heading1)
                }
                .navigationTitle("App")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        QuickThemeSwitcher()
                    }
                }
            }
            .environmentObject(themeManager)
        }
    }
}
