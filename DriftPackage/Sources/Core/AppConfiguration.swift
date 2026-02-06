import Foundation

/// Centralized app configuration for compile-time flags
public enum AppConfiguration {
    #if MOCK_DATA
    public static let useMockData = true
    #else
    public static let useMockData = false
    #endif

    /// When true, shows onboarding flow even in mock mode (for testing onboarding UI)
    /// Set to false to skip onboarding when using mock data
    public static let showOnboardingInMockMode = true
}
