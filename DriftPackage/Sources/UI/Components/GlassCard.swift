import SwiftUI

/// A card with glass morphism effect
public struct GlassCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat
    private let padding: CGFloat

    public init(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.card,
        padding: CGFloat = DesignTokens.Spacing.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    @ViewBuilder
    public var body: some View {
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

/// A tappable glass card
public struct TappableGlassCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let action: () -> Void

    @State private var isPressed = false

    public init(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.card,
        padding: CGFloat = DesignTokens.Spacing.cardPadding,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.action = action
    }

    @ViewBuilder
    public var body: some View {
        if #available(iOS 26.0, *) {
            content
                .padding(padding)
                .glassEffect(isPressed ? .clear : .regular, in: .rect(cornerRadius: cornerRadius))
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(DesignTokens.Animation.spring, value: isPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in
                            isPressed = false
                            action()
                        }
                )
        } else {
            content
                .padding(padding)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(DesignTokens.Animation.spring, value: isPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in
                            isPressed = false
                            action()
                        }
                )
        }
    }
}

/// A prominent hero card for displaying key metrics
public struct HeroCard<Content: View>: View {
    private let content: Content
    private let gradient: LinearGradient

    public init(
        gradient: LinearGradient = LinearGradient(
            colors: [.accentColor.opacity(0.8), .accentColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.gradient = gradient
    }

    @ViewBuilder
    public var body: some View {
        if #available(iOS 26.0, *) {
            content
                .padding(DesignTokens.Spacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xxl)
                        .fill(gradient)
                }
                .glassEffect(in: .rect(cornerRadius: DesignTokens.CornerRadius.xxl))
                .shadow(DesignTokens.Shadow.medium)
        } else {
            content
                .padding(DesignTokens.Spacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xxl)
                        .fill(gradient)
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xxl))
                .shadow(DesignTokens.Shadow.medium)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GlassCard {
            VStack {
                Text("Glass Card")
                    .font(.headline)
                Text("With Liquid Glass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        TappableGlassCard(action: {}) {
            HStack {
                Text("Tappable")
                Spacer()
                Image(systemName: "chevron.right")
            }
        }

        HeroCard {
            VStack {
                Text("$1,234.56")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
                Text("Total Spent")
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
