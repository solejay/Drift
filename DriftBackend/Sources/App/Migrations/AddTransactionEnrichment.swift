import Fluent

struct AddTransactionEnrichment: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("transactions")
            .field("pfc_primary", .string)
            .field("pfc_detailed", .string)
            .field("pfc_confidence", .string)
            .field("logo_url", .string)
            .field("website", .string)
            .field("payment_channel", .string)
            .field("merchant_entity_id", .string)
            .field("counterparty_name", .string)
            .field("counterparty_type", .string)
            .field("counterparty_logo_url", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("transactions")
            .deleteField("pfc_primary")
            .deleteField("pfc_detailed")
            .deleteField("pfc_confidence")
            .deleteField("logo_url")
            .deleteField("website")
            .deleteField("payment_channel")
            .deleteField("merchant_entity_id")
            .deleteField("counterparty_name")
            .deleteField("counterparty_type")
            .deleteField("counterparty_logo_url")
            .update()
    }
}
