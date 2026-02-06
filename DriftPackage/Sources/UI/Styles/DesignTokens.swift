import SwiftUI
import UIKit

/// Design tokens for consistent styling across the app
public enum DesignTokens {
    // MARK: - Spacing
    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48

        // Semantic spacing
        public static let cardPadding: CGFloat = 20
        public static let sectionSpacing: CGFloat = 32
    }

    // MARK: - Corner Radius
    public enum CornerRadius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 28
        public static let pill: CGFloat = 999

        // Semantic corner radii
        public static let card: CGFloat = 22
    }

    // MARK: - Font Sizes
    public enum FontSize {
        public static let caption: CGFloat = 12
        public static let body: CGFloat = 16
        public static let title3: CGFloat = 20
        public static let title2: CGFloat = 24
        public static let title1: CGFloat = 28
        public static let largeTitle: CGFloat = 34
        public static let hero: CGFloat = 48
    }

    // MARK: - Animation
    public enum Animation {
        public static let fast: Double = 0.15
        public static let normal: Double = 0.25
        public static let slow: Double = 0.4
        public static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.85)
        public static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
    }

    // MARK: - Shadows
    public enum Shadow {
        public static var small: ShadowStyle { ShadowStyle(color: .black.opacity(0.1), radius: 4, x: 0, y: 2) }
        public static var medium: ShadowStyle { ShadowStyle(color: .black.opacity(0.15), radius: 8, x: 0, y: 4) }
        public static var large: ShadowStyle { ShadowStyle(color: .black.opacity(0.2), radius: 16, x: 0, y: 8) }
    }

    // MARK: - Colors
    public enum Colors {
        public static let primary = Color.accentColor
        public static let background = Color(uiColor: .systemBackground)
        public static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
        public static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
        public static let label = Color(uiColor: .label)
        public static let secondaryLabel = Color(uiColor: .secondaryLabel)
        public static let tertiaryLabel = Color(uiColor: .tertiaryLabel)

        // Warm background palette (Origin-inspired) - adapts to dark mode
        public static let warmBackground = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? .systemBackground
                : UIColor(red: 0.969, green: 0.965, blue: 0.953, alpha: 1.0)
        })

        // Text colors - adapt to dark mode for proper contrast
        public static let primaryText = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? .label
                : UIColor(red: 0.106, green: 0.122, blue: 0.165, alpha: 1.0)
        })

        public static let secondaryText = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? .secondaryLabel
                : UIColor(red: 0.459, green: 0.459, blue: 0.439, alpha: 1.0)
        })

        // Button colors - adapt to dark mode
        public static let primaryButton = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? .label
                : UIColor(red: 0.106, green: 0.122, blue: 0.165, alpha: 1.0)
        })

        // Button text color - contrasts with primaryButton
        public static let primaryButtonText = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? .systemBackground
                : .white
        })

        // Semantic colors (updated for warmer palette)
        public static let income = Color.mint
        public static let expense = Color.red
        public static let neutral = Color.gray
        public static let positive = Color(red: 0.420, green: 0.557, blue: 0.361) // Olive/sage green #6B8E5C
        public static let negative = Color(red: 0.906, green: 0.365, blue: 0.353) // Warmer coral-red

        // Category colors
        public static func category(_ category: String) -> Color {
            switch category.lowercased() {
            case "food": return .orange
            case "transport": return .blue
            case "shopping": return .pink
            case "entertainment": return .purple
            case "subscriptions": return .red
            case "utilities": return .yellow
            case "health": return .green
            case "income": return .mint
            case "transfer": return .gray
            default: return .secondary
            }
        }
    }

    // MARK: - Typography
    public enum Typography {
        public static let sectionHeader = Font.caption.weight(.medium)
        public static let sectionHeaderTracking: CGFloat = 1.2
    }
}

// MARK: - Shadow Style

public struct ShadowStyle {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - View Extension for Shadows

public extension View {
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }

    /// Apply section header styling with uppercase text and letter spacing
    func sectionHeaderStyle() -> some View {
        self.font(.caption.weight(.medium))
            .textCase(.uppercase)
            .tracking(DesignTokens.Typography.sectionHeaderTracking)
            .foregroundStyle(DriftPalette.muted)
    }
}
