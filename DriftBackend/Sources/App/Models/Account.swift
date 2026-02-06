import Fluent
import Vapor

final class Account: Model, Content, @unchecked Sendable {
    static let schema = "accounts"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "plaid_item_id")
    var plaidItem: PlaidItem

    @Parent(key: "user_id")
    var user: User

    @Field(key: "plaid_account_id")
    var plaidAccountId: String

    @Field(key: "name")
    var name: String

    @Field(key: "official_name")
    var officialName: String?

    @Field(key: "type")
    var type: String

    @Field(key: "subtype")
    var subtype: String?

    @Field(key: "mask")
    var mask: String?

    @Field(key: "current_balance")
    var currentBalance: Decimal?

    @Field(key: "available_balance")
    var availableBalance: Decimal?

    @Field(key: "is_hidden")
    var isHidden: Bool

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$account)
    var transactions: [Transaction]

    init() {}

    init(
        id: UUID? = nil,
        plaidItemID: UUID,
        userID: UUID,
        plaidAccountId: String,
        name: String,
        officialName: String? = nil,
        type: String,
        subtype: String? = nil,
        mask: String? = nil,
        currentBalance: Decimal? = nil,
        availableBalance: Decimal? = nil
    ) {
        self.id = id
        self.$plaidItem.id = plaidItemID
        self.$user.id = userID
        self.plaidAccountId = plaidAccountId
        self.name = name
        self.officialName = officialName
        self.type = type
        self.subtype = subtype
        self.mask = mask
        self.currentBalance = currentBalance
        self.availableBalance = availableBalance
        self.isHidden = false
    }
}

// MARK: - DTO

extension Account {
    func toDTO() -> AccountDTO {
        AccountDTO(
            id: id!,
            plaidAccountId: plaidAccountId,
            name: name,
            officialName: officialName,
            type: type,
            mask: mask,
            currentBalance: currentBalance,
            availableBalance: availableBalance,
            institutionName: nil, // Would need to join with PlaidItem
            isHidden: isHidden
        )
    }
}

struct AccountDTO: Content {
    let id: UUID
    let plaidAccountId: String?
    let name: String
    let officialName: String?
    let type: String
    let mask: String?
    let currentBalance: Decimal?
    let availableBalance: Decimal?
    let institutionName: String?
    let isHidden: Bool
}
