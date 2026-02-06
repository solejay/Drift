import Foundation

// MARK: - Transaction DTOs

public struct TransactionDTO: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let accountId: UUID
    public let plaidTransactionId: String?
    public let amount: Decimal
    public let date: Date
    public let merchantName: String
    public let category: String
    public let description: String?
    public let isPending: Bool
    public let isExcluded: Bool

    public init(
        id: UUID,
        accountId: UUID,
        plaidTransactionId: String? = nil,
        amount: Decimal,
        date: Date,
        merchantName: String,
        category: String,
        description: String? = nil,
        isPending: Bool = false,
        isExcluded: Bool = false
    ) {
        self.id = id
        self.accountId = accountId
        self.plaidTransactionId = plaidTransactionId
        self.amount = amount
        self.date = date
        self.merchantName = merchantName
        self.category = category
        self.description = description
        self.isPending = isPending
        self.isExcluded = isExcluded
    }
}

public struct TransactionListRequest: Codable, Sendable {
    public let startDate: Date?
    public let endDate: Date?
    public let accountIds: [UUID]?
    public let categories: [String]?
    public let page: Int
    public let perPage: Int

    public init(
        startDate: Date? = nil,
        endDate: Date? = nil,
        accountIds: [UUID]? = nil,
        categories: [String]? = nil,
        page: Int = 1,
        perPage: Int = 50
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.accountIds = accountIds
        self.categories = categories
        self.page = page
        self.perPage = perPage
    }
}

public struct TransactionListResponse: Codable, Sendable {
    public let transactions: [TransactionDTO]
    public let total: Int
    public let page: Int
    public let perPage: Int
    public let hasMore: Bool

    public init(
        transactions: [TransactionDTO],
        total: Int,
        page: Int,
        perPage: Int,
        hasMore: Bool
    ) {
        self.transactions = transactions
        self.total = total
        self.page = page
        self.perPage = perPage
        self.hasMore = hasMore
    }
}

public struct UpdateTransactionRequest: Codable, Sendable {
    public let category: String?
    public let isExcluded: Bool?

    public init(category: String? = nil, isExcluded: Bool? = nil) {
        self.category = category
        self.isExcluded = isExcluded
    }
}

// MARK: - Account DTOs

public struct AccountDTO: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let plaidAccountId: String?
    public let name: String
    public let officialName: String?
    public let type: String
    public let mask: String?
    public let currentBalance: Decimal?
    public let availableBalance: Decimal?
    public let institutionName: String?
    public let isHidden: Bool

    public init(
        id: UUID,
        plaidAccountId: String? = nil,
        name: String,
        officialName: String? = nil,
        type: String,
        mask: String? = nil,
        currentBalance: Decimal? = nil,
        availableBalance: Decimal? = nil,
        institutionName: String? = nil,
        isHidden: Bool = false
    ) {
        self.id = id
        self.plaidAccountId = plaidAccountId
        self.name = name
        self.officialName = officialName
        self.type = type
        self.mask = mask
        self.currentBalance = currentBalance
        self.availableBalance = availableBalance
        self.institutionName = institutionName
        self.isHidden = isHidden
    }
}

public struct AccountListResponse: Codable, Sendable {
    public let accounts: [AccountDTO]

    public init(accounts: [AccountDTO]) {
        self.accounts = accounts
    }
}
