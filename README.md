# Drift

**The anti-budgeting spending awareness app for iOS.**

No budgets. No guilt. Just daily awareness. Drift shows you where your money quietly drifts -- not to shame you, but to help you see it clearly.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Backend Setup](#backend-setup)
- [Mock Mode](#mock-mode)
- [Design System](#design-system)
- [Project Structure](#project-structure)
- [Security](#security)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

---

## Features

| Feature                      | Description                                                        |
|------------------------------|--------------------------------------------------------------------|
| **Bank Connection**          | Connect bank accounts securely via Plaid Link                      |
| **Daily Spending Mirror**    | See today's spending at a glance with category breakdown           |
| **Weekly Visual Summaries**  | Daily spending charts, top merchants, and week-over-week comparison|
| **Monthly Overview**         | Monthly heatmap, weekly breakdown, and top spending categories     |
| **Leaky Bucket Detection**   | Identifies recurring spending patterns that quietly drain your money|
| **Push Notifications**       | Daily and weekly spending summaries delivered to your device        |
| **Biometric Authentication** | Face ID and Touch ID support for app lock                          |
| **Data Export**              | Export your transactions to CSV for personal analysis               |
| **Account Deletion**         | Full account and data deletion for privacy compliance (CCPA)       |
| **Dark Mode**                | Full dark mode support with adaptive color system                  |
| **Onboarding Flow**          | Guided setup for new users                                         |

---

## Tech Stack

| Component       | Technology                                    |
|-----------------|-----------------------------------------------|
| **iOS App**     | SwiftUI, iOS 18+, Swift 6.0                   |
| **Backend**     | Vapor 4 (Swift), PostgreSQL, JWT              |
| **Banking**     | Plaid Link SDK for iOS                        |
| **Package Mgmt**| Swift Package Manager (SPM)                   |
| **Auth**        | JWT access tokens + Bcrypt refresh tokens     |
| **Database**    | PostgreSQL 14+ with Fluent ORM                |

---

## Architecture

Drift uses a modular architecture with the main app target and a local Swift Package (`DriftPackage`) containing all feature code.

### App Targets

```
Drift/                  # Main iOS app target
  DriftApp.swift        # @main entry point, lifecycle, biometric lock
  AppState.swift        # Global app state management (singleton)
  ContentView.swift     # Root TabView with Spending, Leaks, Settings tabs
  Assets.xcassets/      # App icons and colors

DriftPackage/           # Local SPM package (all feature code)
  Sources/
    Core/               # Shared models, DTOs, extensions, configuration
    UI/                 # Design system, reusable components, styles
    Services/           # API client, auth, Plaid, transactions, biometrics
    Features/           # Feature-specific views and view models
```

### DriftPackage Modules

| Module       | Purpose                                                              |
|--------------|----------------------------------------------------------------------|
| **Core**     | Data models (`Transaction`, `Account`, `SpendingSummary`, `LeakyBucket`), DTOs, extensions, `AppConfiguration` |
| **UI**       | Design system (`DriftPalette`, `DesignTokens`), reusable components (`GlassCard`, `DriftBackground`, `SpendingRing`, charts), button styles, haptics |
| **Services** | `APIClient`, `AuthService`, `PlaidService`, `TransactionService`, `BiometricService`, `KeychainService`, `LeakyBucketDetector`, `SmartCategorizerService` |
| **Features** | `SpendingView`, `LeakyBucketsView`, `SettingsView`, `LoginView`, `RegisterView`, `OnboardingView`, `LinkAccountView` and their ViewModels |

### Module Dependency Graph

```
Features --> Core, UI, Services
Services --> Core
UI       --> Core
Core     --> (no internal dependencies)
```

### App Navigation

The main `ContentView` uses a `TabView` with three tabs:

| Tab         | View              | Description                             |
|-------------|-------------------|-----------------------------------------|
| Spending    | `SpendingView`    | Unified daily/weekly/monthly spending view with period navigation |
| Leaks       | `LeakyBucketsView`| Recurring spending pattern detection    |
| Settings    | `SettingsView`    | Account, preferences, export, about     |

---

## Getting Started

### Requirements

| Requirement  | Minimum Version |
|-------------|-----------------|
| Xcode       | 16+             |
| iOS         | 18.0+           |
| Swift       | 6.0 (tools 6.0) |
| macOS       | 14+ (for development) |

### Steps

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Drift
   ```

2. **Open the Xcode project:**
   ```bash
   open Drift.xcodeproj
   ```
   Xcode will automatically resolve the local `DriftPackage` SPM dependency.

3. **Select a target device:**
   Choose an iPhone simulator running iOS 18+ or a physical device.

4. **Build and run:**
   Press `Cmd+R` or use the play button.

### Mock Mode (Recommended for First Run)

For development and testing without a backend, Drift supports a mock data mode. See the [Mock Mode](#mock-mode) section below.

### Production Mode

To connect to a live backend:

1. Set `useMockData = false` in `DriftPackage/Package.swift`.
2. Configure the backend URL in `APIClient` (`DriftPackage/Sources/Services/APIClient.swift`).
3. Ensure the backend is running (see [Backend Setup](#backend-setup)).

---

## Backend Setup

The Drift backend is a Vapor 4 Swift server providing REST APIs for authentication, Plaid integration, transactions, and more.

Full backend documentation is available at: [DriftBackend/README.md](DriftBackend/README.md)

### Quick Backend Start

```bash
cd DriftBackend

# Set required environment variables
export JWT_SECRET="your-secret-key"
export PLAID_CLIENT_ID="your-plaid-client-id"
export PLAID_SECRET="your-plaid-secret"
export PLAID_ENV="sandbox"

# Run (auto-migrates in development)
swift run App serve --env development
```

---

## Mock Mode

Drift includes a compile-time mock data system for development and testing without a running backend or Plaid credentials.

### How It Works

1. **Compile flag**: The `MOCK_DATA` Swift compiler flag is controlled by the `useMockData` variable in `DriftPackage/Package.swift`:

   ```swift
   // Set to true for mock data, false for real API calls
   let useMockData = true
   ```

2. **Runtime check**: The `AppConfiguration` enum exposes the flag at runtime:

   ```swift
   public enum AppConfiguration {
       #if MOCK_DATA
       public static let useMockData = true
       #else
       public static let useMockData = false
       #endif
   }
   ```

3. **Service behavior**: When `useMockData` is `true`:
   - Services return pre-built sample data instead of making network calls.
   - Authentication is skipped (user is automatically "logged in").
   - Bank linking is simulated with sample accounts.
   - Biometric lock is disabled.
   - Push notification registration is skipped.

4. **Onboarding control**: `AppConfiguration.showOnboardingInMockMode` controls whether the onboarding flow is shown in mock mode (defaults to `true` for UI testing).

### Toggling Mock Mode

1. Open `DriftPackage/Package.swift`.
2. Change `let useMockData = true` to `false` (or vice versa).
3. Clean and rebuild the project (`Cmd+Shift+K`, then `Cmd+B`).

---

## Design System

Drift uses a custom design system built around a calm, reflective visual language. The system adapts seamlessly between light and dark mode.

### DriftPalette

Defined in `DriftPackage/Sources/UI/Styles/DriftPalette.swift`. All colors are dynamic, adapting to the user's light/dark mode preference.

| Token        | Light Mode Purpose       | Usage                             |
|-------------|--------------------------|-----------------------------------|
| `ink`       | Dark text                | Primary text, headings             |
| `muted`     | Secondary text           | Subtitles, captions                |
| `accent`    | Blue highlight           | Interactive elements, links, icons |
| `accentDeep`| Deeper blue              | Pressed states, emphasis           |
| `mist`      | Light blue background    | Card backgrounds, sections         |
| `warm`      | Warm off-white           | Alternate backgrounds              |
| `ocean`     | Light blue tint          | Decorative backgrounds             |
| `chip`      | Light gray               | Chip/tag backgrounds               |
| `sunset`    | Coral/orange             | Warning states, spending highlights|
| `sunsetDeep`| Deeper coral             | Alert emphasis                     |
| `sage`      | Green                    | Income, positive indicators        |
| `sageDeep`  | Deeper green             | Positive emphasis                  |

### DesignTokens

Defined in `DriftPackage/Sources/UI/Styles/DesignTokens.swift`. Provides consistent spacing, typography, corner radii, animation timing, and shadow styles.

**Spacing:**

| Token          | Value  | Usage                    |
|----------------|--------|--------------------------|
| `xxs`          | 4pt    | Tight spacing            |
| `xs`           | 8pt    | Small gaps               |
| `sm`           | 12pt   | Compact spacing          |
| `md`           | 16pt   | Standard spacing         |
| `lg`           | 24pt   | Section spacing          |
| `xl`           | 32pt   | Large gaps               |
| `xxl`          | 48pt   | Extra-large gaps         |
| `cardPadding`  | 20pt   | Card internal padding    |
| `sectionSpacing` | 32pt | Between sections        |

**Corner Radii:**

| Token  | Value  |
|--------|--------|
| `sm`   | 8pt    |
| `md`   | 12pt   |
| `lg`   | 16pt   |
| `xl`   | 20pt   |
| `card` | 22pt   |
| `pill` | 999pt  |

**Animation Durations:**

| Token    | Value   |
|----------|---------|
| `fast`   | 0.15s   |
| `normal` | 0.25s   |
| `slow`   | 0.4s    |
| `spring` | response: 0.35, damping: 0.85 |
| `bouncy` | response: 0.5, damping: 0.7   |

### Key UI Components

| Component            | Description                                               |
|----------------------|-----------------------------------------------------------|
| `GlassCard`          | Frosted glass card with blur effect and subtle borders    |
| `GlassButtonStyle`   | Glass-effect button styles (`.glassProminentPill`, etc.)  |
| `DriftBackground`    | Animated gradient background for the app                  |
| `SpendingRing`       | Circular progress ring for spending visualization         |
| `DriftBarChart`      | Custom bar chart for daily/weekly spending                |
| `DriftLineChart`     | Custom line chart for trend visualization                 |
| `LeakyBucketCard`    | Card displaying recurring spending pattern                |
| `CategoryIcon`       | Category-colored icon component                           |
| `ShimmerView`        | Loading shimmer/skeleton animation                        |
| `SectionHeader`      | Uppercase tracked section header with muted styling       |

---

## Project Structure

```
Drift/
  Drift/                          # Main iOS app target
    DriftApp.swift                # App entry point, lifecycle management
    AppState.swift                # Global state: auth, onboarding, loading
    ContentView.swift             # Root TabView (Spending, Leaks, Settings)
    Assets.xcassets/              # App icon, accent color

  DriftPackage/                   # Local Swift Package
    Package.swift                 # SPM manifest with mock data toggle
    Sources/
      Core/
        AppConfiguration.swift    # Compile-time configuration flags
        Models/
          Transaction.swift       # Transaction data model
          Account.swift           # Bank account model
          LeakyBucket.swift       # Recurring spending pattern model
          SpendingSummary.swift   # Summary data model
          SpendingCategory.swift  # Category definition
          CategoryOption.swift    # Category selection option
        DTOs/
          AuthDTOs.swift          # Auth request/response types
          TransactionDTOs.swift   # Transaction request/response types
          SummaryDTOs.swift       # Summary request/response types
        Extensions/
          Date+Extensions.swift   # Date helper extensions
          Decimal+Extensions.swift # Decimal formatting

      UI/
        Styles/
          DriftPalette.swift      # Color palette (light/dark adaptive)
          DesignTokens.swift      # Spacing, corners, typography, animation
          GlassButtonStyle.swift  # Glass effect button styles
        Components/
          GlassCard.swift         # Frosted glass card component
          DriftBackground.swift   # Animated app background
          SpendingRing.swift      # Circular spending indicator
          LeakyBucketCard.swift   # Leaky bucket display card
          CategoryIcon.swift      # Category icon component
          AmountText.swift        # Formatted amount text
          SectionHeader.swift     # Section header component
          ShimmerView.swift       # Loading skeleton animation
          Charts/
            DriftBarChart.swift   # Custom bar chart
            DriftLineChart.swift  # Custom line chart
        Modifiers/
          GlassModifiers.swift    # Glass effect view modifiers
        Haptics/
          HapticManager.swift     # Haptic feedback manager

      Services/
        APIClient.swift           # HTTP networking client
        AuthService.swift         # Authentication service
        PlaidService.swift        # Plaid bank linking service
        TransactionService.swift  # Transaction data service
        BiometricService.swift    # Face ID / Touch ID service
        KeychainService.swift     # Keychain token storage
        LeakyBucketDetector.swift # Recurring pattern detection
        SmartCategorizerService.swift # Transaction categorization

      Features/
        Auth/
          LoginView.swift         # Login screen
          RegisterView.swift      # Registration screen
          AuthViewModel.swift     # Auth view model
        Spending/
          SpendingView.swift      # Unified spending view
          SpendingViewModel.swift # Spending data management
          Components/
            SpendingHeroCard.swift     # Main spending amount card
            SpendingChart.swift        # Spending chart component
            CategoryBreakdownSection.swift  # Category breakdown
            TopItemsSection.swift      # Top transactions/merchants
            TimePeriodPicker.swift     # Day/Week/Month selector
            PeriodNavigator.swift      # Navigate between periods
            TransactionDetailSheet.swift  # Transaction detail modal
            SpendingInsightCard.swift  # Insight/comparison card
        LeakyBuckets/
          LeakyBucketsView.swift       # Leaky buckets screen
          LeakyBucketsViewModel.swift  # Leaky bucket detection VM
        LinkAccount/
          LinkAccountView.swift        # Bank linking screen
          LinkAccountViewModel.swift   # Plaid Link view model
        Onboarding/
          OnboardingView.swift         # Onboarding flow
        Settings/
          SettingsView.swift           # Settings screen

  DriftBackend/                   # Vapor 4 backend (separate package)
    Sources/App/                  # Server source code
    Tests/AppTests/               # Backend tests
    Package.swift                 # Backend SPM manifest
```

---

## Security

### Authentication Token Storage

- Access tokens and refresh tokens are stored securely in the iOS **Keychain** via `KeychainService`.
- Tokens are never stored in `UserDefaults` or on disk in plaintext.

### Biometric Authentication

- Drift supports **Face ID** and **Touch ID** for app lock via `BiometricService`.
- Biometric lock is automatically engaged when the app enters the foreground (configurable in settings).
- Biometric authentication is disabled in mock mode.

### Network Security

- All API communication uses HTTPS.
- JWT access tokens expire after 1 hour; refresh tokens after 30 days.
- The backend enforces per-user rate limiting (100 req/min authenticated, 20 req/min unauthenticated).

### Data Privacy

- Full account deletion is supported, removing all user data from the server (CCPA compliance).
- Transaction data export allows users to take their data with them.
- Plaid Link handles bank credentials directly -- Drift never sees or stores banking passwords.

---

## Testing

### iOS App Tests

```bash
# Run from Xcode
# Product > Test (Cmd+U)

# Or via command line
xcodebuild test -project Drift.xcodeproj -scheme Drift -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Backend Tests

```bash
cd DriftBackend
swift test
```

### Mock Mode Testing

Set `useMockData = true` in `DriftPackage/Package.swift` to test the full UI flow without a backend. This is the recommended approach for UI development and design iteration.

---

## Contributing

### Code Style Guidelines

- **SwiftUI views**: Use `struct` for views, `@StateObject` or `@State` for local state, `@ObservedObject` for injected state.
- **Architecture**: Follow MVVM within the Features module. ViewModels go in the same feature folder as their views.
- **Design system**: Always use `DriftPalette` colors and `DesignTokens` spacing/corner radii. Do not use hardcoded colors or magic numbers.
- **Naming**: Use descriptive names. Views end in `View`, ViewModels end in `ViewModel`, services end in `Service`.
- **Concurrency**: Use Swift's structured concurrency (`async`/`await`, `@MainActor`). Services that require thread safety should use the `actor` pattern.
- **Module boundaries**: Keep `Core` free of UI imports. `UI` should not import `Services` or `Features`. `Features` can import everything.
- **Mock data**: When adding new services, provide mock implementations gated behind `#if MOCK_DATA` or `AppConfiguration.useMockData`.

### Pull Request Process

1. Create a feature branch from `main`.
2. Ensure the project builds in both mock and production modes.
3. Run all tests and verify they pass.
4. Include screenshots for UI changes.
5. Keep PRs focused on a single feature or fix.

---

## License

TBD
