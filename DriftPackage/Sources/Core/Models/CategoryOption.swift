import Foundation

/// Leaky bucket category options, shared between onboarding and settings
public enum CategoryOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case foodDelivery
    case coffee
    case amazon
    case dining
    case rideshare
    case subscriptions
    case fastFood
    case alcohol
    case shopping

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .foodDelivery: return "Food Delivery"
        case .coffee: return "Coffee"
        case .amazon: return "Amazon"
        case .dining: return "Dining"
        case .rideshare: return "Rideshare"
        case .subscriptions: return "Subscriptions"
        case .fastFood: return "Fast Food"
        case .alcohol: return "Alcohol"
        case .shopping: return "Shopping"
        }
    }

    public var icon: String {
        switch self {
        case .foodDelivery: return "fork.knife"
        case .coffee: return "cup.and.saucer"
        case .amazon: return "cart"
        case .dining: return "wineglass"
        case .rideshare: return "car"
        case .subscriptions: return "play.rectangle"
        case .fastFood: return "takeoutbag.and.cup.and.straw"
        case .alcohol: return "wineglass.fill"
        case .shopping: return "bag"
        }
    }

    public var exampleMerchants: [String] {
        switch self {
        case .foodDelivery: return ["Uber Eats", "DoorDash", "Grubhub"]
        case .coffee: return ["Starbucks", "Dunkin'", "Peet's"]
        case .amazon: return ["Amazon", "Whole Foods", "Amazon Fresh"]
        case .dining: return ["Chipotle", "Sweetgreen", "Local spots"]
        case .rideshare: return ["Uber", "Lyft", "Via"]
        case .subscriptions: return ["Netflix", "Spotify", "Apple TV+"]
        case .fastFood: return ["McDonald's", "Chick-fil-A", "Wendy's"]
        case .alcohol: return ["Bars", "Total Wine", "Drizly"]
        case .shopping: return ["Target", "Walmart", "Best Buy"]
        }
    }

    // MARK: - UserDefaults Persistence

    private static let selectedCategoriesKey = "selectedLeakyBucketCategories"

    public static func loadSelected() -> [CategoryOption] {
        guard let rawValues = UserDefaults.standard.stringArray(forKey: selectedCategoriesKey) else {
            return [.foodDelivery, .coffee]
        }
        return rawValues.compactMap { CategoryOption(rawValue: $0) }
    }

    public static func saveSelected(_ categories: [CategoryOption]) {
        let rawValues = categories.map(\.rawValue)
        UserDefaults.standard.set(rawValues, forKey: selectedCategoriesKey)
    }
}
