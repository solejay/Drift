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
    var amount: Decimal

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
        amount: Decimal,
        date: Date,
        merchantName: String,
        category: String,
        description: String? = nil,
        isPending: Bool = false,
        isExcluded: Bool = false
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
    }
}

// MARK: - DTO

extension Transaction {
    func toDTO() -> TransactionDTO {
        TransactionDTO(
            id: id!,
            accountId: $account.id,
            plaidTransactionId: plaidTransactionId,
            amount: amount,
            date: date,
            merchantName: merchantName,
            category: category,
            description: transactionDescription,
            isPending: isPending,
            isExcluded: isExcluded
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
}
