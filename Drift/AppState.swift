import Foundation
import SwiftUI
import Combine
import Features
import Services
import Core

/// Global app state management
@MainActor
public final class AppState: ObservableObject {
    // MARK: - Shared Instance
    public static let shared = AppState()

    // MARK: - Published State
    @Published public var isAuthenticated = AppConfiguration.useMockData && !AppConfiguration.showOnboardingInMockMode
    @Published public var hasCompletedOnboarding = AppConfiguration.useMockData && !AppConfiguration.showOnboardingInMockMode
    @Published public var hasLinkedAccounts = AppConfiguration.useMockData
    @Published public var isLoading = !AppConfiguration.useMockData

    // MARK: - Services
    public let authService: AuthService
    public let plaidService: PlaidService
    public let transactionService: TransactionService
    public let summaryService: SummaryService

    // MARK: - Initialization

    private init() {
        self.authService = AuthService.shared
        self.plaidService = PlaidService.shared
        self.transactionService = TransactionService.shared
        self.summaryService = SummaryService.shared
    }

    // MARK: - Lifecycle

    /// Initialize app state on launch
    public func initialize() async {
        // When using mock data, skip initialization to show main app directly
        guard !AppConfiguration.useMockData else { return }

        isLoading = true
        defer { isLoading = false }

        // Restore authentication session
        await authService.restoreSession()
        isAuthenticated = authService.isAuthenticated

        // Check onboarding status — authenticated users have already onboarded
        hasCompletedOnboarding = isAuthenticated || UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        // Load linked accounts if authenticated
        if isAuthenticated {
            do {
                try await plaidService.fetchAccounts()
                hasLinkedAccounts = !plaidService.linkedAccounts.isEmpty
            } catch {
                // Ignore errors, user can link accounts later
            }
        }
    }

    /// Mark onboarding as complete
    public func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    /// Handle successful login/registration
    public func handleAuthentication() {
        isAuthenticated = true
    }

    /// Handle logout
    public func handleLogout() async {
        await authService.logout()
        isAuthenticated = false
        hasLinkedAccounts = false
    }
}
