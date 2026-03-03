//
//  SharedTimerViews.swift
//  WODrounds
//
//  Shared components for iOS, macOS and tvOS – reduces duplication.
//

import SwiftUI

#if os(iOS) || os(macOS) || os(tvOS)

// MARK: - Shared helpers

func sharedTimeString(from interval: TimeInterval) -> String {
    let totalSeconds = max(0, Int(ceil(interval)))
    let m = totalSeconds / 60
    let s = totalSeconds % 60
    return String(format: "%02d:%02d", m, s)
}

func sharedRoundLabel(snapshot: WODTimerEngineSnapshot, totalRounds: Int) -> String {
    "Round \(snapshot.currentRound) / \(totalRounds) Rounds"
}

func sharedFormatEmomLength(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}

// MARK: - Theme types (sizes/spacing; colours from DesignTokens + scheme)

struct DoneViewTheme {
    var checkmarkSize: CGFloat
    var titleSize: CGFloat
    var bodySize: CGFloat
    var verticalSpacing: CGFloat
}

struct StepperTheme {
    var labelFontSize: CGFloat
    var valueFontSize: CGFloat
    var buttonSize: CGFloat
    var cornerRadius: CGFloat
    var stackSpacing: CGFloat
    var verticalPadding: CGFloat
}

struct PrimaryButtonTheme {
    var titleSize: CGFloat
    var verticalPadding: CGFloat
    var horizontalPadding: CGFloat
    var cornerRadius: CGFloat
}

struct CancelButtonTheme {
    var titleSize: CGFloat
    var verticalPadding: CGFloat
    var horizontalPadding: CGFloat
    var cornerRadius: CGFloat
}

struct ModeSwitchTheme {
    var fontSize: CGFloat
    var horizontalPadding: CGFloat
    var verticalPadding: CGFloat
    var spacing: CGFloat
    var cornerRadius: CGFloat
    /// true = tvOS: .card + focusEffectDisabled
    var useCardStyle: Bool = false
}

// MARK: - SharedDoneView

struct SharedDoneView: View {
    var totalRounds: Int
    var theme: DoneViewTheme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: theme.verticalSpacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: theme.checkmarkSize, weight: .medium))
                .foregroundStyle(DesignTokens.Common.primary(scheme))
            Text("Done")
                .font(.system(size: theme.titleSize, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
            Text("You completed \(totalRounds) round\(totalRounds == 1 ? "" : "s")")
                .font(.system(size: theme.bodySize, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
        }
        .padding(.vertical, theme.verticalSpacing)
    }
}

// MARK: - SharedStepperView (single value + −/+; optional long-press repeat on iOS)

struct SharedStepperView: View {
    @Binding var value: Int
    var range: ClosedRange<Int>
    var step: Int = 1
    var displayString: String? = nil
    var label: String
    var onChange: () -> Void
    var theme: StepperTheme
    var useLongPressRepeat: Bool

    @Environment(\.colorScheme) private var scheme
    @State private var repeatWorkItem: DispatchWorkItem?
    @State private var repeatStartTime: Date?
    @State private var repeatCancelled = false

    var body: some View {
        VStack(spacing: theme.stackSpacing) {
            Text(label)
                .font(.system(size: theme.labelFontSize, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))

            HStack(spacing: theme.stackSpacing) {
                stepperButton(sign: -1)
                Text(displayString ?? "\(value)")
                    .font(.system(size: theme.valueFontSize, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: displayString != nil ? max(theme.buttonSize * 2, theme.valueFontSize * 1.9) : theme.buttonSize * 2)
                    .padding(.horizontal, displayString != nil ? DesignTokens.Spacing.lg : 0)
                stepperButton(sign: 1)
            }
            .padding(.vertical, theme.verticalPadding)
        }
    }

    private func stepperButton(sign: Int) -> some View {
        let label = sign < 0 ? "−" : "+"
        return Button {
            stepValue(by: sign)
        } label: {
            Text(label)
                .font(.system(size: theme.valueFontSize * 0.75, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .frame(width: theme.buttonSize, height: theme.buttonSize)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
        }
        .buttonStyle(.plain)
        .modifier(LongPressRepeatModifier(enabled: useLongPressRepeat, sign: sign, onPressStart: { startRepeat(by: $0) }, onPressEnd: stopRepeat))
    }

    private func stepValue(by direction: Int) {
        let delta = direction * step
        value = max(range.lowerBound, min(range.upperBound, value + delta))
        onChange()
    }

    private func startRepeat(by direction: Int) {
        stopRepeat()
        repeatCancelled = false
        repeatStartTime = Date()
        func scheduleNext(interval: TimeInterval) {
            guard !repeatCancelled else { return }
            let item = DispatchWorkItem {
                guard !repeatCancelled else { return }
                stepValue(by: direction)
                let elapsed = repeatStartTime.map { Date().timeIntervalSince($0) } ?? 0
                let nextInterval: TimeInterval = elapsed > 0.8 ? 0.12 : 0.35
                scheduleNext(interval: nextInterval)
            }
            repeatWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: item)
        }
        scheduleNext(interval: 0.35)
    }

    private func stopRepeat() {
        repeatCancelled = true
        repeatWorkItem?.cancel()
        repeatWorkItem = nil
    }
}

// Long-press modifier so tvOS/macOS don't need repeat logic in view
private struct LongPressRepeatModifier: ViewModifier {
    var enabled: Bool
    var sign: Int
    var onPressStart: (Int) -> Void
    var onPressEnd: () -> Void

    func body(content: Content) -> some View {
        if enabled {
            content
                .onLongPressGesture(minimumDuration: 0.4, pressing: { pressing in
                    if pressing {
                        onPressStart(sign)
                    } else {
                        onPressEnd()
                    }
                }) {}
        } else {
            content
        }
    }
}

// MARK: - SharedPrimaryButton

struct SharedPrimaryButton: View {
    var title: String
    var action: () -> Void
    var theme: PrimaryButtonTheme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: theme.titleSize, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .contentTransition(.interpolate)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.verticalPadding)
                .padding(.horizontal, theme.horizontalPadding)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SharedCancelButton

struct SharedCancelButton: View {
    var action: () -> Void
    var theme: CancelButtonTheme

    var body: some View {
        Button(action: action) {
            Text("Cancel")
                .font(.system(size: theme.titleSize, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.ColorToken.State.onError)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.verticalPadding)
                .padding(.horizontal, theme.horizontalPadding)
                .background(DesignTokens.ColorToken.State.error)
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SharedModeSwitch

struct SharedModeSwitch: View {
    @Binding var timerMode: TimerUIMode
    var onModeChange: () -> Void
    var theme: ModeSwitchTheme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: theme.spacing) {
            ForEach(TimerUIMode.allCases, id: \.self) { mode in
                modeButton(mode: mode)
            }
        }
    }

    @ViewBuilder
    private func modeButton(mode: TimerUIMode) -> some View {
        let button = Button {
            timerMode = mode
            onModeChange()
        } label: {
            Text(mode.rawValue)
                .font(.system(size: theme.fontSize, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(timerMode == mode ? DesignTokens.Common.onPrimary(scheme) : DesignTokens.Common.Text.primary(scheme))
                .padding(.horizontal, theme.horizontalPadding)
                .padding(.vertical, theme.verticalPadding)
                .background(timerMode == mode ? DesignTokens.Common.primary(scheme) : DesignTokens.Common.Background.card(scheme))
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
        }
        if theme.useCardStyle {
            #if os(tvOS)
            button
                .buttonStyle(.card)
                .focusEffectDisabled()
            #else
            button
                .buttonStyle(.plain)
            #endif
        } else {
            button
                .buttonStyle(.plain)
        }
    }
}

#endif
