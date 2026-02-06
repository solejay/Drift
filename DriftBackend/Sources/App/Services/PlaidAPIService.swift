import Vapor

/// Service for communicating with Plaid API
///
/// TODO: Encrypt Plaid access tokens at rest using AES-256 with PLAID_ENCRYPTION_KEY env variable.
/// Vapor does not include AES natively. When a crypto library (e.g. swift-crypto) is added,
/// implement EncryptionService to encrypt/decrypt access tokens before storage.
/// For now, the database itself should be encrypted at rest in production.
actor PlaidAPIService {
    private let client: Client
    private let clientId: String
    private let secret: String
    private let environment: PlaidEnvironment

    enum PlaidEnvironment: String {
        case sandbox = "sandbox"
        case development = "development"
        case production = "production"

        var baseURL: String {
            switch self {
            case .sandbox: return "https://sandbox.plaid.com"
            case .development: return "https://development.plaid.com"
            case .production: return "https://production.plaid.com"
            }
        }
    }

    init(client: Client) {
        self.client = client
        self.clientId = Environment.get("PLAID_CLIENT_ID") ?? ""
        self.secret = Environment.get("PLAID_SECRET") ?? ""
        self.environment = PlaidEnvironment(rawValue: Environment.get("PLAID_ENV") ?? "sandbox") ?? .sandbox
    }

    // MARK: - Link Token

    func createLinkToken(userId: UUID) async throws -> String {
        struct Request: Content {
            let client_id: String
            let secret: String
            let user: UserInfo
            let client_name: String
            let products: [String]
            let country_codes: [String]
            let language: String

            struct UserInfo: Content {
                let client_user_id: String
            }
        }

        struct Response: Content {
            let link_token: String
        }

        let request = Request(
            client_id: clientId,
            secret: secret,
            user: .init(client_user_id: userId.uuidString),
            client_name: "Drift",
            products: ["transactions"],
            country_codes: ["US"],
            language: "en"
        )

        let response = try await client.post(URI(string: "\(environment.baseURL)/link/token/create")) { req in
            try req.content.encode(request)
            req.headers.contentType = .json
        }

        let result = try response.content.decode(Response.self)
        return result.link_token
    }

    // MARK: - Exchange Token

    struct ExchangeResult {
        let accessToken: String
        let itemId: String
    }

    func exchangePublicToken(_ publicToken: String) async throws -> ExchangeResult {
        struct Request: Content {
            let client_id: String
            let secret: String
            let public_token: String
        }

        struct Response: Content {
            let access_token: String
            let item_id: String
        }

        let request = Request(
            client_id: clientId,
            secret: secret,
            public_token: publicToken
        )

        let response = try await client.post(URI(string: "\(environment.baseURL)/item/public_token/exchange")) { req in
            try req.content.encode(request)
            req.headers.contentType = .json
        }

        let result = try response.content.decode(Response.self)
        return ExchangeResult(accessToken: result.access_token, itemId: result.item_id)
    }

    // MARK: - Get Accounts

    struct PlaidAccount: Content {
        let account_id: String
        let name: String
        let official_name: String?
        let type: String
        let subtype: String?
        let mask: String?
        let balances: Balances

        struct Balances: Content {
            let current: Double?
            let available: Double?
        }
    }

    func getAccounts(accessToken: String) async throws -> [PlaidAccount] {
        struct Request: Content {
            let client_id: String
            let secret: String
            let access_token: String
        }

        struct Response: Content {
            let accounts: [PlaidAccount]
        }

        let request = Request(
            client_id: clientId,
            secret: secret,
            access_token: accessToken
        )

        let response = try await client.post(URI(string: "\(environment.baseURL)/accounts/get")) { req in
            try req.content.encode(request)
            req.headers.contentType = .json
        }

        let result = try response.content.decode(Response.self)
        return result.accounts
    }

    // MARK: - Sync Transactions

    struct TransactionSyncResult {
        let added: [PlaidTransaction]
        let modified: [PlaidTransaction]
        let removed: [String]
        let nextCursor: String
        let hasMore: Bool
    }

    struct PlaidTransaction: Content {
        let transaction_id: String
        let account_id: String
        let amount: Double
        let date: String
        let merchant_name: String?
        let name: String
        let category: [String]?
        let pending: Bool
    }

    func syncTransactions(accessToken: String, cursor: String?) async throws -> TransactionSyncResult {
        struct Request: Content {
            let client_id: String
            let secret: String
            let access_token: String
            let cursor: String?
        }

        struct Response: Content {
            let added: [PlaidTransaction]
            let modified: [PlaidTransaction]
            let removed: [RemovedTransaction]
            let next_cursor: String
            let has_more: Bool

            struct RemovedTransaction: Content {
                let transaction_id: String
            }
        }

        let request = Request(
            client_id: clientId,
            secret: secret,
            access_token: accessToken,
            cursor: cursor
        )

        let response = try await client.post(URI(string: "\(environment.baseURL)/transactions/sync")) { req in
            try req.content.encode(request)
            req.headers.contentType = .json
        }

        let result = try response.content.decode(Response.self)

        return TransactionSyncResult(
            added: result.added,
            modified: result.modified,
            removed: result.removed.map(\.transaction_id),
            nextCursor: result.next_cursor,
            hasMore: result.has_more
        )
    }

    // MARK: - Get Institution

    struct PlaidInstitution: Content {
        let institution_id: String
        let name: String
    }

    func getInstitution(institutionId: String) async throws -> PlaidInstitution {
        struct Request: Content {
            let client_id: String
            let secret: String
            let institution_id: String
            let country_codes: [String]
        }

        struct Response: Content {
            let institution: PlaidInstitution
        }

        let request = Request(
            client_id: clientId,
            secret: secret,
            institution_id: institutionId,
            country_codes: ["US"]
        )

        let response = try await client.post(URI(string: "\(environment.baseURL)/institutions/get_by_id")) { req in
            try req.content.encode(request)
            req.headers.contentType = .json
        }

        let result = try response.content.decode(Response.self)
        return result.institution
    }
}
