import Foundation
import LocalAuthentication
import Core

/// Service for biometric authentication (Face ID / Touch ID)
@MainActor
public final class BiometricService: ObservableObject {
    public static let shared = BiometricService()

    @Published public private(set) var biometricType: BiometricType = .none
    @Published public private(set) var isAuthenticated = false

    private let keychain: KeychainService

    private static let biometricEnabledKey = "biometricAuthEnabled"

    public enum BiometricType {
        case none
        case touchID
        case faceID

        public var displayName: String {
            switch self {
            case .none: return "Biometrics"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            }
        }

        public var iconName: String {
            switch self {
            case .none: return "lock"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            }
        }
    }

    public init(keychain: KeychainService = .shared) {
        self.keychain = keychain
        checkBiometricAvailability()
    }

    // MARK: - Availability

    public func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }

        switch context.biometryType {
        case .faceID:
            biometricType = .faceID
        case .touchID:
            biometricType = .touchID
        default:
            biometricType = .none
        }
    }

    public var isAvailable: Bool {
        biometricType != .none
    }

    // MARK: - Enabled Preference

    public var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.biometricEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.biometricEnabledKey) }
    }

    // MARK: - Authentication

    public func authenticate() async -> Bool {
        guard isAvailable else { return true }

        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Drift to view your spending"
            )
            isAuthenticated = success
            return success
        } catch {
            isAuthenticated = false
            return false
        }
    }

    /// Enable biometric auth with a verification prompt
    public func enableWithVerification() async -> Bool {
        let success = await authenticate()
        if success {
            isEnabled = true
        }
        return success
    }

    public func disable() {
        isEnabled = false
        isAuthenticated = false
    }
}
