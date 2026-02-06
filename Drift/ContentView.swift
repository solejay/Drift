import SwiftUI
import UIKit
import Features
import UI
import Services
import Core

/// Main content view with tab navigation
public struct ContentView: View {
    @ObservedObject private var appState = AppState.shared
    @State private var selectedTab = 0

    public init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(white: 0.08, alpha: 0.7)
            }
            return UIColor(white: 1.0, alpha: 0.65)
        }

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(DriftPalette.muted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(DriftPalette.muted)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DriftPalette.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(DriftPalette.accent)
        ]

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Unified Spending View (replaces Today, Week, Month tabs)
            NavigationStack {
                SpendingView()
            }
            .tabItem {
                Label("Spending", systemImage: "chart.bar")
            }
            .tag(0)

            // Leaky Buckets
            NavigationStack {
                LeakyBucketsView()
            }
            .tabItem {
                Label("Leaks", systemImage: "drop")
            }
            .tag(1)

            // Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
        .environment(\.symbolVariants, .none)
        .tint(DriftPalette.accent)
        .onChange(of: selectedTab) { _, _ in
            HapticManager.selection()
        }
    }
}

#Preview {
    ContentView()
}
