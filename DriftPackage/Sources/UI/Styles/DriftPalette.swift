import SwiftUI
import UIKit

/// App-wide palette for the "daily mirror" visual language
public enum DriftPalette {
    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    public static let ink = dynamicColor(
        light: UIColor(red: 0.10, green: 0.13, blue: 0.19, alpha: 1.0),
        dark: UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1.0)
    )
    public static let muted = dynamicColor(
        light: UIColor(red: 0.46, green: 0.50, blue: 0.56, alpha: 1.0),
        dark: UIColor(red: 0.70, green: 0.74, blue: 0.79, alpha: 1.0)
    )

    public static let accent = dynamicColor(
        light: UIColor(red: 0.24, green: 0.53, blue: 0.78, alpha: 1.0),
        dark: UIColor(red: 0.42, green: 0.70, blue: 0.92, alpha: 1.0)
    )
    public static let accentDeep = dynamicColor(
        light: UIColor(red: 0.16, green: 0.39, blue: 0.66, alpha: 1.0),
        dark: UIColor(red: 0.28, green: 0.56, blue: 0.86, alpha: 1.0)
    )

    public static let mist = dynamicColor(
        light: UIColor(red: 0.92, green: 0.96, blue: 0.99, alpha: 1.0),
        dark: UIColor(red: 0.06, green: 0.08, blue: 0.11, alpha: 1.0)
    )
    public static let warm = dynamicColor(
        light: UIColor(red: 0.98, green: 0.95, blue: 0.93, alpha: 1.0),
        dark: UIColor(red: 0.10, green: 0.11, blue: 0.13, alpha: 1.0)
    )
    public static let ocean = dynamicColor(
        light: UIColor(red: 0.66, green: 0.82, blue: 0.96, alpha: 1.0),
        dark: UIColor(red: 0.12, green: 0.18, blue: 0.26, alpha: 1.0)
    )

    public static let chip = dynamicColor(
        light: UIColor(red: 0.93, green: 0.94, blue: 0.96, alpha: 1.0),
        dark: UIColor(red: 0.16, green: 0.19, blue: 0.24, alpha: 1.0)
    )
    public static let chipText = Color.white
    public static let track = dynamicColor(
        light: UIColor.black.withAlphaComponent(0.12),
        dark: UIColor.white.withAlphaComponent(0.16)
    )

    public static let sunset = dynamicColor(
        light: UIColor(red: 0.95, green: 0.64, blue: 0.52, alpha: 1.0),
        dark: UIColor(red: 0.96, green: 0.66, blue: 0.56, alpha: 1.0)
    )
    public static let sunsetDeep = dynamicColor(
        light: UIColor(red: 0.89, green: 0.46, blue: 0.43, alpha: 1.0),
        dark: UIColor(red: 0.93, green: 0.50, blue: 0.46, alpha: 1.0)
    )

    public static let sage = dynamicColor(
        light: UIColor(red: 0.52, green: 0.66, blue: 0.55, alpha: 1.0),
        dark: UIColor(red: 0.60, green: 0.74, blue: 0.64, alpha: 1.0)
    )
    public static let sageDeep = dynamicColor(
        light: UIColor(red: 0.41, green: 0.55, blue: 0.46, alpha: 1.0),
        dark: UIColor(red: 0.48, green: 0.64, blue: 0.54, alpha: 1.0)
    )
}
