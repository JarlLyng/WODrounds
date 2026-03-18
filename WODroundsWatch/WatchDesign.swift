//
//  WatchDesign.swift
//  WODrounds Watch App
//
//  Watch-specific design tokens. Imports colors from the IAMJARL design system
//  package and defines scaled spacing and typography for the small screen.
//

import SwiftUI
import IAMJARLDesignTokens

enum WatchDesign {
    // Spacing scaled down for watch (roughly half of main app values)
    enum Spacing {
        static let xs: CGFloat = 2
        static let sm: CGFloat = 4
        static let md: CGFloat = 6
        static let lg: CGFloat = 8
        static let xl: CGFloat = 10
    }

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
    }

    /// Watch-specific font sizes
    static let timerFontSize: CGFloat = 34
    static let roundFontSize: CGFloat = 12
    static let buttonFontSize: CGFloat = 14
    static let countdownTitleFontSize: CGFloat = 13
    static let countdownNumberFontSize: CGFloat = 28

    /// Colors from the IAMJARL design system package
    enum Colors {
        static func primary(_ scheme: ColorScheme) -> Color {
            DesignTokens.Common.primary(scheme)
        }
        static var onPrimary: Color {
            DesignTokens.ColorToken.Static.black
        }
        static func textPrimary(_ scheme: ColorScheme) -> Color {
            DesignTokens.Common.Text.primary(scheme)
        }
        static func textSecondary(_ scheme: ColorScheme) -> Color {
            DesignTokens.Common.Text.secondary(scheme)
        }
        static func textTertiary(_ scheme: ColorScheme) -> Color {
            DesignTokens.Common.Text.tertiary(scheme)
        }
        static func background(_ scheme: ColorScheme) -> Color {
            DesignTokens.Common.Background.app(scheme)
        }
    }
}
