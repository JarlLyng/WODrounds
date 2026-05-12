//
//  macOSContentView.swift
//  WODrounds
//
//  macOS content: timer UI with keyboard-friendly controls.
//

#if os(macOS)
import SwiftUI

struct ContentView: View {
    @State private var timerMode: TimerUIMode = .emom
    @State private var rounds: Int = 10
    @AppStorage("emomRoundLengthSeconds") private var emomRoundLengthSeconds: Int = 60
    @State private var intervalsWork: Int = 30
    @State private var intervalsRest: Int = 15
    @State private var intervalsRounds: Int = 8
    @State private var engine = WODTimerEngine(emomRounds: 10, secondsPerRound: 60)

    @Environment(\.colorScheme) private var scheme

    private let maxContentWidth: CGFloat = 320
    private let maxContentHeight: CGFloat = 520

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
            MacContent(
                engine: $engine,
                timerMode: $timerMode,
                rounds: $rounds,
                emomRoundLength: $emomRoundLengthSeconds,
                intervalsWork: $intervalsWork,
                intervalsRest: $intervalsRest,
                intervalsRounds: $intervalsRounds,
                now: timeline.date
            )
            .onChange(of: timeline.date) { newDate in
                if engine.state == .running {
                    var e = engine
                    e.tick(now: newDate)
                    engine = e
                }
            }
        }
        .frame(maxWidth: maxContentWidth, maxHeight: maxContentHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Common.Background.app(scheme))
    }
}

private struct MacContent: View {
    @Binding var engine: WODTimerEngine
    @Binding var timerMode: TimerUIMode
    @Binding var rounds: Int
    @Binding var emomRoundLength: Int
    @Binding var intervalsWork: Int
    @Binding var intervalsRest: Int
    @Binding var intervalsRounds: Int
    let now: Date
    @Environment(\.colorScheme) private var scheme

    @State private var showCancelConfirmation = false
    @State private var showAbout = false
    @State private var countdownEndTime: Date? = nil
    @State private var flashScreen = false
    @State private var lastHapticRound = 0
    @State private var lastHapticPhase: WODTimerPhase?
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true

    private static let macDoneTheme = DoneViewTheme(
        checkmarkSize: 64,
        titleSize: DesignTokens.Typography.Size.xxl,
        bodySize: DesignTokens.Typography.Size.base,
        verticalSpacing: DesignTokens.Spacing.xxl
    )
    private static let macStepperTheme = StepperTheme(
        labelFontSize: DesignTokens.Typography.Size.sm,
        valueFontSize: DesignTokens.Typography.Size.title,
        buttonSize: DesignTokens.Spacing.xxxl * 2,
        cornerRadius: DesignTokens.Radius.md,
        stackSpacing: DesignTokens.Spacing.xl,
        verticalPadding: DesignTokens.Spacing.sm
    )
    private static let macPrimaryTheme = PrimaryButtonTheme(
        titleSize: DesignTokens.Typography.Size.xxl,
        verticalPadding: DesignTokens.Spacing.md,
        horizontalPadding: DesignTokens.Spacing.xl,
        cornerRadius: DesignTokens.Radius.md
    )
    private static let macCancelTheme = CancelButtonTheme(
        titleSize: DesignTokens.Typography.Size.lg,
        verticalPadding: DesignTokens.Spacing.sm,
        horizontalPadding: DesignTokens.Spacing.xl,
        cornerRadius: DesignTokens.Radius.sm
    )
    private static let macModeSwitchTheme = ModeSwitchTheme(
        fontSize: DesignTokens.Typography.Size.base,
        horizontalPadding: DesignTokens.Spacing.md,
        verticalPadding: DesignTokens.Spacing.sm,
        spacing: DesignTokens.Spacing.sm,
        cornerRadius: DesignTokens.Radius.sm,
        useCardStyle: false
    )

    var body: some View {
        let snapshot = engine.snapshot(now: now)
        let totalRounds = engine.rounds

        ZStack(alignment: .topTrailing) {
            mainVStack(snapshot: snapshot, totalRounds: totalRounds, now: now)

            topRightControls
        }
        .overlay { flashOverlay }
        .overlay { countdownOverlay(now: now) }
        .onChange(of: now) { newDate in
            if let end = countdownEndTime, newDate >= end {
                var e = engine
                e.start(now: end)
                engine = e
                countdownEndTime = nil
            }
        }
        .onChange(of: snapshot.currentRound) { newRound in
            if (engine.state == .running || engine.state == .paused), timerMode == .emom, newRound > lastHapticRound {
                triggerFlash()
                lastHapticRound = newRound
            }
        }
        .onChange(of: snapshot.currentPhase) { newPhase in
            if (engine.state == .running || engine.state == .paused), timerMode == .intervals, newPhase != lastHapticPhase {
                triggerFlash()
                lastHapticPhase = newPhase
            }
        }
        .sheet(isPresented: $showAbout) { MacAboutView() }
        .confirmationDialog("Cancel workout?", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            Button("Cancel workout", role: .destructive) {
                var e = engine
                e.reset()
                engine = e
                WODTimerSync.write(engine.syncPayload(now: Date()))
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("You'll return to setup. Current progress will be lost.")
        }
    }

    private func mainVStack(snapshot: WODTimerEngineSnapshot, totalRounds: Int, now: Date) -> some View {
        let isIdle = snapshot.state == .idle
        let showCancel = snapshot.state == .running || snapshot.state == .paused

        return VStack(spacing: DesignTokens.Spacing.xxxl) {
            if isIdle {
                idleHeaderView(state: snapshot.state)
            }

            Spacer()

            if snapshot.state == .finished {
                SharedDoneView(totalRounds: totalRounds, theme: Self.macDoneTheme)
                    .transition(.opacity)
            } else if snapshot.state == .running || snapshot.state == .paused {
                activeTimerView(snapshot: snapshot, totalRounds: totalRounds)
            }

            Spacer()

            if isIdle {
                idleSettingsView(state: snapshot.state)
            }

            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                macPrimaryButton(snapshot: snapshot, now: now)
                if showCancel {
                    SharedCancelButton(action: { showCancelConfirmation = true }, theme: Self.macCancelTheme)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .animation(.easeInOut(duration: 0.25), value: snapshot.state)
        .animation(.easeInOut(duration: 0.25), value: timerMode)
    }

    private func idleHeaderView(state: WODTimerEngineState) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            SharedModeSwitch(timerMode: $timerMode, onModeChange: { syncEngineIfIdle(state) }, theme: Self.macModeSwitchTheme)
            Text(modeHelpText)
                .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, DesignTokens.Spacing.xl)
        }
    }

    private func activeTimerView(snapshot: WODTimerEngineSnapshot, totalRounds: Int) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text(sharedTimeString(from: timerMode == .emom ? snapshot.remainingTimeInPhase : snapshot.remainingTime))
                .font(.system(size: DesignTokens.Typography.Size.display, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                .frame(maxWidth: .infinity)
            Text(sharedRoundLabel(snapshot: snapshot, totalRounds: totalRounds))
                .font(.system(size: DesignTokens.Typography.Size.lg, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            if timerMode == .intervals {
                Text(snapshot.currentPhase == .work ? "Work" : "Rest")
                    .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }
        }
        .transition(.opacity)
    }

    private func idleSettingsView(state: WODTimerEngineState) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: DesignTokens.Spacing.lg) {
                SharedStepperView(value: $rounds, range: roundsRange, label: "Rounds", onChange: { syncEngineIfIdle(state) }, theme: Self.macStepperTheme, useLongPressRepeat: true)
                SharedStepperView(value: $emomRoundLength, range: emomLengthRange, step: 30, displayString: sharedFormatEmomLength(emomRoundLength), label: "Round length", onChange: { syncEngineIfIdle(state) }, theme: Self.macStepperTheme, useLongPressRepeat: true)
            }
                .opacity(timerMode == .emom ? 1 : 0)
                .allowsHitTesting(timerMode == .emom)
                .accessibilityHidden(timerMode != .emom)
            VStack(spacing: DesignTokens.Spacing.lg) {
                SharedStepperView(value: $intervalsWork, range: intervalsWorkRange, label: "Work (sec)", onChange: { syncEngineIfIdle(state) }, theme: Self.macStepperTheme, useLongPressRepeat: true)
                SharedStepperView(value: $intervalsRest, range: intervalsRestRange, label: "Rest (sec)", onChange: { syncEngineIfIdle(state) }, theme: Self.macStepperTheme, useLongPressRepeat: true)
                SharedStepperView(value: $intervalsRounds, range: intervalsRoundsRange, label: "Rounds", onChange: { syncEngineIfIdle(state) }, theme: Self.macStepperTheme, useLongPressRepeat: true)
            }
            .opacity(timerMode == .intervals ? 1 : 0)
            .allowsHitTesting(timerMode == .intervals)
            .accessibilityHidden(timerMode != .intervals)
        }
        .animation(.easeInOut(duration: 0.25), value: timerMode)
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }

    private var topRightControls: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            soundToggleButton
            infoButton
        }
        .padding(DesignTokens.Spacing.md)
    }

    private var soundToggleButton: some View {
        Button {
            soundEnabled.toggle()
        } label: {
            Image(systemName: soundEnabled ? "speaker.wave.2" : "speaker.slash")
                .font(.system(size: DesignTokens.Typography.Size.lg, weight: DesignTokens.Typography.Weight.regular))
                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                .contentTransitionInterpolateCompat()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(soundEnabled ? "Mute sound" : "Unmute sound")
    }

    private var infoButton: some View {
        Button {
            showAbout = true
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: DesignTokens.Typography.Size.lg, weight: DesignTokens.Typography.Weight.regular))
                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("About")
    }

    private var flashOverlay: some View {
        DesignTokens.Common.Text.primary(scheme)
            .ignoresSafeArea()
            .opacity(flashScreen ? 0.85 : 0)
            .animation(.easeInOut(duration: 0.15), value: flashScreen)
            .accessibilityHidden(true)
    }

    private func countdownOverlay(now: Date) -> some View {
        Group {
            if let end = countdownEndTime {
                let remaining = max(0, Int(ceil(end.timeIntervalSince(now))))
                if remaining > 0 {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Text("Get ready")
                            .font(.system(size: DesignTokens.Typography.Size.lg, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                            .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                        Text("\(remaining)")
                            .font(.system(size: DesignTokens.Typography.Size.display, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DesignTokens.Common.Background.app(scheme))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Countdown, \(remaining) seconds")
                }
            }
        }
    }

    private var modeHelpText: String {
        switch timerMode {
        case .emom: return "Select the number of rounds, and length of each round."
        case .intervals: return "Set work time, rest time, and number of rounds."
        }
    }

    private func macPrimaryButton(snapshot: WODTimerEngineSnapshot, now: Date) -> some View {
        let (title, action): (String, () -> Void) = switch snapshot.state {
        case .idle: ("Start", { countdownEndTime = now.addingTimeInterval(10) })
        case .running: ("Pause", { var e = engine; e.pause(now: now); engine = e })
        case .paused: ("Resume", { var e = engine; e.resume(now: now); engine = e })
        case .finished: ("Reset", { var e = engine; e.reset(); engine = e })
        }
        return SharedPrimaryButton(title: title, action: action, theme: Self.macPrimaryTheme)
            .contentTransitionInterpolateCompat()
            .animation(.easeInOut(duration: 0.2), value: snapshot.state)
    }

    private func syncEngineIfIdle(_ state: WODTimerEngineState) {
        guard state == .idle || state == .finished else { return }
        switch timerMode {
        case .emom:
            engine = WODTimerEngine(emomRounds: rounds, secondsPerRound: emomRoundLength)
        case .intervals:
            engine = WODTimerEngine(workSeconds: intervalsWork, restSeconds: intervalsRest, rounds: intervalsRounds)
        }
    }

    private func triggerFlash() {
        flashScreen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            flashScreen = false
        }
    }
}

// MARK: - About (macOS)

private struct MacAboutView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    private var appName: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "WODrounds" }
    private var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0" }
    private var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1" }
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text(appName)
                    .font(.system(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                Text("Version \(version) (\(build))")
                    .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            }
            .padding(.top, DesignTokens.Spacing.xxl)
            Text(String(localized: "No analytics or tracking."))
                .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if let url = URL(string: "https://wodrounds.iamjarl.com/support") {
                    Link(destination: url) {
                        Text("Support")
                            .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                            .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                    }
                }
                if let url = URL(string: "https://wodrounds.iamjarl.com/privacy") {
                    Link(destination: url) {
                        Text("Privacy Policy")
                            .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                            .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                    }
                }
            }
            Spacer()
            Button("Done") { dismiss() }
                .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .buttonStyle(.plain)
                .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .frame(minWidth: 320, minHeight: 380)
        .background(DesignTokens.Common.Background.app(scheme))
    }
}
#endif
