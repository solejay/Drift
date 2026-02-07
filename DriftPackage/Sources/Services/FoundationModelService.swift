import Foundation
import Core

#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device AI service for enhanced leaky bucket detection.
/// Returns nil from all methods when Foundation Models is unavailable.
public actor FoundationModelService {

    public static let shared = FoundationModelService()

    /// Whether Foundation Models is available on this device
    public var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    // MARK: - Merchant Grouping

    /// Groups raw merchant names into canonical merchant identities.
    /// Returns canonical→[rawNames] mapping, or nil if AI unavailable/fails.
    public func groupMerchants(_ merchantNames: [String]) async -> [String: [String]]? {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            guard SystemLanguageModel.default.availability == .available else { return nil }
            guard !merchantNames.isEmpty else { return nil }

            do {
                var allGroups: [String: [String]] = [:]
                let batchSize = 80

                for batchStart in stride(from: 0, to: merchantNames.count, by: batchSize) {
                    let batchEnd = min(batchStart + batchSize, merchantNames.count)
                    let batch = Array(merchantNames[batchStart..<batchEnd])

                    let session = LanguageModelSession(instructions: """
                        You are a merchant name normalizer. Group the provided merchant names \
                        by the business they belong to. For example, "AMZN*Mktp", "Amazon.com", \
                        and "AMZN DIGITAL" all belong to "Amazon". Use clean, recognizable names \
                        as the canonical name. Each raw name should appear in exactly one group.
                        """)

                    let nameList = batch.joined(separator: ", ")
                    let response = try await session.respond(
                        to: "Group these merchant names: \(nameList)",
                        generating: MerchantGroupingResult.self
                    )

                    for group in response.content.groups {
                        let existing = allGroups[group.canonicalName] ?? []
                        allGroups[group.canonicalName] = existing + group.rawNames
                    }
                }

                return allGroups.isEmpty ? nil : allGroups
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }

    // MARK: - Leak Classification

    /// Classifies detected buckets as true leaks vs essential spending.
    /// Returns classifications parallel to the input array, or nil if AI unavailable/fails.
    public func classifyLeaks(_ buckets: [LeakyBucket]) async -> [LeakClassificationInfo]? {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            guard SystemLanguageModel.default.availability == .available else { return nil }
            guard !buckets.isEmpty else { return nil }

            do {
                let session = LanguageModelSession(instructions: """
                    You are a personal finance advisor. Classify each spending pattern as either \
                    a "leak" (discretionary, cuttable, or reducible) or "essential" (necessary, \
                    hard to cut). Consider the merchant, category, frequency, and amount. \
                    Provide brief reasoning and a confidence multiplier (0.5-1.5) where >1.0 \
                    means more confident it's a real leak and <1.0 means less confident.
                    """)

                let descriptions = buckets.enumerated().map { index, bucket in
                    "\(index + 1). \(bucket.merchantName) — \(bucket.category.displayName), " +
                    "\(bucket.frequency.displayName), avg \(bucket.formattedAverageAmount)/txn, " +
                    "\(bucket.formattedMonthlyImpact)/month"
                }.joined(separator: "\n")

                let response = try await session.respond(
                    to: "Classify these spending patterns:\n\(descriptions)",
                    generating: LeakClassificationResult.self
                )

                let classifications = response.content.classifications
                guard classifications.count == buckets.count else { return nil }

                return classifications.map { classification in
                    LeakClassificationInfo(
                        isLeak: classification.isLeak,
                        reasoning: classification.reasoning,
                        confidenceMultiplier: classification.confidenceMultiplier
                    )
                }
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }

    // MARK: - Insight Generation

    /// Generates a streaming personalized insight for a single bucket.
    /// Falls back to the provided template string if AI is unavailable.
    public nonisolated func generateInsight(
        for bucket: LeakyBucket,
        fallback: String
    ) -> AsyncStream<BucketInsightInfo> {
        AsyncStream { continuation in
            #if canImport(FoundationModels)
            if #available(iOS 26, *) {
                if SystemLanguageModel.default.availability == .available {
                    Task {
                        do {
                            let session = LanguageModelSession(instructions: """
                                You are a friendly, concise personal finance advisor. Generate a \
                                personalized insight about a recurring spending pattern. Be specific \
                                about the merchant and amounts. Keep the tone encouraging, not judgmental. \
                                The insight should be 1-2 sentences. Optionally suggest a specific action \
                                and what else the money could be used for.
                                """)

                            let prompt = """
                                Spending pattern: \(bucket.merchantName) (\(bucket.category.displayName))
                                Frequency: \(bucket.frequency.displayName)
                                Average: \(bucket.formattedAverageAmount) per transaction
                                Monthly impact: \(bucket.formattedMonthlyImpact)
                                Yearly impact: \(bucket.formattedYearlyImpact)
                                Occurrences: \(bucket.occurrenceCount) times
                                """

                            let stream = session.streamResponse(
                                to: prompt,
                                generating: BucketInsight.self
                            )

                            for try await partial in stream {
                                let info = BucketInsightInfo(
                                    insightText: partial.content.insightText ?? "",
                                    actionSuggestion: partial.content.actionSuggestion ?? nil,
                                    alternativeUse: partial.content.alternativeUse ?? nil
                                )
                                continuation.yield(info)
                            }
                            continuation.finish()
                        } catch {
                            continuation.yield(BucketInsightInfo(insightText: fallback))
                            continuation.finish()
                        }
                    }
                    return
                }
            }
            #endif
            // Fallback: emit template string immediately
            continuation.yield(BucketInsightInfo(insightText: fallback))
            continuation.finish()
        }
    }
}
