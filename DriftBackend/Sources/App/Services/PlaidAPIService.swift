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
            let clientId: String
            let secret: String
            let user: UserInfo
            let clientName: String
            let products: [String]
            let countryCodes: [String]
            let language: String
            let redirectUri: String?

            struct UserInfo: Content {
                let clientUserId: String
            }
        }

        struct Response: Content {
            let linkToken: String
        }

        let redirectUri = Environment.get("PLAID_REDIRECT_URI")

        let request = Request(
            clientId: clientId,
            secret: secret,
            user: .init(clientUserId: userId.uuidString),
            clientName: "Drift",
            products: ["transactions"],
            countryCodes: ["US"],
            language: "en",
            redirectUri: redirectUri
        )

        let response = try await client.post(URI(string: "\(environment.baseURL)/link/token/create")) { req in
            try req.content.encode(request)
            req.headers.contentType = .json
        }

        let result = try response.content.decode(Response.self)
        return result.linkToken
    }

    // MARK: - Exchange Token

    struct ExchangeResult {
        let accessToken: String
        let itemId: String
    }

    func exchangePublicToken(_ publicToken: String) async throws -> ExchangeResult {
        struct Request: Content {
            let clientId: String
            let secret: String
            let publicToken: String
        }

        struct Response: Content {
            let accessToken: String
            let itemId: String
        }

        let request = Request(
            clientId: clientId,
            secret: secret,
            publicToken: publicToken
        )

        let response = try await client.post(URI(string: "\(environment.baseURL)/item/public_token/exchange")) { req in
            try req.content.encode(request)
            req.headers.contentType = .json
        }

        let result = try response.content.decode(Response.self)
        return ExchangeResult(accessToken: result.accessToken, itemId: result.itemId)
    }

    // MARK: - Get Accounts

    struct PlaidAccount: Content {
        let accountId: String
        let name: String
        let officialName: String?
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
            let clientId: String
            let secret: String
            let accessToken: String
        }

        struct Response: Content {
            let accounts: [PlaidAccount]
        }

        let request = Request(
            clientId: clientId,
            secret: secret,
            accessToken: accessToken
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
        let transactionId: String
        let accountId: String
        let amount: Double
        let date: String
        let merchantName: String?
        let name: String
        let category: [String]?
        let pending: Bool
    }

    func syncTransactions(accessToken: String, cursor: String?) async throws -> TransactionSyncResult {
        struct Request: Content {
            let clientId: String
            let secret: String
            let accessToken: String
            let cursor: String?
        }

        struct Response: Content {
            let added: [PlaidTransaction]
            let modified: [PlaidTransaction]
            let removed: [RemovedTransaction]
            let nextCursor: String
            let hasMore: Bool

            struct RemovedTransaction: Content {
                let transactionId: String
            }
        }

        let request = Request(
            clientId: clientId,
            secret: secret,
            accessToken: accessToken,
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
            removed: result.removed.map(\.transactionId),
            nextCursor: result.nextCursor,
            hasMore: result.hasMore
        )
    }

    // MARK: - Get Institution

    struct PlaidInstitution: Content {
        let institutionId: String
        let name: String
    }

    func getInstitution(institutionId: String) async throws -> PlaidInstitution {
        struct Request: Content {
            let clientId: String
            let secret: String
            let institutionId: String
            let countryCodes: [String]
        }

        struct Response: Content {
            let institution: PlaidInstitution
        }

        let request = Request(
            clientId: clientId,
            secret: secret,
            institutionId: institutionId,
            countryCodes: ["US"]
        )

        let response = try await client.post(URI(string: "\(environment.baseURL)/institutions/get_by_id")) { req in
            try req.content.encode(request)
            req.headers.contentType = .json
        }

        let result = try response.content.decode(Response.self)
        return result.institution
    }
}
