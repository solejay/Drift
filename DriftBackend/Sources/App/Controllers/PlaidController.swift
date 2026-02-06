import Vapor
import Fluent

struct PlaidController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let plaid = routes.grouped("plaid")
        plaid.post("link-token", use: createLinkToken)
        plaid.post("exchange", use: exchangeToken)
        plaid.post("sync", use: syncTransactions)
    }

    // MARK: - Webhook (registered separately as unprotected route)

    @Sendable static func webhookHandler(req: Request) async throws -> HTTPStatus {
        // Verify webhook - reject requests without Plaid-Verification header
        // In production, implement full JWT signature verification per Plaid docs:
        // https://plaid.com/docs/api/webhooks/webhook-verification/
        guard req.headers.first(name: "Plaid-Verification") != nil else {
            req.logger.warning("Plaid webhook rejected: missing Plaid-Verification header")
            throw Abort(.unauthorized, reason: "Missing webhook verification")
        }

        let webhook = try req.content.decode(PlaidWebhookRequest.self)

        req.logger.info("Plaid webhook received: \(webhook.webhookType) - \(webhook.webhookCode)")

        switch webhook.webhookType {
        case "TRANSACTIONS":
            switch webhook.webhookCode {
            case "SYNC_UPDATES_AVAILABLE", "DEFAULT_UPDATE":
                guard let itemId = webhook.itemId else {
                    req.logger.error("Plaid webhook missing item_id for transaction event")
                    return .ok
                }

                // Find the PlaidItem and trigger sync
                guard let plaidItem = try await PlaidItem.query(on: req.db)
                    .filter(\.$plaidItemId == itemId)
                    .first() else {
                    req.logger.warning("Plaid webhook: item not found for item_id \(itemId)")
                    return .ok
                }

                let controller = PlaidController()
                _ = try await controller.syncTransactionsForItem(plaidItem, on: req)
                req.logger.info("Plaid webhook: synced transactions for item \(itemId)")
            default:
                req.logger.info("Plaid webhook: unhandled TRANSACTIONS code \(webhook.webhookCode)")
            }

        case "ITEM":
            switch webhook.webhookCode {
            case "ERROR":
                req.logger.error("Plaid webhook: item error for item_id \(webhook.itemId ?? "unknown") - \(webhook.error?.errorMessage ?? "no message")")
            case "PENDING_EXPIRATION":
                req.logger.warning("Plaid webhook: pending expiration for item_id \(webhook.itemId ?? "unknown")")
            default:
                req.logger.info("Plaid webhook: unhandled ITEM code \(webhook.webhookCode)")
            }

        default:
            req.logger.info("Plaid webhook: unhandled type \(webhook.webhookType)")
        }

        return .ok
    }

    // MARK: - Create Link Token

    struct LinkTokenResponse: Content {
        let linkToken: String
    }

    func createLinkToken(req: Request) async throws -> LinkTokenResponse {
        let userId = try req.userId
        let plaidService = PlaidAPIService(client: req.client)

        let linkToken = try await plaidService.createLinkToken(userId: userId)

        return LinkTokenResponse(linkToken: linkToken)
    }

    // MARK: - Exchange Token

    struct ExchangeRequest: Content {
        let publicToken: String
    }

    struct ExchangeResponse: Content {
        let accounts: [AccountDTO]
    }

    func exchangeToken(req: Request) async throws -> ExchangeResponse {
        let userId = try req.userId
        let input = try req.content.decode(ExchangeRequest.self)
        let plaidService = PlaidAPIService(client: req.client)

        // Exchange public token for access token
        let exchangeResult = try await plaidService.exchangePublicToken(input.publicToken)

        // Get accounts
        let plaidAccounts = try await plaidService.getAccounts(accessToken: exchangeResult.accessToken)

        // Create PlaidItem
        let plaidItem = PlaidItem(
            userID: userId,
            plaidItemId: exchangeResult.itemId,
            accessToken: exchangeResult.accessToken
        )
        try await plaidItem.save(on: req.db)

        guard let plaidItemId = plaidItem.id else {
            throw Abort(.internalServerError, reason: "Failed to save Plaid item")
        }

        // Create accounts
        var accountDTOs: [AccountDTO] = []
        for plaidAccount in plaidAccounts {
            let account = Account(
                plaidItemID: plaidItemId,
                userID: userId,
                plaidAccountId: plaidAccount.account_id,
                name: plaidAccount.name,
                officialName: plaidAccount.official_name,
                type: plaidAccount.type,
                subtype: plaidAccount.subtype,
                mask: plaidAccount.mask,
                currentBalance: plaidAccount.balances.current.map { Decimal($0) },
                availableBalance: plaidAccount.balances.available.map { Decimal($0) }
            )
            try await account.save(on: req.db)
            accountDTOs.append(account.toDTO())
        }

        // Trigger initial transaction sync
        _ = try await syncTransactionsForItem(plaidItem, on: req)

        return ExchangeResponse(accounts: accountDTOs)
    }

    // MARK: - Sync Transactions

    struct SyncResponse: Content {
        let added: Int
        let modified: Int
        let removed: Int
    }

    func syncTransactions(req: Request) async throws -> SyncResponse {
        let userId = try req.userId

        // Get all Plaid items for user
        let plaidItems = try await PlaidItem.query(on: req.db)
            .filter(\.$user.$id == userId)
            .all()

        var totalAdded = 0
        var totalModified = 0
        var totalRemoved = 0

        for item in plaidItems {
            let result = try await syncTransactionsForItem(item, on: req)
            totalAdded += result.added
            totalModified += result.modified
            totalRemoved += result.removed
        }

        return SyncResponse(added: totalAdded, modified: totalModified, removed: totalRemoved)
    }

    // MARK: - Helpers

    func syncTransactionsForItem(_ item: PlaidItem, on req: Request) async throws -> (added: Int, modified: Int, removed: Int) {
        let plaidService = PlaidAPIService(client: req.client)
        var hasMore = true
        var cursor = item.cursor
        var totalAdded = 0
        var totalModified = 0
        var totalRemoved = 0

        guard let itemId = item.id else { return (0, 0, 0) }

        // Get account ID map
        let accounts = try await Account.query(on: req.db)
            .filter(\.$plaidItem.$id == itemId)
            .all()
        let accountMap = Dictionary(uniqueKeysWithValues: accounts.map { ($0.plaidAccountId, $0) })

        while hasMore {
            let result = try await plaidService.syncTransactions(accessToken: item.accessToken, cursor: cursor)

            // Process added transactions
            for plaidTxn in result.added {
                guard let account = accountMap[plaidTxn.account_id] else { continue }

                guard let accountId = account.id else { continue }

                let transaction = Transaction(
                    accountID: accountId,
                    userID: item.$user.id,
                    plaidTransactionId: plaidTxn.transaction_id,
                    amount: Decimal(plaidTxn.amount),
                    date: parseDate(plaidTxn.date) ?? Date(),
                    merchantName: plaidTxn.merchant_name ?? plaidTxn.name,
                    category: plaidTxn.category?.first ?? "other",
                    isPending: plaidTxn.pending
                )
                try await transaction.save(on: req.db)
                totalAdded += 1
            }

            // Process modified transactions
            for plaidTxn in result.modified {
                guard let existing = try await Transaction.query(on: req.db)
                    .filter(\.$plaidTransactionId == plaidTxn.transaction_id)
                    .first() else { continue }

                existing.amount = Decimal(plaidTxn.amount)
                existing.date = parseDate(plaidTxn.date) ?? existing.date
                existing.merchantName = plaidTxn.merchant_name ?? plaidTxn.name
                existing.category = plaidTxn.category?.first ?? existing.category
                existing.isPending = plaidTxn.pending

                try await existing.save(on: req.db)
                totalModified += 1
            }

            // Process removed transactions
            for txnId in result.removed {
                try await Transaction.query(on: req.db)
                    .filter(\.$plaidTransactionId == txnId)
                    .delete()
                totalRemoved += 1
            }

            cursor = result.nextCursor
            hasMore = result.hasMore
        }

        // Update cursor
        item.cursor = cursor
        try await item.save(on: req.db)

        return (totalAdded, totalModified, totalRemoved)
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: string)
    }
}

// MARK: - Webhook DTOs

struct PlaidWebhookRequest: Content {
    let webhookType: String
    let webhookCode: String
    let itemId: String?
    let error: PlaidWebhookError?

    enum CodingKeys: String, CodingKey {
        case webhookType = "webhook_type"
        case webhookCode = "webhook_code"
        case itemId = "item_id"
        case error
    }
}

struct PlaidWebhookError: Content {
    let errorType: String?
    let errorCode: String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case errorType = "error_type"
        case errorCode = "error_code"
        case errorMessage = "error_message"
    }
}
