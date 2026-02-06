import SwiftUI
import UI

/// Registration screen
public struct RegisterView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                // Header
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Create account")
                        .font(.system(size: 32, weight: .semibold, design: .serif))
                        .foregroundStyle(DriftPalette.ink)

                    Text("Start seeing where your money goes")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(DriftPalette.muted)
                }
                .padding(.top, DesignTokens.Spacing.lg)
                .accessibilityElement(children: .combine)

                // Registration form
                GlassCard {
                    VStack(spacing: DesignTokens.Spacing.md) {
                        TextField("Name (optional)", text: $viewModel.displayName)
                            .textContentType(.name)
                            .textFieldStyle(.roundedBorder)
                            .tint(DriftPalette.accent)

                        TextField("Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textFieldStyle(.roundedBorder)
                            .tint(DriftPalette.accent)

                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.newPassword)
                            .textFieldStyle(.roundedBorder)
                            .tint(DriftPalette.accent)

                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                            .textFieldStyle(.roundedBorder)
                            .tint(DriftPalette.accent)

                        if !viewModel.password.isEmpty && viewModel.password.count < 8 {
                            Text("Password must be at least 8 characters")
                                .font(.caption)
                                .foregroundStyle(DriftPalette.sunsetDeep)
                        }

                        if !viewModel.confirmPassword.isEmpty && viewModel.password != viewModel.confirmPassword {
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundStyle(DriftPalette.sunsetDeep)
                        }

                        Button(action: {
                            Task { await viewModel.register() }
                        }) {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Create account")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glassProminentPill)
                            .disabled(!viewModel.isRegisterValid || viewModel.isLoading)
                            .accessibilityHint("Creates your Drift account")
                    }
                }

                // Terms
                Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundStyle(DriftPalette.muted)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .background(DriftBackground(animated: false))
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.error) { _ in
            Button("OK") { viewModel.showError = false }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
    }
}
