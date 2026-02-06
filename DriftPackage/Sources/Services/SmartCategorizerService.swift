import Foundation
import Core

/// Result of transaction categorization
public struct CategoryResult: Sendable {
    public let category: String
    public let confidence: Int
    public let isRecurring: Bool

    public init(category: String, confidence: Int, isRecurring: Bool) {
        self.category = category
        self.confidence = confidence
        self.isRecurring = isRecurring
    }
}

/// Error types for categorization
public enum SmartCategorizerError: Error, LocalizedError {
    case modelUnavailable
    case categorizationFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "On-device language model is not available"
        case .categorizationFailed(let error):
            return "Categorization failed: \(error.localizedDescription)"
        }
    }
}

/// Service for smart transaction categorization using on-device LLM
/// Note: Full Foundation Models implementation requires iOS 26+
public actor SmartCategorizerService {
    public static let shared = SmartCategorizerService()

    private init() {}

    /// Check if the service is available (requires iOS 26+ with Foundation Models)
    public var isAvailable: Bool {
        // Foundation Models availability check
        // In production, this would check SystemLanguageModel.default.availability
        #if swift(>=6.0)
        // Placeholder for iOS 26 Foundation Models check
        return false
        #else
        return false
        #endif
    }

    /// Categorize a single transaction
    public func categorize(
        merchantName: String,
        amount: Decimal,
        description: String?
    ) async throws -> CategoryResult {
        // When Foundation Models is not available, fall back to rule-based categorization
        guard isAvailable else {
            return fallbackCategorize(merchantName: merchantName, amount: amount, description: description)
        }

        // iOS 26 Foundation Models implementation would go here:
        /*
        let session = LanguageModelSession(instructions: """
            You are a spending categorizer. Given a transaction, determine:
            1. The category (food, transport, shopping, entertainment, subscriptions, utilities, health, other)
            2. Your confidence level (0-100)
            3. Whether this looks like a recurring expense

            Be concise and accurate.
            """)

        let prompt = """
            Merchant: \(merchantName)
            Amount: $\(amount)
            \(description.map { "Description: \($0)" } ?? "")
            """

        let response = try await session.respond(
            to: prompt,
            generating: CategoryResult.self
        )

        return response.content
        */

        return fallbackCategorize(merchantName: merchantName, amount: amount, description: description)
    }

    /// Batch categorize transactions with streaming updates
    public func categorizeTransactions(
        _ transactions: [TransactionDTO]
    ) -> AsyncThrowingStream<(TransactionDTO, CategoryResult), Error> {
        AsyncThrowingStream { continuation in
            Task {
                for transaction in transactions {
                    do {
                        let result = try await categorize(
                            merchantName: transaction.merchantName,
                            amount: transaction.amount,
                            description: transaction.description
                        )
                        continuation.yield((transaction, result))
                    } catch {
                        continuation.finish(throwing: error)
                        return
                    }
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Fallback Categorization

    private func fallbackCategorize(
        merchantName: String,
        amount: Decimal,
        description: String?
    ) -> CategoryResult {
        let combined = "\(merchantName) \(description ?? "")".lowercased()

        // Rule-based categorization
        let category: String
        let confidence: Int
        var isRecurring = false

        // Food & Dining
        let foodKeywords = ["starbucks", "mcdonald", "chipotle", "uber eats", "doordash", "grubhub",
                           "restaurant", "cafe", "coffee", "pizza", "burger", "sushi", "taco"]
        if foodKeywords.contains(where: { combined.contains($0) }) {
            category = "food"
            confidence = 85

            // Check for recurring patterns
            if ["starbucks", "coffee"].contains(where: { combined.contains($0) }) {
                isRecurring = amount < 20
            }
        }
        // Transportation
        else if ["uber", "lyft", "taxi", "gas", "shell", "chevron", "exxon", "bp ", "parking", "metro", "transit"]
            .contains(where: { combined.contains($0) }) {
            category = "transport"
            confidence = 85
        }
        // Subscriptions
        else if ["netflix", "spotify", "hulu", "disney+", "hbo", "apple music", "youtube premium",
                "subscription", "monthly", "membership", "amazon prime"].contains(where: { combined.contains($0) }) {
            category = "subscriptions"
            confidence = 95
            isRecurring = true
        }
        // Shopping
        else if ["amazon", "target", "walmart", "costco", "best buy", "apple store", "nike", "nordstrom"]
            .contains(where: { combined.contains($0) }) {
            category = "shopping"
            confidence = 80
        }
        // Entertainment
        else if ["amc", "cinema", "theater", "concert", "ticketmaster", "game", "steam", "playstation", "xbox"]
            .contains(where: { combined.contains($0) }) {
            category = "entertainment"
            confidence = 80
        }
        // Utilities
        else if ["electric", "water", "gas bill", "internet", "comcast", "att", "verizon", "utility"]
            .contains(where: { combined.contains($0) }) {
            category = "utilities"
            confidence = 90
            isRecurring = true
        }
        // Health
        else if ["pharmacy", "cvs", "walgreens", "doctor", "hospital", "medical", "dental", "health"]
            .contains(where: { combined.contains($0) }) {
            category = "health"
            confidence = 85
        }
        // Default
        else {
            category = "other"
            confidence = 50
        }

        return CategoryResult(category: category, confidence: confidence, isRecurring: isRecurring)
    }
}
