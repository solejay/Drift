import SwiftUI
import UI

/// Login screen
public struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showRegister = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // Logo and title
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 58))
                            .foregroundStyle(DriftPalette.accent)
                            .accessibilityLabel("Drift logo")

                        Text("Drift")
                            .font(.system(size: 36, weight: .semibold, design: .serif))
                            .foregroundStyle(DriftPalette.ink)

                        Text("See where your money quietly drifts")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(DriftPalette.muted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, DesignTokens.Spacing.xxl)
                    .accessibilityElement(children: .combine)

                    // Login form
                    GlassCard {
                        VStack(spacing: DesignTokens.Spacing.md) {
                            TextField("Email", text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(.roundedBorder)
                                .tint(DriftPalette.accent)

                            SecureField("Password", text: $viewModel.password)
                                .textContentType(.password)
                                .textFieldStyle(.roundedBorder)
                                .tint(DriftPalette.accent)

                            Button(action: {
                                Task { await viewModel.login() }
                            }) {
                                Group {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Sign in")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glassProminentPill)
                            .disabled(!viewModel.isLoginValid || viewModel.isLoading)
                            .accessibilityHint("Signs into your Drift account")
                        }
                    }

                    // Register link
                    Button(action: { showRegister = true }) {
                        Text("Don't have an account? ")
                            .foregroundStyle(DriftPalette.muted)
                        + Text("Sign Up")
                            .foregroundStyle(DriftPalette.ink)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .background(DriftBackground(animated: false))
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
            .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.error) { _ in
                Button("OK") { viewModel.showError = false }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
}

#Preview {
    LoginView()
}
