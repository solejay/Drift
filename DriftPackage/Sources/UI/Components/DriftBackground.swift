import SwiftUI

/// Shared background used across Drift for the calm "mirror" feel
public struct DriftBackground: View {
    private let animated: Bool
    @State private var drift = false

    public init(animated: Bool = true) {
        self.animated = animated
    }

    public var body: some View {
        ZStack {
            DesignTokens.Colors.warmBackground

            LinearGradient(
                colors: [
                    DriftPalette.mist,
                    DriftPalette.warm
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.7)

            Circle()
                .fill(DriftPalette.accent.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: drift ? 160 : 120, y: drift ? -220 : -260)

            Circle()
                .fill(DriftPalette.ocean.opacity(0.25))
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .offset(x: drift ? -170 : -130, y: drift ? 260 : 220)
        }
        .ignoresSafeArea()
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

#Preview {
    DriftBackground()
}
