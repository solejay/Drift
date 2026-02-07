import Fluent
import Vapor

final class Transaction: Model, Content, @unchecked Sendable {
    static let schema = "transactions"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "account_id")
    var account: Account

    @Parent(key: "user_id")
    var user: User

    @Field(key: "plaid_transaction_id")
    var plaidTransactionId: String?

    @Field(key: "amount")
    var amount: Double

    @Field(key: "date")
    var date: Date

    @Field(key: "merchant_name")
    var merchantName: String

    @Field(key: "category")
    var category: String

    @Field(key: "description")
    var transactionDescription: String?

    @Field(key: "is_pending")
    var isPending: Bool

    @Field(key: "is_excluded")
    var isExcluded: Bool

    // MARK: - Enrichment Fields

    @Field(key: "pfc_primary")
    var pfcPrimary: String?

    @Field(key: "pfc_detailed")
    var pfcDetailed: String?

    @Field(key: "pfc_confidence")
    var pfcConfidence: String?

    @Field(key: "logo_url")
    var logoUrl: String?

    @Field(key: "website")
    var website: String?

    @Field(key: "payment_channel")
    var paymentChannel: String?

    @Field(key: "merchant_entity_id")
    var merchantEntityId: String?

    @Field(key: "counterparty_name")
    var counterpartyName: String?

    @Field(key: "counterparty_type")
    var counterpartyType: String?

    @Field(key: "counterparty_logo_url")
    var counterpartyLogoUrl: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        accountID: UUID,
        userID: UUID,
        plaidTransactionId: String? = nil,
        amount: Double,
        date: Date,
        merchantName: String,
        category: String,
        description: String? = nil,
        isPending: Bool = false,
        isExcluded: Bool = false,
        pfcPrimary: String? = nil,
        pfcDetailed: String? = nil,
        pfcConfidence: String? = nil,
        logoUrl: String? = nil,
        website: String? = nil,
        paymentChannel: String? = nil,
        merchantEntityId: String? = nil,
        counterpartyName: String? = nil,
        counterpartyType: String? = nil,
        counterpartyLogoUrl: String? = nil
    ) {
        self.id = id
        self.$account.id = accountID
        self.$user.id = userID
        self.plaidTransactionId = plaidTransactionId
        self.amount = amount
        self.date = date
        self.merchantName = merchantName
        self.category = category
        self.transactionDescription = description
        self.isPending = isPending
        self.isExcluded = isExcluded
        self.pfcPrimary = pfcPrimary
        self.pfcDetailed = pfcDetailed
        self.pfcConfidence = pfcConfidence
        self.logoUrl = logoUrl
        self.website = website
        self.paymentChannel = paymentChannel
        self.merchantEntityId = merchantEntityId
        self.counterpartyName = counterpartyName
        self.counterpartyType = counterpartyType
        self.counterpartyLogoUrl = counterpartyLogoUrl
    }
}

// MARK: - DTO

extension Transaction {
    func toDTO() -> TransactionDTO {
        TransactionDTO(
            id: id!,
            accountId: $account.id,
            plaidTransactionId: plaidTransactionId,
            amount: Decimal(amount),
            date: date,
            merchantName: merchantName,
            category: category,
            description: transactionDescription,
            isPending: isPending,
            isExcluded: isExcluded,
            pfcPrimary: pfcPrimary,
            pfcDetailed: pfcDetailed,
            pfcConfidence: pfcConfidence,
            logoUrl: logoUrl,
            website: website,
            paymentChannel: paymentChannel,
            merchantEntityId: merchantEntityId,
            counterpartyName: counterpartyName,
            counterpartyType: counterpartyType,
            counterpartyLogoUrl: counterpartyLogoUrl
        )
    }
}

struct TransactionDTO: Content {
    let id: UUID
    let accountId: UUID
    let plaidTransactionId: String?
    let amount: Decimal
    let date: Date
    let merchantName: String
    let category: String
    let description: String?
    let isPending: Bool
    let isExcluded: Bool
    let pfcPrimary: String?
    let pfcDetailed: String?
    let pfcConfidence: String?
    let logoUrl: String?
    let website: String?
    let paymentChannel: String?
    let merchantEntityId: String?
    let counterpartyName: String?
    let counterpartyType: String?
    let counterpartyLogoUrl: String?
}
