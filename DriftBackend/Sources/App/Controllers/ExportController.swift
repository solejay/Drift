import Vapor
import Fluent

struct ExportController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let export = routes.grouped("export")
        export.get("transactions", use: exportTransactions)
    }

    // MARK: - Export Transactions as CSV

    func exportTransactions(req: Request) async throws -> Response {
        let userId = try req.userId

        // Parse query parameters
        let startDate = try? req.query.get(Date.self, at: "startDate")
        let endDate = try? req.query.get(Date.self, at: "endDate")

        var query = Transaction.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$isExcluded == false)

        if let startDate {
            query = query.filter(\.$date >= startDate)
        }
        if let endDate {
            query = query.filter(\.$date <= endDate)
        }

        let transactions = try await query
            .sort(\.$date, .descending)
            .limit(10_000)
            .all()

        // Build CSV
        var csv = "date,merchant_name,category,amount,description,is_pending,account_id\n"

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        for txn in transactions {
            let date = dateFormatter.string(from: txn.date)
            let merchant = escapeCSV(txn.merchantName)
            let category = escapeCSV(txn.category)
            let amount = "\(txn.amount)"
            let description = escapeCSV(txn.transactionDescription ?? "")
            let isPending = txn.isPending ? "true" : "false"
            let accountId = txn.$account.id.uuidString

            csv += "\(date),\(merchant),\(category),\(amount),\(description),\(isPending),\(accountId)\n"
        }

        let response = Response(status: .ok, body: .init(string: csv))
        response.headers.contentType = HTTPMediaType(type: "text", subType: "csv")
        response.headers.add(name: .contentDisposition, value: "attachment; filename=\"transactions.csv\"")

        return response
    }

    // MARK: - Helpers

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
