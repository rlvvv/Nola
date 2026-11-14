import SwiftUI
import UIKit

enum NolaTheme {
    static let background = adaptive(
        light: UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1),
        dark: UIColor(red: 0.08, green: 0.075, blue: 0.10, alpha: 1)
    )
    static let surface = adaptive(
        light: UIColor.white,
        dark: UIColor(red: 0.13, green: 0.12, blue: 0.16, alpha: 1)
    )
    static let raisedSurface = adaptive(
        light: UIColor(red: 0.99, green: 0.985, blue: 0.97, alpha: 1),
        dark: UIColor(red: 0.17, green: 0.16, blue: 0.21, alpha: 1)
    )
    static let text = adaptive(
        light: UIColor(red: 0.19, green: 0.18, blue: 0.24, alpha: 1),
        dark: UIColor(red: 0.94, green: 0.93, blue: 0.97, alpha: 1)
    )
    static let secondaryText = adaptive(
        light: UIColor(red: 0.40, green: 0.39, blue: 0.44, alpha: 1),
        dark: UIColor(red: 0.73, green: 0.71, blue: 0.78, alpha: 1)
    )
    static let cardBorder = adaptive(
        light: UIColor(red: 0.87, green: 0.86, blue: 0.83, alpha: 1),
        dark: UIColor(red: 0.24, green: 0.23, blue: 0.27, alpha: 1)
    )
    static let accent = adaptive(
        light: UIColor(red: 0.05, green: 0.35, blue: 0.27, alpha: 1),
        dark: UIColor(red: 0.30, green: 0.72, blue: 0.57, alpha: 1)
    )
    static let accentStrong = adaptive(
        light: UIColor(red: 0.035, green: 0.27, blue: 0.21, alpha: 1),
        dark: UIColor(red: 0.20, green: 0.56, blue: 0.42, alpha: 1)
    )
    static let accentSoft = adaptive(
        light: UIColor(red: 0.87, green: 0.94, blue: 0.90, alpha: 1),
        dark: UIColor(red: 0.13, green: 0.25, blue: 0.20, alpha: 1)
    )
    static let warmSoft = adaptive(
        light: UIColor(red: 0.93, green: 0.91, blue: 0.86, alpha: 1),
        dark: UIColor(red: 0.25, green: 0.23, blue: 0.20, alpha: 1)
    )

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

