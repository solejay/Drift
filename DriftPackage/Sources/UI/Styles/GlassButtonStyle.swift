import SwiftUI
import UIKit

/// A button style that applies a glass effect (iOS 26+)
public struct GlassButtonStyle: ButtonStyle {
    public enum Variant {
        case regular
        case prominent
        case prominentPill
        case destructive
    }

    private let variant: Variant

    public init(variant: Variant = .regular) {
        self.variant = variant
    }

    private var isPill: Bool {
        variant == .prominentPill
    }

    private var cornerRadius: CGFloat {
        isPill ? DesignTokens.CornerRadius.pill : DesignTokens.CornerRadius.lg
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .textCase(isPill ? .uppercase : nil)
            .tracking(isPill ? 0.8 : 0)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .foregroundStyle(foregroundColor)
            .background {
                backgroundView
            }
            .modifier(GlassEffectModifier(
                variant: variant,
                isPressed: configuration.isPressed,
                cornerRadius: cornerRadius
            ))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .regular:
            // Glass effect modifier handles the background
            EmptyView()
        case .prominent:
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(DesignTokens.Colors.primaryButton)
        case .prominentPill:
            Capsule()
                .fill(DesignTokens.Colors.primaryButton)
        case .destructive:
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(DesignTokens.Colors.negative)
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .regular:
            return .primary
        case .prominent, .prominentPill:
            return DesignTokens.Colors.primaryButtonText
        case .destructive:
            return .white
        }
    }
}

/// Helper modifier to conditionally apply glass effect
private struct GlassEffectModifier: ViewModifier {
    let variant: GlassButtonStyle.Variant
    let isPressed: Bool
    let cornerRadius: CGFloat

    private var isPill: Bool {
        variant == .prominentPill
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if variant == .regular {
            if #available(iOS 26.0, *) {
                content
                    .glassEffect(isPressed ? .clear : .regular, in: .rect(cornerRadius: cornerRadius))
            } else {
                content
                    .background {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        } else if isPill {
            content
                .clipShape(Capsule())
        } else {
            content
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

public extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { GlassButtonStyle(variant: .regular) }
    static var glassProminent: GlassButtonStyle { GlassButtonStyle(variant: .prominent) }
    static var glassProminentPill: GlassButtonStyle { GlassButtonStyle(variant: .prominentPill) }
    static var glassDestructive: GlassButtonStyle { GlassButtonStyle(variant: .destructive) }
}

/// A secondary button style with subtle background
public struct SecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .foregroundStyle(.secondary)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .fill(Color(uiColor: .tertiarySystemFill))
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
