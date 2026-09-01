//
//  SharedTimerViews.swift
//  WODrounds
//
//  Shared components for iOS, macOS and tvOS – reduces duplication.
//

import SwiftUI

#if os(iOS) || os(macOS) || os(tvOS)

// MARK: - Compatibility shims

extension View {
    /// Applies `focusEffectDisabled()` on tvOS 17+. On tvOS 16, the system focus
    /// indicator remains visible (acceptable fallback). No-op on non-tvOS platforms.
    @ViewBuilder
    func focusEffectDisabledCompat() -> some View {
        #if os(tvOS)
        if #available(tvOS 17.0, *) {
            self.focusEffectDisabled()
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// Applies `contentTransition(.interpolate)` on iOS 17+ / macOS 14+ / tvOS 17+.
    /// On older OSes, text content changes cut directly (no interpolation).
    @ViewBuilder
    func contentTransitionInterpolateCompat() -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, *) {
            self.contentTransition(.interpolate)
        } else {
            self
        }
    }
}

// MARK: - tvOS focus styling

#if os(tvOS)
/// Calm, consistent tvOS focus treatment. The default `.plain` focus effect draws
/// a large white "focus plate" behind the button, which is jarring on the dark
/// theme with bright buttons. Pair this style with `focusEffectDisabledCompat()`
/// to suppress that plate; this adds a subtle lift (gentle scale + soft shadow)
/// so focus is still clearly visible without being loud.
struct TVCalmFocusStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        // Under Reduce Motion the lift snaps instead of animating. The size
        // change itself stays: on tvOS it is the focus indicator, and removing
        // it would leave only a dark shadow on a dark background.
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.02 : (isFocused ? 1.08 : 1.0))
            .shadow(color: Color.black.opacity(isFocused ? 0.35 : 0),
                    radius: isFocused ? 12 : 0, x: 0, y: isFocused ? 6 : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isFocused)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.10), value: configuration.isPressed)
    }
}

extension View {
    /// On tvOS, apply the calm focus style + suppress the default focus plate.
    /// On other platforms, fall back to `.plain`.
    @ViewBuilder
    func tvCalmButtonStyle() -> some View {
        self.buttonStyle(TVCalmFocusStyle()).focusEffectDisabledCompat()
    }
}
#endif

// MARK: - Shared helpers

func sharedTimeString(from interval: TimeInterval) -> String {
    let totalSeconds = max(0, Int(ceil(interval)))
    let m = totalSeconds / 60
    let s = totalSeconds % 60
    return String(format: "%02d:%02d", m, s)
}

func sharedRoundLabel(snapshot: WODTimerEngineSnapshot, totalRounds: Int) -> String {
    String(localized: "Round \(snapshot.currentRound) / \(totalRounds) Rounds")
}

/// Whole-workout countdown, shown as secondary context while the big readout counts
/// down the current work or rest phase. Intervals used to put this in the big readout,
/// which left an athlete mid-interval with no way to see how long the interval had left
/// — while the audio cues were already counting the phase.
func sharedTotalRemainingLabel(snapshot: WODTimerEngineSnapshot) -> String {
    String(localized: "\(sharedTimeString(from: snapshot.remainingTime)) left")
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
    /// When set (For Time), the body line shows the finished time instead of rounds.
    var finishedTime: TimeInterval? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: theme.verticalSpacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: theme.checkmarkSize, weight: .medium))
                .foregroundStyle(DesignTokens.Common.primary(scheme))
            Text("Done")
                .font(.system(size: theme.titleSize, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
            Text(bodyLine)
                .font(.system(size: theme.bodySize, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
        }
        .padding(.vertical, theme.verticalSpacing)
        .accessibilityElement(children: .combine)
    }

    private var bodyLine: String {
        if let finishedTime {
            // Floor: the athlete's time is the last full second reached.
            return String(localized: "Finished in \(sharedTimeString(from: floor(finishedTime)))")
        }
        return "You completed \(totalRounds) round\(totalRounds == 1 ? "" : "s")"
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
            Text(LocalizedStringKey(label))
                .font(.system(size: theme.labelFontSize, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))

            HStack(spacing: theme.stackSpacing) {
                stepperButton(sign: -1)
                Text(displayString ?? "\(value)")
                    .font(.system(size: theme.valueFontSize, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                    .lineLimit(1)
                    // Shrink rather than overflow. fixedSize used to pin this to the
                    // text's ideal width, which is fine for "01:00" but sent longer
                    // localized values ("Ingen grænse") straight through the +/- buttons.
                    .minimumScaleFactor(0.4)
                    .frame(minWidth: displayString != nil ? max(theme.buttonSize * 2, theme.valueFontSize * 1.9) : theme.buttonSize * 2)
                    .padding(.horizontal, displayString != nil ? DesignTokens.Spacing.lg : 0)
                    // LocalizedStringKey, not the raw String: `label` is an English
                    // key ("Round length"), and the plain-String overload would read
                    // it out verbatim while the screen shows "Rundelængde".
                    .accessibilityLabel(LocalizedStringKey(label))
                    .accessibilityValue(displayString ?? "\(value)")
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
            Text(LocalizedStringKey(label))
                .font(.system(size: theme.valueFontSize * 0.75, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .frame(width: theme.buttonSize, height: theme.buttonSize)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
        }
        #if os(tvOS)
        .tvCalmButtonStyle()
        #else
        .buttonStyle(.plain)
        #endif
        // Two levels of translation: the surrounding phrase, and the stepper name
        // interpolated into it. Localizing the phrase alone would announce
        // "Formindsk Round length".
        .accessibilityLabel({
            let name = String(localized: String.LocalizationValue(self.label))
            return sign < 0 ? String(localized: "Decrease \(name)") : String(localized: "Increase \(name)")
        }())
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
            Text(LocalizedStringKey(title))
                .font(.system(size: theme.titleSize, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .contentTransitionInterpolateCompat()
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.verticalPadding)
                .padding(.horizontal, theme.horizontalPadding)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
        }
        #if os(tvOS)
        .tvCalmButtonStyle()
        #else
        .buttonStyle(.plain)
        #endif
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
        #if os(tvOS)
        .tvCalmButtonStyle()
        #else
        .buttonStyle(.plain)
        #endif
        .accessibilityHint("Stops workout and returns to setup")
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
            Text(LocalizedStringKey(mode.rawValue))
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
                .tvCalmButtonStyle()
                .accessibilityAddTraits(timerMode == mode ? .isSelected : [])
            #else
            button
                .buttonStyle(.plain)
                .accessibilityAddTraits(timerMode == mode ? .isSelected : [])
            #endif
        } else {
            button
                .buttonStyle(.plain)
                .accessibilityAddTraits(timerMode == mode ? .isSelected : [])
        }
    }
}

#endif

// MARK: - Phase ring

/// Length of the phase the big readout is counting down, so the ring can show how far
/// through it we are. Mirrors the switch the audio cues already use.
func sharedPhaseDuration(mode: WODTimerMode, phase: WODTimerPhase) -> TimeInterval {
    switch mode {
    case .emom(_, let secondsPerRound): return TimeInterval(secondsPerRound)
    case .intervals(let work, let rest, _): return TimeInterval(phase == .work ? work : rest)
    case .forTime: return 0
    }
}

/// Phase progress drawn around the readout. It drains over the current work, rest or EMOM
/// round and refills at every phase change, so it can be read from across a gym without
/// focusing on the digits — which is the point when your hands are on a barbell.
///
/// Deliberately not animated: the view already redraws on the timer tick, so an animated
/// trim would add motion that Reduce Motion asks us to leave out, and would lag the digits.
struct SharedPhaseRing: View {
    let remaining: TimeInterval
    let duration: TimeInterval
    let tint: Color
    let track: Color
    let diameter: CGFloat
    let lineWidth: CGFloat

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, remaining / duration))
    }

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: diameter, height: diameter)
        // The digits and the Work/Rest label already carry this for VoiceOver.
        .accessibilityHidden(true)
    }
}
