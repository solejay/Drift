import Vapor
import Fluent

struct TransactionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let transactions = routes.grouped("transactions")
        transactions.get(use: list)
        transactions.put(":transactionId", use: update)
    }

    // MARK: - List Transactions

    struct TransactionListResponse: Content {
        let transactions: [TransactionDTO]
        let total: Int
        let page: Int
        let perPage: Int
        let hasMore: Bool
    }

    func list(req: Request) async throws -> TransactionListResponse {
        let userId = try req.userId

        // Parse query parameters
        let page = (try? req.query.get(Int.self, at: "page")) ?? 1
        let perPage = min((try? req.query.get(Int.self, at: "perPage")) ?? 50, 100)
        let startDate = try? req.query.get(Date.self, at: "startDate")
        let endDate = try? req.query.get(Date.self, at: "endDate")
        let accountIdsString = try? req.query.get(String.self, at: "accountIds")
        let categoriesString = try? req.query.get(String.self, at: "categories")

        var query = Transaction.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$isExcluded == false)

        // Apply filters
        if let startDate {
            query = query.filter(\.$date >= startDate)
        }

        if let endDate {
            query = query.filter(\.$date <= endDate)
        }

        if let accountIdsString {
            let accountIds = accountIdsString.split(separator: ",").compactMap { UUID(uuidString: String($0)) }
            if !accountIds.isEmpty {
                query = query.filter(\.$account.$id ~~ accountIds)
            }
        }

        if let categoriesString {
            let categories = categoriesString.split(separator: ",").map { String($0) }
            if !categories.isEmpty {
                query = query.filter(\.$category ~~ categories)
            }
        }

        // Get total count
        let total = try await query.count()

        // Apply pagination and ordering
        let transactions = try await query
            .sort(\.$date, .descending)
            .offset((page - 1) * perPage)
            .limit(perPage)
            .all()

        let hasMore = (page * perPage) < total

        return TransactionListResponse(
            transactions: transactions.map { $0.toDTO() },
            total: total,
            page: page,
            perPage: perPage,
            hasMore: hasMore
        )
    }

    // MARK: - Update Transaction

    struct UpdateTransactionRequest: Content {
        let category: String?
        let isExcluded: Bool?
    }

    func update(req: Request) async throws -> TransactionDTO {
        let userId = try req.userId
        guard let transactionId = req.parameters.get("transactionId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid transaction ID")
        }

        guard let transaction = try await Transaction.query(on: req.db)
            .filter(\.$id == transactionId)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Transaction not found")
        }

        let input = try req.content.decode(UpdateTransactionRequest.self)

        if let category = input.category {
            guard InputValidation.isValidCategory(category) else {
                throw Abort(.badRequest, reason: "Invalid category. Allowed: \(InputValidation.validCategories.sorted().joined(separator: ", "))")
            }
            transaction.category = category.lowercased()
        }

        if let isExcluded = input.isExcluded {
            transaction.isExcluded = isExcluded
        }

        try await transaction.save(on: req.db)

        return transaction.toDTO()
    }
}
