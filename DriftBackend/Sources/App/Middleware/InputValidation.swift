import Vapor

// MARK: - Input Validation Helpers

enum InputValidation {

    /// Validates email format using a standard regex pattern.
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    /// Validates password: 8+ chars, at least 1 uppercase, at least 1 number.
    static func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasUppercase && hasNumber
    }

    /// Strips HTML tags and trims whitespace from a string.
    static func sanitize(_ input: String) -> String {
        let stripped = input.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Allowed transaction category values.
    static let validCategories: Set<String> = [
        "food", "transport", "shopping", "entertainment",
        "subscriptions", "utilities", "health", "income",
        "transfer", "other"
    ]

    /// Validates a category string against the allowed set.
    static func isValidCategory(_ category: String) -> Bool {
        validCategories.contains(category.lowercased())
    }

    /// Validates a timezone identifier against the system-known timezones.
    static func isValidTimezone(_ timezone: String) -> Bool {
        TimeZone(identifier: timezone) != nil
    }
}
