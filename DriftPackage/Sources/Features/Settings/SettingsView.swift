import SwiftUI
import Core
import UI
import Services

/// App settings view
public struct SettingsView: View {
    @ObservedObject private var authService: AuthService
    @ObservedObject private var biometricService: BiometricService
    @State private var showLogoutConfirmation = false
    @State private var showLinkAccount = false
    @State private var isSyncing = false
    @State private var syncResult: SyncResult?
    @AppStorage("appearanceMode") private var appearanceMode = "system"

    private enum SyncResult {
        case success
        case failure(String)
    }

    public init(
        authService: AuthService = .shared,
        biometricService: BiometricService = .shared
    ) {
        self.authService = authService
        self.biometricService = biometricService
    }

    public var body: some View {
        List {
            profileSection
            accountsSection
            securitySection
            appearanceSection
            preferencesSection
            aboutSection
            signOutSection
        }
        .scrollContentBackground(.hidden)
        .background(DriftBackground(animated: false))
        .navigationTitle("Settings")
        .sheet(isPresented: $showLinkAccount) {
            LinkAccountView()
        }
        .confirmationDialog(
            "Sign Out",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task { await authService.logout() }
            }
            Button("Sign Out Everywhere", role: .destructive) {
                Task { await authService.logout(allDevices: true) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section {
            if let user = authService.currentUser {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Text(initials(for: user))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(DriftPalette.accent)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName ?? "User")
                            .font(.headline)
                            .foregroundStyle(DriftPalette.ink)
                        Text(user.email)
                            .font(.caption)
                            .foregroundStyle(DriftPalette.muted)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(DriftPalette.muted)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Loading profile...")
                            .font(.headline)
                            .foregroundStyle(DriftPalette.ink)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
                .task {
                    await authService.fetchUserProfile()
                }
            }
        }
    }

    // MARK: - Accounts

    private var accountsSection: some View {
        Section {
            Button(action: { showLinkAccount = true }) {
                Label("Manage Linked Accounts", systemImage: "building.columns")
                    .foregroundStyle(DriftPalette.ink)
            }
            .accessibilityHint("Opens bank account linking")

            Button(action: { syncTransactions() }) {
                HStack {
                    Label("Sync Transactions", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundStyle(DriftPalette.ink)
                    Spacer()
                    if isSyncing {
                        ProgressView()
                            .controlSize(.small)
                    } else if let result = syncResult {
                        switch result {
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(DriftPalette.sage)
                                .accessibilityLabel("Sync succeeded")
                        case .failure:
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(DriftPalette.sunsetDeep)
                                .accessibilityLabel("Sync failed")
                        }
                    }
                }
            }
            .disabled(isSyncing)
            .accessibilityHint("Fetches the latest transactions from your bank")
        } header: {
            Text("Accounts")
        } footer: {
            Text("Drift uses read-only access. We never move your money.")
        }
    }

    // MARK: - Security

    private var securitySection: some View {
        Section("Security") {
            if biometricService.isAvailable {
                Toggle(isOn: Binding(
                    get: { biometricService.isEnabled },
                    set: { newValue in
                        if newValue {
                            Task {
                                let success = await biometricService.enableWithVerification()
                                if !success {
                                    HapticManager.notification(.error)
                                }
                            }
                        } else {
                            biometricService.disable()
                        }
                        HapticManager.selection()
                    }
                )) {
                    Label(biometricService.biometricType.displayName, systemImage: biometricService.biometricType.iconName)
                        .foregroundStyle(DriftPalette.ink)
                }
                .tint(DriftPalette.accent)
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: $appearanceMode) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Appearance")
        } footer: {
            Text("System follows your device settings.")
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section("Preferences") {
            NavigationLink {
                NotificationSettingsView()
            } label: {
                Label("Notifications", systemImage: "bell")
                    .foregroundStyle(DriftPalette.ink)
            }

            NavigationLink {
                CategorySettingsView()
            } label: {
                Label("Categories", systemImage: "tag")
                    .foregroundStyle(DriftPalette.ink)
            }

            NavigationLink {
                PrivacySettingsView()
            } label: {
                Label("Privacy", systemImage: "hand.raised")
                    .foregroundStyle(DriftPalette.ink)
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(DriftPalette.muted)
            }

            if let url = URL(string: "https://drift.app/privacy") {
                Link(destination: url) {
                    Label("Privacy Policy", systemImage: "doc.text")
                        .foregroundStyle(DriftPalette.ink)
                }
            }

            if let url = URL(string: "https://drift.app/terms") {
                Link(destination: url) {
                    Label("Terms of Service", systemImage: "doc.text")
                        .foregroundStyle(DriftPalette.ink)
                }
            }

            if let url = URL(string: "mailto:support@drift.app") {
                Link(destination: url) {
                    Label("Contact Support", systemImage: "envelope")
                        .foregroundStyle(DriftPalette.ink)
                }
            }
        }
    }

    // MARK: - Sign Out

    private var signOutSection: some View {
        Section {
            Button(role: .destructive, action: { showLogoutConfirmation = true }) {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    // MARK: - Actions

    private func syncTransactions() {
        isSyncing = true
        syncResult = nil
        HapticManager.impact(.light)

        Task {
            if AppConfiguration.useMockData {
                try? await Task.sleep(for: .seconds(2))
                isSyncing = false
                syncResult = .success
                HapticManager.notification(.success)
            } else {
                do {
                    try await PlaidService.shared.syncTransactions()
                    isSyncing = false
                    syncResult = .success
                    HapticManager.notification(.success)
                } catch {
                    isSyncing = false
                    syncResult = .failure(error.localizedDescription)
                    HapticManager.notification(.error)
                }
            }

            // Clear result after 3 seconds
            try? await Task.sleep(for: .seconds(3))
            syncResult = nil
        }
    }

    private func initials(for user: UserDTO) -> String {
        if let name = user.displayName, !name.isEmpty {
            let parts = name.split(separator: " ")
            let first = parts.first?.prefix(1) ?? ""
            let last = parts.count > 1 ? parts.last?.prefix(1) ?? "" : ""
            return "\(first)\(last)".uppercased()
        }
        return String(user.email.prefix(1)).uppercased()
    }
}

// MARK: - Enhanced Notification Settings

private struct NotificationSettingsView: View {
    @AppStorage("notificationTime") private var notificationTime = "eightPM"
    @AppStorage("dailySummaryEnabled") private var dailySummary = true
    @AppStorage("weeklyReflectionEnabled") private var weeklyReflection = true
    @AppStorage("leakyBucketAlertsEnabled") private var leakyBucketAlerts = true

    private var selectedTime: String {
        switch notificationTime {
        case "sevenPM": return "7:00 PM"
        case "eightPM": return "8:00 PM"
        case "ninePM": return "9:00 PM"
        default: return "8:00 PM"
        }
    }

    var body: some View {
        List {
            // Time picker
            Section {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Daily reminder time")
                        .font(.subheadline)
                        .foregroundStyle(DriftPalette.ink)

                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(["sevenPM", "eightPM", "ninePM"], id: \.self) { option in
                            let title: String = {
                                switch option {
                                case "sevenPM": return "7 PM"
                                case "eightPM": return "8 PM"
                                case "ninePM": return "9 PM"
                                default: return ""
                                }
                            }()

                            Button {
                                HapticManager.selection()
                                notificationTime = option
                            } label: {
                                Text(title)
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignTokens.Spacing.sm)
                                    .foregroundStyle(notificationTime == option ? DriftPalette.chipText : DriftPalette.ink)
                                    .background {
                                        Capsule()
                                            .fill(notificationTime == option ? DriftPalette.accentDeep : DriftPalette.chip)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } header: {
                Text("Schedule")
            }

            // Toggles
            Section {
                Toggle(isOn: $dailySummary) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily spending summary")
                            .foregroundStyle(DriftPalette.ink)
                        Text("A quick snapshot every evening")
                            .font(.caption)
                            .foregroundStyle(DriftPalette.muted)
                    }
                }
                .tint(DriftPalette.accent)

                Toggle(isOn: $weeklyReflection) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weekly reflection")
                            .foregroundStyle(DriftPalette.ink)
                        Text("Every Sunday at \(selectedTime)")
                            .font(.caption)
                            .foregroundStyle(DriftPalette.muted)
                    }
                }
                .tint(DriftPalette.accent)

                Toggle(isOn: $leakyBucketAlerts) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Leaky bucket alerts")
                            .foregroundStyle(DriftPalette.ink)
                        Text("When your tracked categories spike")
                            .font(.caption)
                            .foregroundStyle(DriftPalette.muted)
                    }
                }
                .tint(DriftPalette.accent)
            } header: {
                Text("Notification types")
            }

            // Preview card
            Section {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(DriftPalette.accent)
                        Text("Drift")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DriftPalette.ink)
                        Spacer()
                        Text("now")
                            .font(.caption)
                            .foregroundStyle(DriftPalette.muted)
                    }

                    Text("Today: $47 -- Uber Eats $32, Amazon $15.")
                        .font(.subheadline)
                        .foregroundStyle(DriftPalette.ink)

                    Text("Delivered at \(selectedTime)")
                        .font(.caption)
                        .foregroundStyle(DriftPalette.muted)
                }
                .padding(.vertical, DesignTokens.Spacing.xs)
            } header: {
                Text("Preview")
            }
        }
        .scrollContentBackground(.hidden)
        .background(DriftBackground(animated: false))
        .navigationTitle("Notifications")
    }
}

// MARK: - Category Settings (Full Implementation)

private struct CategorySettingsView: View {
    @State private var selectedCategories: [CategoryOption] = CategoryOption.loadSelected()

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.Spacing.sm),
        GridItem(.flexible(), spacing: DesignTokens.Spacing.sm),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Your leaky buckets")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundStyle(DriftPalette.ink)

                    Text("Pick 2 to 4 spending categories to track closely.")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(DriftPalette.muted)
                }

                // Count pill
                HStack {
                    Text("\(selectedCategories.count) of 4 selected")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DriftPalette.muted)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background {
                            Capsule().fill(DriftPalette.chip)
                        }
                    Spacer()
                }

                // Category grid
                LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.sm) {
                    ForEach(CategoryOption.allCases) { option in
                        CategoryChipView(
                            option: option,
                            isSelected: selectedCategories.contains(option)
                        ) {
                            toggleCategory(option)
                        }
                    }
                }

                // Selected categories detail
                if !selectedCategories.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Tracked categories")
                            .sectionHeaderStyle()

                        ForEach(selectedCategories) { category in
                            GlassCard(padding: DesignTokens.Spacing.sm) {
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                    HStack(spacing: DesignTokens.Spacing.xs) {
                                        Image(systemName: category.icon)
                                            .foregroundStyle(DriftPalette.accent)
                                        Text(category.title)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(DriftPalette.ink)
                                    }

                                    Text(category.exampleMerchants.joined(separator: " \u{00B7} "))
                                        .font(.caption)
                                        .foregroundStyle(DriftPalette.muted)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.lg)
        }
        .background(DriftBackground(animated: false))
        .navigationTitle("Categories")
    }

    private func toggleCategory(_ option: CategoryOption) {
        HapticManager.selection()

        if let index = selectedCategories.firstIndex(of: option) {
            guard selectedCategories.count > 2 else { return }
            selectedCategories.remove(at: index)
        } else if selectedCategories.count < 4 {
            selectedCategories.append(option)
        } else {
            // Replace oldest selection
            selectedCategories.removeFirst()
            selectedCategories.append(option)
        }

        CategoryOption.saveSelected(selectedCategories)
    }
}

private struct CategoryChipView: View {
    let option: CategoryOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: option.icon)
                Text(option.title)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isSelected ? DriftPalette.chipText : DriftPalette.ink)
            .background {
                Capsule()
                    .fill(isSelected ? DriftPalette.accentDeep : DriftPalette.chip)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Privacy Settings (with Delete All Data wired up)

private struct PrivacySettingsView: View {
    @State private var shareAnalytics = false
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmText = ""
    @State private var isDeleting = false
    @State private var deleteSuccess = false

    var body: some View {
        List {
            Section {
                Toggle("Share Anonymous Analytics", isOn: $shareAnalytics)
                    .tint(DriftPalette.accent)
            } footer: {
                Text("Help us improve Drift by sharing anonymous usage data")
                    .foregroundStyle(DriftPalette.muted)
            }

            Section {
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    HStack {
                        Text("Delete All Data")
                        Spacer()
                        if isDeleting {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isDeleting)
            } footer: {
                Text("This will permanently delete all your data and unlink all accounts")
                    .foregroundStyle(DriftPalette.muted)
            }
        }
        .scrollContentBackground(.hidden)
        .background(DriftBackground(animated: false))
        .navigationTitle("Privacy")
        .alert("Delete All Data", isPresented: $showDeleteConfirmation) {
            TextField("Type DELETE to confirm", text: $deleteConfirmText)
            Button("Delete Everything", role: .destructive) {
                guard deleteConfirmText == "DELETE" else { return }
                performDeletion()
            }
            Button("Cancel", role: .cancel) {
                deleteConfirmText = ""
            }
        } message: {
            Text("This action cannot be undone. Type DELETE to confirm.")
        }
        .alert("Data Deleted", isPresented: $deleteSuccess) {
            Button("OK") {}
        } message: {
            Text("All your data has been deleted. The app will reset.")
        }
    }

    private func performDeletion() {
        isDeleting = true
        HapticManager.notification(.warning)

        Task {
            if AppConfiguration.useMockData {
                // Clear UserDefaults
                if let bundleId = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: bundleId)
                }
                try? await Task.sleep(for: .seconds(1))
                isDeleting = false
                deleteSuccess = true
                HapticManager.notification(.success)
            } else {
                do {
                    // Call backend delete endpoint
                    let api = APIClient.shared
                    let _: DeleteAccountResponse = try await api.delete("/api/v1/auth/account")

                    // Clear local data
                    try? await KeychainService.shared.deleteAll()
                    if let bundleId = Bundle.main.bundleIdentifier {
                        UserDefaults.standard.removePersistentDomain(forName: bundleId)
                    }

                    // Trigger logout to reset app state reactively
                    await AuthService.shared.logout()

                    isDeleting = false
                    deleteSuccess = true
                    HapticManager.notification(.success)
                } catch {
                    isDeleting = false
                    HapticManager.notification(.error)
                }
            }

            deleteConfirmText = ""
        }
    }
}

private struct DeleteAccountResponse: Decodable {}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
