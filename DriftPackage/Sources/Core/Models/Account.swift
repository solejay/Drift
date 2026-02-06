import Foundation

/// Account type classification
public enum AccountType: String, Codable, Sendable, CaseIterable {
    case checking
    case savings
    case credit
    case investment
    case loan
    case other

    public var displayName: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .credit: return "Credit Card"
        case .investment: return "Investment"
        case .loan: return "Loan"
        case .other: return "Other"
        }
    }

    public var iconName: String {
        switch self {
        case .checking: return "banknote"
        case .savings: return "building.columns"
        case .credit: return "creditcard"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .loan: return "doc.text"
        case .other: return "ellipsis.circle"
        }
    }
}

/// A linked bank account
public struct Account: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let plaidAccountId: String?
    public let plaidItemId: UUID?
    public let name: String
    public let officialName: String?
    public let type: AccountType
    public let mask: String?
    public let currentBalance: Decimal?
    public let availableBalance: Decimal?
    public let institutionName: String?
    public let isHidden: Bool

    public init(
        id: UUID = UUID(),
        plaidAccountId: String? = nil,
        plaidItemId: UUID? = nil,
        name: String,
        officialName: String? = nil,
        type: AccountType,
        mask: String? = nil,
        currentBalance: Decimal? = nil,
        availableBalance: Decimal? = nil,
        institutionName: String? = nil,
        isHidden: Bool = false
    ) {
        self.id = id
        self.plaidAccountId = plaidAccountId
        self.plaidItemId = plaidItemId
        self.name = name
        self.officialName = officialName
        self.type = type
        self.mask = mask
        self.currentBalance = currentBalance
        self.availableBalance = availableBalance
        self.institutionName = institutionName
        self.isHidden = isHidden
    }

    /// Display name with mask suffix
    public var displayName: String {
        if let mask = mask {
            return "\(name) (\(mask))"
        }
        return name
    }

    /// Formatted balance string
    public var formattedBalance: String? {
        guard let balance = currentBalance else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: balance as NSDecimalNumber)
    }
}
