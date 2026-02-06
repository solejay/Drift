import Vapor
import Fluent
import FluentPostgresDriver
import JWT

func configure(_ app: Application) async throws {
    // MARK: - Content Configuration
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.keyEncodingStrategy = .convertToSnakeCase
    ContentConfiguration.global.use(encoder: encoder, for: .json)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // MARK: - Database Configuration
    if let databaseURL = Environment.get("DATABASE_URL") {
        try app.databases.use(.postgres(url: databaseURL), as: .psql)
    } else {
        let config = SQLPostgresConfiguration(
            hostname: Environment.get("DB_HOST") ?? "localhost",
            port: Environment.get("DB_PORT").flatMap(Int.init) ?? 5432,
            username: Environment.get("DB_USER") ?? "drift",
            password: Environment.get("DB_PASSWORD") ?? "password",
            database: Environment.get("DB_NAME") ?? "drift_db",
            tls: .disable
        )
        app.databases.use(.postgres(configuration: config), as: .psql)
    }

    // MARK: - JWT Configuration
    guard let jwtSecret = Environment.get("JWT_SECRET") else {
        fatalError("JWT_SECRET environment variable is required")
    }

    app.jwt.signers.use(.hs256(key: jwtSecret))

    // MARK: - Migrations
    app.migrations.add(CreateUser())
    app.migrations.add(CreateRefreshToken())
    app.migrations.add(CreatePlaidItem())
    app.migrations.add(CreateAccount())
    app.migrations.add(CreateTransaction())
    app.migrations.add(CreateUserPreference())
    app.migrations.add(CreateDeviceToken())

    // Run migrations in development
    if app.environment == .development {
        try await app.autoMigrate()
    }

    // MARK: - Middleware
    // CORS: Restrict origins in production, allow all in development
    let allowedOrigin: CORSMiddleware.AllowOriginSetting
    if app.environment == .production, let origins = Environment.get("ALLOWED_ORIGINS") {
        let originList = origins.split(separator: ",").map(String.init)
        allowedOrigin = .any(originList)
    } else {
        allowedOrigin = .all
    }
    let corsConfig = CORSMiddleware.Configuration(
        allowedOrigin: allowedOrigin,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfig))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.middleware.use(RateLimitMiddleware())

    // MARK: - Routes
    try routes(app)
}
