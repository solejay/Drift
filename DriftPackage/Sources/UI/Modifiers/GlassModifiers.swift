import SwiftUI

/// Modifier to apply glass card styling
public struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let padding: CGFloat

    public init(cornerRadius: CGFloat = DesignTokens.CornerRadius.xl, padding: CGFloat = DesignTokens.Spacing.md) {
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    @ViewBuilder
    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding(padding)
                .glassEffect(in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .padding(padding)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

/// Modifier to apply interactive glass styling
public struct InteractiveGlassModifier: ViewModifier {
    let isPressed: Bool
    let cornerRadius: CGFloat

    public init(isPressed: Bool = false, cornerRadius: CGFloat = DesignTokens.CornerRadius.xl) {
        self.isPressed = isPressed
        self.cornerRadius = cornerRadius
    }

    @ViewBuilder
    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(isPressed ? .clear : .regular, in: .rect(cornerRadius: cornerRadius))
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(DesignTokens.Animation.spring, value: isPressed)
        } else {
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(DesignTokens.Animation.spring, value: isPressed)
        }
    }
}

/// Modifier for list row glass styling
public struct GlassRowModifier: ViewModifier {
    public init() {}

    @ViewBuilder
    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .glassEffect(in: .rect(cornerRadius: DesignTokens.CornerRadius.md))
        } else {
            content
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .fill(.ultraThinMaterial)
                }
        }
    }
}

// MARK: - View Extensions

public extension View {
    /// Apply glass card styling
    func glassCard(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.xl,
        padding: CGFloat = DesignTokens.Spacing.md
    ) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    /// Apply interactive glass styling
    func interactiveGlass(
        isPressed: Bool = false,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.xl
    ) -> some View {
        modifier(InteractiveGlassModifier(isPressed: isPressed, cornerRadius: cornerRadius))
    }

    /// Apply glass row styling for list items
    func glassRow() -> some View {
        modifier(GlassRowModifier())
    }

    /// Conditional modifier
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
