import Foundation
import SwiftUI
import Core
import Services

/// View model for authentication screens
@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var email = ""
    @Published public var password = ""
    @Published public var confirmPassword = ""
    @Published public var displayName = ""

    @Published public private(set) var isLoading = false
    @Published public var error: AuthError?
    @Published public var showError = false

    private let authService: AuthService

    public init(authService: AuthService = .shared) {
        self.authService = authService
    }

    // MARK: - Validation

    public var isLoginValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 8
    }

    public var isRegisterValid: Bool {
        isLoginValid && password == confirmPassword
    }

    // MARK: - Actions

    public func login() async {
        guard isLoginValid else {
            error = .invalidCredentials
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        // In mock mode, simulate successful login
        if AppConfiguration.useMockData {
            try? await Task.sleep(for: .milliseconds(500))
            authService.setMockAuthenticated(true)
            return
        }

        do {
            try await authService.login(email: email, password: password)
        } catch {
            self.error = .loginFailed(error)
            showError = true
        }
    }

    public func register() async {
        guard isRegisterValid else {
            error = .passwordMismatch
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        // In mock mode, simulate successful registration
        if AppConfiguration.useMockData {
            try? await Task.sleep(for: .milliseconds(500))
            authService.setMockAuthenticated(true)
            return
        }

        do {
            try await authService.register(
                email: email,
                password: password,
                displayName: displayName.isEmpty ? nil : displayName
            )
        } catch {
            self.error = .registrationFailed(error)
            showError = true
        }
    }

    public func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        error = nil
        showError = false
    }
}

// MARK: - Error Types

public enum AuthError: Error, LocalizedError, Identifiable {
    case invalidCredentials
    case passwordMismatch
    case loginFailed(Error)
    case registrationFailed(Error)

    public var id: String { localizedDescription }

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Please enter a valid email and password (8+ characters)"
        case .passwordMismatch:
            return "Passwords do not match"
        case .loginFailed(let error):
            return "Login failed: \(error.localizedDescription)"
        case .registrationFailed(let error):
            return "Registration failed: \(error.localizedDescription)"
        }
    }
}
