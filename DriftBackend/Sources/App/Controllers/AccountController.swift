import Vapor
import Fluent

struct AccountController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let accounts = routes.grouped("accounts")
        accounts.get(use: list)
        accounts.delete(":accountId", use: delete)
        accounts.put(":accountId", use: update)
    }

    // MARK: - List Accounts

    struct AccountListResponse: Content {
        let accounts: [AccountDTO]
    }

    func list(req: Request) async throws -> AccountListResponse {
        let userId = try req.userId

        let accounts = try await Account.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$isHidden == false)
            .all()

        return AccountListResponse(accounts: accounts.map { $0.toDTO() })
    }

    // MARK: - Delete Account

    func delete(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId
        guard let accountId = req.parameters.get("accountId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid account ID")
        }

        guard let account = try await Account.query(on: req.db)
            .filter(\.$id == accountId)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Account not found")
        }

        // Delete associated transactions
        try await Transaction.query(on: req.db)
            .filter(\.$account.$id == accountId)
            .delete()

        // Delete account
        try await account.delete(on: req.db)

        // If this was the last account for the PlaidItem, delete the PlaidItem too
        let remainingAccounts = try await Account.query(on: req.db)
            .filter(\.$plaidItem.$id == account.$plaidItem.id)
            .count()

        if remainingAccounts == 0 {
            try await PlaidItem.query(on: req.db)
                .filter(\.$id == account.$plaidItem.id)
                .delete()
        }

        return .ok
    }

    // MARK: - Update Account

    struct UpdateAccountRequest: Content {
        let isHidden: Bool?
    }

    func update(req: Request) async throws -> AccountDTO {
        let userId = try req.userId
        guard let accountId = req.parameters.get("accountId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid account ID")
        }

        guard let account = try await Account.query(on: req.db)
            .filter(\.$id == accountId)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Account not found")
        }

        let input = try req.content.decode(UpdateAccountRequest.self)

        if let isHidden = input.isHidden {
            account.isHidden = isHidden
        }

        try await account.save(on: req.db)

        return account.toDTO()
    }
}
