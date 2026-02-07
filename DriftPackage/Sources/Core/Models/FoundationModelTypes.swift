import Foundation

// MARK: - Platform-Agnostic Types (available on all iOS versions)

/// AI classification info for a leaky bucket
public struct LeakClassificationInfo: Codable, Sendable, Hashable {
    public let isLeak: Bool
    public let reasoning: String
    public let confidenceMultiplier: Double

    public init(isLeak: Bool, reasoning: String, confidenceMultiplier: Double) {
        self.isLeak = isLeak
        self.reasoning = reasoning
        self.confidenceMultiplier = confidenceMultiplier
    }
}

/// AI-generated insight for a bucket
public struct BucketInsightInfo: Codable, Sendable, Hashable {
    public let insightText: String
    public let actionSuggestion: String?
    public let alternativeUse: String?

    public init(insightText: String, actionSuggestion: String? = nil, alternativeUse: String? = nil) {
        self.insightText = insightText
        self.actionSuggestion = actionSuggestion
        self.alternativeUse = alternativeUse
    }
}

/// Processing stages for loading state UI
public enum AIProcessingStage: String, Sendable {
    case groupingMerchants = "Grouping merchants..."
    case detectingPatterns = "Detecting patterns..."
    case classifyingLeaks = "Classifying spending..."
    case generatingInsight = "Generating insight..."

    public var displayText: String { rawValue }
}

// MARK: - Foundation Models Generable Types (iOS 26+)

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
@Generable(description: "A group of merchant names that refer to the same business")
public struct MerchantGroup {
    @Guide(description: "The canonical/clean merchant name (e.g. 'Amazon')")
    public var canonicalName: String

    @Guide(description: "List of raw merchant name variants that match this business")
    public var rawNames: [String]
}

@available(iOS 26, *)
@Generable(description: "Result of grouping merchant names by business identity")
public struct MerchantGroupingResult {
    @Guide(description: "Groups of merchant names, each with a canonical name and raw variants")
    public var groups: [MerchantGroup]
}

@available(iOS 26, *)
@Generable(description: "Classification of whether a spending pattern is a true leak or essential spending")
public struct LeakClassification {
    @Guide(description: "Whether this is a true leak (discretionary, cuttable) vs essential spending")
    public var isLeak: Bool

    @Guide(description: "Brief reasoning for the classification")
    public var reasoning: String

    @Guide(description: "Confidence multiplier from 0.5 to 1.5 to adjust the algorithmic confidence score", .range(0.5...1.5))
    public var confidenceMultiplier: Double
}

@available(iOS 26, *)
@Generable(description: "Classification results for a batch of spending patterns")
public struct LeakClassificationResult {
    @Guide(description: "Classifications for each spending pattern bucket")
    public var classifications: [LeakClassification]
}

@available(iOS 26, *)
@Generable(description: "A personalized insight about a recurring spending pattern")
public struct BucketInsight {
    @Guide(description: "The main insight text about the spending pattern, 1-2 sentences")
    public var insightText: String

    @Guide(description: "A specific actionable suggestion to reduce this spending, or nil if not applicable")
    public var actionSuggestion: String?

    @Guide(description: "What else the money could be used for at this amount, or nil")
    public var alternativeUse: String?
}
#endif
