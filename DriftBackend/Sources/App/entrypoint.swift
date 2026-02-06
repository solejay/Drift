import Vapor
import Fluent
import FluentPostgresDriver

@main
struct Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)

        // Configure the application
        try await configure(app)

        // Run the application
        try await app.execute()
    }
}
