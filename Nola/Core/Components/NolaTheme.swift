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
    static let accent = adaptive(
        light: UIColor(red: 0.42, green: 0.38, blue: 0.72, alpha: 1),
        dark: UIColor(red: 0.72, green: 0.67, blue: 0.98, alpha: 1)
    )
    static let accentStrong = Color(red: 0.36, green: 0.32, blue: 0.65)
    static let accentSoft = adaptive(
        light: UIColor(red: 0.92, green: 0.90, blue: 0.97, alpha: 1),
        dark: UIColor(red: 0.24, green: 0.21, blue: 0.34, alpha: 1)
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

