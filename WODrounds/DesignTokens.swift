//
//  DesignTokens.swift
//  WODrounds
//
//  Re-exports IAMJARL design tokens from the SPM package and adds app-specific extensions.
//  Package: https://github.com/jarllyng/iamjarl-design
//

import SwiftUI
@_exported import IAMJARLDesignTokens

// MARK: - App-Specific Convenience Accessors

extension DesignTokens.Common {
    /// Shorthand for `OnPrimary.text(scheme)` — matches the API the app uses.
    static func onPrimary(_ scheme: ColorScheme) -> Color {
        OnPrimary.text(scheme)
    }
}

// MARK: - App-Specific Typography Extensions

extension DesignTokens.Typography.Size {
    /// Dominant timer readout (EMOM); not in tokens.json, app-specific.
    static let display: CGFloat = 80
    /// Rounds / minutes selector; not in tokens.json, app-specific.
    static let title: CGFloat = 56
}
