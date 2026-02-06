import Foundation

/// Categories for spending classification
public enum SpendingCategory: String, Codable, CaseIterable, Sendable {
    case food
    case transport
    case shopping
    case entertainment
    case subscriptions
    case utilities
    case health
    case income
    case transfer
    case other

    public var displayName: String {
        switch self {
        case .food: return "Food & Dining"
        case .transport: return "Transportation"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .subscriptions: return "Subscriptions"
        case .utilities: return "Utilities"
        case .health: return "Health"
        case .income: return "Income"
        case .transfer: return "Transfer"
        case .other: return "Other"
        }
    }

    public var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car"
        case .shopping: return "bag"
        case .entertainment: return "tv"
        case .subscriptions: return "repeat"
        case .utilities: return "bolt"
        case .health: return "heart"
        case .income: return "arrow.down.circle"
        case .transfer: return "arrow.left.arrow.right"
        case .other: return "ellipsis.circle"
        }
    }

    public var color: String {
        switch self {
        case .food: return "orange"
        case .transport: return "blue"
        case .shopping: return "pink"
        case .entertainment: return "purple"
        case .subscriptions: return "red"
        case .utilities: return "yellow"
        case .health: return "green"
        case .income: return "mint"
        case .transfer: return "gray"
        case .other: return "secondary"
        }
    }

    /// Map from Plaid category to SpendingCategory
    public static func from(plaidCategory: String) -> SpendingCategory {
        let lowercased = plaidCategory.lowercased()

        if lowercased.contains("food") || lowercased.contains("restaurant") || lowercased.contains("coffee") || lowercased.contains("dining") {
            return .food
        } else if lowercased.contains("travel") || lowercased.contains("transport") || lowercased.contains("uber") || lowercased.contains("lyft") || lowercased.contains("gas") {
            return .transport
        } else if lowercased.contains("shop") || lowercased.contains("retail") || lowercased.contains("amazon") || lowercased.contains("store") {
            return .shopping
        } else if lowercased.contains("entertainment") || lowercased.contains("recreation") || lowercased.contains("movie") || lowercased.contains("game") {
            return .entertainment
        } else if lowercased.contains("subscription") || lowercased.contains("netflix") || lowercased.contains("spotify") || lowercased.contains("recurring") {
            return .subscriptions
        } else if lowercased.contains("utility") || lowercased.contains("electric") || lowercased.contains("water") || lowercased.contains("internet") || lowercased.contains("phone") {
            return .utilities
        } else if lowercased.contains("health") || lowercased.contains("medical") || lowercased.contains("pharmacy") || lowercased.contains("doctor") {
            return .health
        } else if lowercased.contains("income") || lowercased.contains("payroll") || lowercased.contains("deposit") {
            return .income
        } else if lowercased.contains("transfer") || lowercased.contains("payment") {
            return .transfer
        } else {
            return .other
        }
    }
}
