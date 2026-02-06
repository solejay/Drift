import Foundation

/// A financial transaction
public struct Transaction: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let plaidTransactionId: String?
    public let accountId: UUID
    public let amount: Decimal
    public let date: Date
    public let merchantName: String
    public let category: SpendingCategory
    public let description: String?
    public let isPending: Bool
    public let isExcluded: Bool

    public init(
        id: UUID = UUID(),
        plaidTransactionId: String? = nil,
        accountId: UUID,
        amount: Decimal,
        date: Date,
        merchantName: String,
        category: SpendingCategory,
        description: String? = nil,
        isPending: Bool = false,
        isExcluded: Bool = false
    ) {
        self.id = id
        self.plaidTransactionId = plaidTransactionId
        self.accountId = accountId
        self.amount = amount
        self.date = date
        self.merchantName = merchantName
        self.category = category
        self.description = description
        self.isPending = isPending
        self.isExcluded = isExcluded
    }

    /// Returns true if this is an expense (positive amount in Plaid convention)
    public var isExpense: Bool {
        amount > 0
    }

    /// Formatted amount string with currency symbol
    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}
