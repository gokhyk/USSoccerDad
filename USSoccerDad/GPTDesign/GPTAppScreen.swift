//
//  GPTAppScreen.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 2/10/26.
//


import SwiftUI

struct GPTAppScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(GPTAppTheme.bg.ignoresSafeArea())
            .tint(GPTAppTheme.accent) // consistent accent across app
    }
}

extension View {
    func appScreen() -> some View { modifier(GPTAppScreen()) }
}
