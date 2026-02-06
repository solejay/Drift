import Foundation
import SwiftUI
import Core
import Services

/// View model for linking bank accounts
@MainActor
public final class LinkAccountViewModel: ObservableObject {
    @Published public private(set) var accounts: [AccountDTO] = []
    @Published public private(set) var isLinking = false
    @Published public private(set) var isSyncing = false
    @Published public var error: LinkError?
    @Published public var showError = false

    private let plaidService: PlaidService

    public init(plaidService: PlaidService = .shared) {
        self.plaidService = plaidService
    }

    // MARK: - State

    public var hasLinkedAccounts: Bool {
        !accounts.isEmpty
    }

    // MARK: - Actions

    public func loadAccounts() async {
        do {
            try await plaidService.fetchAccounts()
            accounts = plaidService.linkedAccounts
        } catch {
            self.error = .fetchFailed(error)
            showError = true
        }
    }

    public func startLinking() async {
        isLinking = true
        defer { isLinking = false }

        do {
            try await plaidService.startLink()
            accounts = plaidService.linkedAccounts

            // Sync transactions after linking
            await syncTransactions()
        } catch {
            self.error = .linkFailed(error)
            showError = true
        }
    }

    public func syncTransactions() async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            try await plaidService.syncTransactions()
        } catch {
            self.error = .syncFailed(error)
            showError = true
        }
    }

    public func unlinkAccount(_ account: AccountDTO) async {
        do {
            try await plaidService.unlinkAccount(account.id)
            accounts.removeAll { $0.id == account.id }
        } catch {
            self.error = .unlinkFailed(error)
            showError = true
        }
    }
}

// MARK: - Error Types

public enum LinkError: Error, LocalizedError, Identifiable {
    case fetchFailed(Error)
    case linkFailed(Error)
    case syncFailed(Error)
    case unlinkFailed(Error)

    public var id: String { localizedDescription }

    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to load accounts: \(error.localizedDescription)"
        case .linkFailed(let error):
            return "Failed to link account: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Failed to sync transactions: \(error.localizedDescription)"
        case .unlinkFailed(let error):
            return "Failed to unlink account: \(error.localizedDescription)"
        }
    }
}
