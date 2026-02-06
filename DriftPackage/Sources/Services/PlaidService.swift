import Foundation
import LinkKit
import Core

/// Service for Plaid Link integration
@MainActor
public final class PlaidService: ObservableObject {
    public static let shared = PlaidService()

    @Published public private(set) var isLinking = false
    @Published public private(set) var linkedAccounts: [AccountDTO] = []
    @Published public private(set) var error: PlaidError?

    private let api: APIClient
    private var linkHandler: Handler?

    public init(api: APIClient = .shared) {
        self.api = api
    }

    // MARK: - Link Token

    /// Create a link token for starting Plaid Link
    public func createLinkToken() async throws -> String {
        struct LinkTokenResponse: Decodable {
            let linkToken: String
        }

        let response: LinkTokenResponse = try await api.post("/api/v1/plaid/link-token")
        return response.linkToken
    }

    // MARK: - Start Plaid Link

    /// Start the Plaid Link flow
    public func startLink() async throws {
        isLinking = true
        error = nil

        do {
            let linkToken = try await createLinkToken()
            try await presentLink(with: linkToken)
        } catch {
            isLinking = false
            self.error = .linkTokenFailed(error)
            throw error
        }
    }

    private func presentLink(with linkToken: String) async throws {
        let config = try createLinkConfiguration(linkToken: linkToken)

        return try await withCheckedThrowingContinuation { continuation in
            let result = Plaid.create(config)

            switch result {
            case .success(let handler):
                self.linkHandler = handler
                handler.open(presentUsing: .viewController(UIViewController.topMost()))
                // Continuation will be resumed in onSuccess/onExit callbacks
                // Store continuation for later use
                self.linkContinuation = continuation

            case .failure(let error):
                continuation.resume(throwing: PlaidError.createFailed(error))
            }
        }
    }

    private var linkContinuation: CheckedContinuation<Void, Error>?

    private func createLinkConfiguration(linkToken: String) throws -> LinkTokenConfiguration {
        var config = LinkTokenConfiguration(token: linkToken) { [weak self] result in
            Task { @MainActor in
                self?.handleLinkSuccess(result)
            }
        }

        config.onExit = { [weak self] exit in
            Task { @MainActor in
                self?.handleLinkExit(exit)
            }
        }

        return config
    }

    private func handleLinkSuccess(_ result: LinkSuccess) {
        Task {
            do {
                try await exchangePublicToken(result.publicToken)
                linkContinuation?.resume()
                linkContinuation = nil
            } catch {
                linkContinuation?.resume(throwing: error)
                linkContinuation = nil
            }
            isLinking = false
        }
    }

    private func handleLinkExit(_ exit: LinkExit) {
        isLinking = false

        if let plaidError = exit.error {
            error = .linkExitError(plaidError.displayMessage ?? "Link was cancelled")
            linkContinuation?.resume(throwing: self.error!)
        } else {
            // User cancelled
            linkContinuation?.resume(throwing: PlaidError.userCancelled)
        }
        linkContinuation = nil
    }

    // MARK: - Exchange Token

    private func exchangePublicToken(_ publicToken: String) async throws {
        struct ExchangeRequest: Encodable {
            let publicToken: String
        }

        struct ExchangeResponse: Decodable {
            let accounts: [AccountDTO]
        }

        let request = ExchangeRequest(publicToken: publicToken)
        let response: ExchangeResponse = try await api.post("/api/v1/plaid/exchange", body: request)

        linkedAccounts.append(contentsOf: response.accounts)
    }

    // MARK: - Sync Transactions

    /// Trigger a transaction sync for all linked accounts
    public func syncTransactions() async throws {
        struct SyncResponse: Decodable {
            let added: Int
            let modified: Int
            let removed: Int
        }

        let _: SyncResponse = try await api.post("/api/v1/plaid/sync")
    }

    // MARK: - Fetch Accounts

    public func fetchAccounts() async throws {
        let response: AccountListResponse = try await api.get("/api/v1/accounts")
        linkedAccounts = response.accounts
    }

    // MARK: - Unlink Account

    public func unlinkAccount(_ accountId: UUID) async throws {
        try await api.delete("/api/v1/accounts/\(accountId.uuidString)")
        linkedAccounts.removeAll { $0.id == accountId }
    }
}

// MARK: - Errors

public enum PlaidError: Error, LocalizedError {
    case linkTokenFailed(Error)
    case createFailed(Error)
    case linkExitError(String)
    case userCancelled
    case exchangeFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .linkTokenFailed(let error):
            return "Failed to create link token: \(error.localizedDescription)"
        case .createFailed(let error):
            return "Failed to create Plaid Link: \(error.localizedDescription)"
        case .linkExitError(let message):
            return message
        case .userCancelled:
            return "Link was cancelled"
        case .exchangeFailed(let error):
            return "Failed to link account: \(error.localizedDescription)"
        }
    }
}

// MARK: - UIViewController Extension

import UIKit

extension UIViewController {
    static func topMost() -> UIViewController {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              var topController = window.rootViewController else {
            fatalError("No key window found")
        }

        while let presented = topController.presentedViewController {
            topController = presented
        }

        return topController
    }
}
