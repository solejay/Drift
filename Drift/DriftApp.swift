import SwiftUI
import UserNotifications
import Features
import Services
import Core
import UI

@main
struct DriftApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var biometricService = BiometricService.shared
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var isBiometricLocked = false

    private func loadRocketSimConnect() {
        #if DEBUG
        guard (Bundle(path: "/Applications/RocketSim.app/Contents/Frameworks/RocketSimConnectLinker.nocache.framework")?.load() == true) else {
            print("Failed to load linker framework")
            return
        }
        print("RocketSim Connect successfully linked")
        #endif
    }

    init() {
        loadRocketSimConnect()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isLoading {
                    LaunchView()
                } else if isBiometricLocked {
                    BiometricLockView {
                        Task {
                            let success = await biometricService.authenticate()
                            if success {
                                isBiometricLocked = false
                            }
                        }
                    }
                } else if !appState.hasCompletedOnboarding {
                    OnboardingView(isComplete: $appState.hasCompletedOnboarding)
                        .onChange(of: appState.hasCompletedOnboarding) { _, completed in
                            if completed {
                                appState.completeOnboarding()
                                requestNotificationPermission()
                            }
                        }
                } else if !appState.isAuthenticated {
                    LoginView()
                        .onReceive(appState.authService.$isAuthenticated) { isAuth in
                            appState.isAuthenticated = isAuth
                        }
                } else if !appState.hasLinkedAccounts {
                    LinkAccountView()
                        .onReceive(appState.plaidService.$linkedAccounts) { accounts in
                            appState.hasLinkedAccounts = !accounts.isEmpty
                        }
                } else {
                    ContentView()
                }
            }
            .task {
                checkBiometricLock()
                await appState.initialize()
            }
            .preferredColorScheme(preferredScheme)
        }
    }

    private var preferredScheme: ColorScheme? {
        switch appearanceMode {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }

    private func checkBiometricLock() {
        guard !AppConfiguration.useMockData else { return }
        guard biometricService.isEnabled else { return }
        isBiometricLocked = true
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}

// MARK: - App Delegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        guard !AppConfiguration.useMockData else { return }

        Task {
            await registerDeviceToken(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    private func registerDeviceToken(_ token: String) async {
        struct DeviceTokenRequest: Encodable {
            let token: String
            let platform: String
        }

        struct DeviceTokenResponse: Decodable {}

        let request = DeviceTokenRequest(token: token, platform: "ios")
        let api = APIClient.shared
        let _: DeviceTokenResponse? = try? await api.post("/api/v1/notifications/device-token", body: request)
    }
}

// MARK: - Launch View

private struct LaunchView: View {
    @State private var ripple1 = false
    @State private var ripple2 = false
    @State private var ripple3 = false
    @State private var showText = false
    @State private var showDrop = false

    var body: some View {
        ZStack {
            DriftBackground(animated: false)

            ZStack {
                // Ripple circles (concentric, expanding outward like a water drop)
                Circle()
                    .stroke(DriftPalette.accent.opacity(ripple3 ? 0 : 0.3), lineWidth: 2)
                    .frame(width: ripple3 ? 280 : 40, height: ripple3 ? 280 : 40)

                Circle()
                    .stroke(DriftPalette.accent.opacity(ripple2 ? 0 : 0.4), lineWidth: 2.5)
                    .frame(width: ripple2 ? 200 : 40, height: ripple2 ? 200 : 40)

                Circle()
                    .stroke(DriftPalette.accent.opacity(ripple1 ? 0.1 : 0.5), lineWidth: 3)
                    .frame(width: ripple1 ? 140 : 40, height: ripple1 ? 140 : 40)

                // Drop icon
                Image(systemName: "drop.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(DriftPalette.accent)
                    .scaleEffect(showDrop ? 1 : 0.3)
                    .opacity(showDrop ? 1 : 0)
            }
            .offset(y: -40)

            // Text and subtitle
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("Drift")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundStyle(DriftPalette.ink)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 12)

                Text("Reflecting...")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(DriftPalette.muted)
                    .opacity(showText ? 1 : 0)
            }
            .offset(y: 80)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showDrop = true
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                ripple1 = true
            }
            withAnimation(.easeOut(duration: 1.1).delay(0.4)) {
                ripple2 = true
            }
            withAnimation(.easeOut(duration: 1.2).delay(0.6)) {
                ripple3 = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showText = true
            }
        }
    }
}

// MARK: - Biometric Lock View

private struct BiometricLockView: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            DriftBackground(animated: false)

            VStack(spacing: DesignTokens.Spacing.xl) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(DriftPalette.accent)

                Text("Drift")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(DriftPalette.ink)

                Text("Unlock to view your spending")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(DriftPalette.muted)

                Button(action: onUnlock) {
                    Label("Unlock", systemImage: BiometricService.shared.biometricType.iconName)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminentPill)
                .padding(.horizontal, DesignTokens.Spacing.xl)
            }
        }
        .onAppear {
            onUnlock()
        }
    }
}
