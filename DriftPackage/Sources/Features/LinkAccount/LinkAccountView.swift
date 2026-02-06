import SwiftUI
import UI
import Core

/// View for linking and managing bank accounts
public struct LinkAccountView: View {
    @StateObject private var viewModel = LinkAccountViewModel()
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    if viewModel.accounts.isEmpty {
                        emptyState
                    } else {
                        accountsList
                    }
                }
                .padding()
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task { await viewModel.startLinking() }
                    }) {
                        Image(systemName: "plus")
                    }
                    .disabled(viewModel.isLinking)
                }

                if viewModel.hasLinkedAccounts {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .task {
                await viewModel.loadAccounts()
            }
            .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.error) { _ in
                Button("OK") { viewModel.showError = false }
            } message: { error in
                Text(error.localizedDescription)
            }
            .overlay {
                if viewModel.isLinking || viewModel.isSyncing {
                    LoadingOverlay(
                        message: viewModel.isLinking ? "Connecting to your bank..." : "Syncing transactions..."
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
                .frame(height: 60)

            Image(systemName: "building.columns")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Link Your Bank")
                    .font(.title2.bold())

                Text("Connect your bank accounts to start tracking your spending patterns.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task { await viewModel.startLinking() }
            }) {
                HStack {
                    Image(systemName: "link")
                    Text("Link Account")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .disabled(viewModel.isLinking)

            // Security note
            GlassCard(padding: DesignTokens.Spacing.sm) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Secured by Plaid")
                            .font(.caption.weight(.semibold))
                        Text("We never see your bank credentials")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Accounts List

    private var accountsList: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ForEach(viewModel.accounts) { account in
                AccountRow(account: account) {
                    Task { await viewModel.unlinkAccount(account) }
                }
            }

            // Sync button
            Button(action: {
                Task { await viewModel.syncTransactions() }
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Sync Transactions")
                }
            }
            .buttonStyle(.secondary)
            .disabled(viewModel.isSyncing)
        }
    }
}

// MARK: - Account Row

private struct AccountRow: View {
    let account: AccountDTO
    let onUnlink: () -> Void

    @State private var showUnlinkConfirmation = false

    var body: some View {
        GlassCard {
            HStack(spacing: DesignTokens.Spacing.md) {
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.headline)

                    HStack {
                        if let institution = account.institutionName {
                            Text(institution)
                        }
                        if let mask = account.mask {
                            Text("••••\(mask)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Balance
                if let balance = account.currentBalance {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(balance))
                            .font(.headline.monospacedDigit())

                        Text(account.type.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Menu
                Menu {
                    Button(role: .destructive) {
                        showUnlinkConfirmation = true
                    } label: {
                        Label("Unlink Account", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(8)
                }
            }
        }
        .confirmationDialog(
            "Unlink Account",
            isPresented: $showUnlinkConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unlink", role: .destructive, action: onUnlink)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \(account.name) and its transactions from Drift.")
        }
    }

    private var iconName: String {
        switch account.type.lowercased() {
        case "checking": return "banknote"
        case "savings": return "building.columns"
        case "credit": return "creditcard"
        default: return "dollarsign.circle"
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }
}

// MARK: - Loading Overlay

private struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            GlassCard {
                VStack(spacing: DesignTokens.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 200)
            }
        }
    }
}

#Preview {
    LinkAccountView()
}
