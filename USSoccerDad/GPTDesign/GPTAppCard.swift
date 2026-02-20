//
//  AppCard.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 2/10/26.
//


import SwiftUI

struct GPTAppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(GPTAppTheme.pad)
            .background(GPTAppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: GPTAppTheme.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: GPTAppTheme.corner, style: .continuous)
                    .stroke(GPTAppTheme.separator.opacity(0.6), lineWidth: 1)
            )
    }
}

struct SectionHeader: View {
    let title: String
    let systemImage: String?

    init(_ title: String, systemImage: String? = nil) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(GPTAppTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 2)
    }
}

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(.headline)
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(
            LinearGradient(
                colors: [GPTAppTheme.accent, GPTAppTheme.accent.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: GPTAppTheme.corner, style: .continuous))
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let emphasized: Bool

    init(_ label: String, value: String, emphasized: Bool = false) {
        self.label = label
        self.value = value
        self.emphasized = emphasized
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(GPTAppTheme.textSecondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(emphasized ? .white : GPTAppTheme.text)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(emphasized ? GPTAppTheme.accent : GPTAppTheme.surface2)
        .clipShape(Capsule())
    }
}
