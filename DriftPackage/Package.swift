// swift-tools-version: 6.0
import PackageDescription

// MOCK_DATA flag: Set to true for mock data, false for real API calls
// To toggle: Change this value and rebuild
let useMockData = false

// Swift settings for mock data flag
let mockDataSwiftSettings: [SwiftSetting] = useMockData ? [.define("MOCK_DATA")] : []

let package = Package(
    name: "DriftPackage",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "UI", targets: ["UI"]),
        .library(name: "Services", targets: ["Services"]),
        .library(name: "Features", targets: ["Features"]),
    ],
    dependencies: [
        .package(url: "https://github.com/plaid/plaid-link-ios.git", from: "6.0.0"),
    ],
    targets: [
        .target(
            name: "Core",
            path: "Sources/Core",
            swiftSettings: mockDataSwiftSettings
        ),
        .target(
            name: "UI",
            dependencies: ["Core"],
            path: "Sources/UI",
            swiftSettings: mockDataSwiftSettings
        ),
        .target(
            name: "Services",
            dependencies: [
                "Core",
                .product(name: "LinkKit", package: "plaid-link-ios"),
            ],
            path: "Sources/Services",
            swiftSettings: mockDataSwiftSettings
        ),
        .target(
            name: "Features",
            dependencies: ["Core", "UI", "Services"],
            path: "Sources/Features",
            swiftSettings: mockDataSwiftSettings
        ),
    ]
)
