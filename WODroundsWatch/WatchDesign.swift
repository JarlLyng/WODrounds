//
//  WatchDesign.swift
//  WODrounds Watch App
//
//  Design tokens aligned with main app (IAMJARL) – watchOS.
//

import SwiftUI

enum WatchDesign {
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

    /// Timer readout on watch – large and legible
    static let timerFontSize: CGFloat = 34
    static let roundFontSize: CGFloat = 12
    static let buttonFontSize: CGFloat = 14
    static let countdownTitleFontSize: CGFloat = 13
    static let countdownNumberFontSize: CGFloat = 28

    enum Colors {
        static let primaryLight = Color(red: 0.808, green: 0.388, blue: 1.0) // #CE63FF
        static let primaryDark = Color(red: 0.82, green: 1, blue: 0)       // #D0FF00
        static let onPrimary = Color.black
        static let textPrimaryLight = Color.black
        static let textPrimaryDark = Color.white
        static let textSecondaryLight = Color(white: 0, opacity: 0.7)
        static let textSecondaryDark = Color(white: 1, opacity: 0.75)
        static let textTertiaryLight = Color(white: 0, opacity: 0.55)
        static let textTertiaryDark = Color(white: 1, opacity: 0.6)
        static let backgroundLight = Color.white
        static let backgroundDark = Color.black

        static func primary(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? primaryDark : primaryLight
        }
        static func textPrimary(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? textPrimaryDark : textPrimaryLight
        }
        static func textSecondary(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? textSecondaryDark : textSecondaryLight
        }
        static func textTertiary(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? textTertiaryDark : textTertiaryLight
        }
        static func background(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? backgroundDark : backgroundLight
        }
    }
}
