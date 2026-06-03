//
//  tvOSContentView.swift
//  WODrounds
//
//  tvOS content: timer UI with focus-based controls and card-style buttons.
//

#if os(tvOS)
import SwiftUI

private enum TVOSTypography {
    static let display: CGFloat = 120
    static let title: CGFloat = 72
    static let xxl: CGFloat = 48
    static let xl: CGFloat = 32
    static let lg: CGFloat = 24
    static let base: CGFloat = 20
    static let sm: CGFloat = 18
}

struct ContentView: View {
    @State private var timerMode: TimerUIMode = .emom
    @State private var rounds: Int = 10
    @State private var intervalsWork: Int = 30
    @State private var intervalsRest: Int = 15
    @State private var intervalsRounds: Int = 8
    @State private var engine = WODTimerEngine(emomRounds: 10, secondsPerRound: 60)
    @AppStorage("emomRoundLengthSeconds") private var emomRoundLengthSeconds: Int = 60
    @State private var showCancelConfirmation = false
    @State private var showAbout = false
    @State private var countdownEndTime: Date? = nil
    @State private var flashScreen = false
    @State private var lastHapticRound = 0
    @State private var lastHapticPhase: WODTimerPhase?
    // Tracks the last round we announced a "rounds remaining" cue for, so the
    // cue fires once per round even though Intervals changes phase twice per round.
    @State private var lastRoundsRemainingRound: Int = 0
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    // In-round cue state — tracks which cues have fired this (round, phase) so each fires once.
    @State private var lastHalfwayRound: Int? = nil
    @State private var lastHalfwayPhase: WODTimerPhase? = nil
    @State private var lastTenSecondsRound: Int? = nil
    @State private var lastTenSecondsPhase: WODTimerPhase? = nil
    @State private var lastBeepSecond: Int = -1
    @State private var lastBeepRound: Int? = nil
    @State private var lastBeepPhase: WODTimerPhase? = nil

    @Environment(\.colorScheme) private var scheme

    private static let tvOSDoneTheme = DoneViewTheme(
        checkmarkSize: 80,
        titleSize: TVOSTypography.xxl,
        bodySize: TVOSTypography.base,
        verticalSpacing: DesignTokens.Spacing.xxl
    )
    private static let tvOSStepperTheme = StepperTheme(
        labelFontSize: TVOSTypography.sm,
        valueFontSize: TVOSTypography.title,
        buttonSize: 80,
        cornerRadius: DesignTokens.Radius.md,
        stackSpacing: DesignTokens.Spacing.xxl,
        verticalPadding: DesignTokens.Spacing.sm
    )
    private static let tvOSPrimaryTheme = PrimaryButtonTheme(
        titleSize: TVOSTypography.xxl,
        verticalPadding: DesignTokens.Spacing.lg,
        horizontalPadding: DesignTokens.Spacing.xxl,
        cornerRadius: DesignTokens.Radius.md
    )
    private static let tvOSCancelTheme = CancelButtonTheme(
        titleSize: TVOSTypography.lg,
        verticalPadding: DesignTokens.Spacing.md,
        horizontalPadding: DesignTokens.Spacing.xxl,
        cornerRadius: DesignTokens.Radius.sm
    )
    private static let tvOSModeSwitchTheme = ModeSwitchTheme(
        fontSize: TVOSTypography.base,
        horizontalPadding: DesignTokens.Spacing.lg,
        verticalPadding: DesignTokens.Spacing.md,
        spacing: DesignTokens.Spacing.md,
        cornerRadius: DesignTokens.Radius.sm,
        useCardStyle: true
    )

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
            tvOSContent(now: timeline.date, rounds: $rounds, emomRoundLength: $emomRoundLengthSeconds, intervalsWork: $intervalsWork, intervalsRest: $intervalsRest, intervalsRounds: $intervalsRounds)
                .onChange(of: timeline.date) { newDate in
                    if engine.state == .running {
                        var e = engine
                        e.tick(now: newDate)
                        engine = e
                        WODTimerSync.write(engine.syncPayload(now: newDate))
                    }
                    if let end = countdownEndTime, newDate >= end {
                        var e = engine
                        e.start(now: end)
                        engine = e
                        countdownEndTime = nil
                        WorkoutSoundManager.playGetReadyStart()
                    }
                    checkInRoundCues(now: newDate)
                }
                .onChange(of: engine.snapshot(now: timeline.date).currentRound) { newRound in
                    if (engine.state == .running || engine.state == .paused), timerMode == .emom, newRound > lastHapticRound {
                        triggerFlash()
                        lastHapticRound = newRound
                        WorkoutSoundManager.checkRoundsRemaining(currentRound: newRound, totalRounds: rounds)
                    }
                }
                .onChange(of: engine.snapshot(now: timeline.date).currentPhase) { newPhase in
                    if (engine.state == .running || engine.state == .paused), timerMode == .intervals, newPhase != lastHapticPhase {
                        triggerFlash()
                        lastHapticPhase = newPhase
                        // Phase changes twice per round (work→rest, rest→work); only announce
                        // rounds-remaining once per round so the cue isn't spoken twice.
                        let currentRound = engine.snapshot(now: timeline.date).currentRound
                        if currentRound != lastRoundsRemainingRound {
                            lastRoundsRemainingRound = currentRound
                            WorkoutSoundManager.checkRoundsRemaining(currentRound: currentRound, totalRounds: intervalsRounds)
                        }
                    }
                }
                .onChange(of: engine.state) { newState in
                    if newState == .finished {
                        WorkoutSoundManager.playYouDidIt()
                    }
                    if newState == .idle || newState == .finished {
                        lastHapticRound = 0
                        lastHapticPhase = nil
                        lastRoundsRemainingRound = 0
                        resetInRoundCueState()
                    }
                }
        }
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Common.Background.app(scheme))
        .fullScreenCover(isPresented: $showAbout) {
            tvOSAboutView()
        }
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

    private func tvOSContent(now: Date, rounds: Binding<Int>, emomRoundLength: Binding<Int>, intervalsWork: Binding<Int>, intervalsRest: Binding<Int>, intervalsRounds: Binding<Int>) -> some View {
        let snapshot = engine.snapshot(now: now)
        let totalRounds = engine.rounds

        return ZStack(alignment: .topTrailing) {
            tvOSMainVStack(snapshot: snapshot, totalRounds: totalRounds, now: now)

            tvOSTopRightControls
        }
        .overlay { tvOSFlashOverlay }
        .overlay { tvOSCountdownOverlay(now: now) }
    }

    private func tvOSMainVStack(snapshot: WODTimerEngineSnapshot, totalRounds: Int, now: Date) -> some View {
        let isIdle = snapshot.state == .idle
        let showCancel = snapshot.state == .running || snapshot.state == .paused

        return VStack(spacing: DesignTokens.Spacing.xxxl) {
            if isIdle {
                tvOSIdleHeaderView(state: snapshot.state)
            }

            Spacer()

            if snapshot.state == .finished {
                SharedDoneView(totalRounds: totalRounds, theme: Self.tvOSDoneTheme)
                    .transition(.opacity)
            } else if snapshot.state == .running || snapshot.state == .paused {
                tvOSActiveTimerView(snapshot: snapshot, totalRounds: totalRounds)
            }

            Spacer()

            if isIdle {
                tvOSIdleSettingsView(state: snapshot.state)
            }

            Spacer()

            VStack(spacing: DesignTokens.Spacing.xl) {
                tvOSPrimaryButton(snapshot: snapshot, now: now)
                if showCancel {
                    SharedCancelButton(action: { showCancelConfirmation = true }, theme: Self.tvOSCancelTheme)
                        .buttonStyle(.card)
                        .focusEffectDisabledCompat()
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.bottom, DesignTokens.Spacing.xxxl)
        }
        .animation(.easeInOut(duration: 0.25), value: snapshot.state)
        .animation(.easeInOut(duration: 0.25), value: timerMode)
    }

    private func tvOSIdleHeaderView(state: WODTimerEngineState) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            SharedModeSwitch(timerMode: $timerMode, onModeChange: { syncEngineIfIdle(state) }, theme: Self.tvOSModeSwitchTheme)
            Text(modeHelpText)
                .font(.system(size: TVOSTypography.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, DesignTokens.Spacing.xxl)
        }
    }

    private func tvOSActiveTimerView(snapshot: WODTimerEngineSnapshot, totalRounds: Int) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text(sharedTimeString(from: timerMode == .emom ? snapshot.remainingTimeInPhase : snapshot.remainingTime))
                .font(.system(size: TVOSTypography.display, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                .frame(maxWidth: .infinity)
            Text(sharedRoundLabel(snapshot: snapshot, totalRounds: totalRounds))
                .font(.system(size: TVOSTypography.lg, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            if timerMode == .intervals {
                Text(snapshot.currentPhase == .work ? "Work" : "Rest")
                    .font(.system(size: TVOSTypography.sm, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }
        }
        .transition(.opacity)
    }

    private func tvOSIdleSettingsView(state: WODTimerEngineState) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: DesignTokens.Spacing.xl) {
                SharedStepperView(value: $rounds, range: roundsRange, label: "Rounds", onChange: { syncEngineIfIdle(state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
                SharedStepperView(value: $emomRoundLengthSeconds, range: emomLengthRange, step: 30, displayString: sharedFormatEmomLength(emomRoundLengthSeconds), label: "Round length", onChange: { syncEngineIfIdle(state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
            }
                .opacity(timerMode == .emom ? 1 : 0)
                .allowsHitTesting(timerMode == .emom)
                .accessibilityHidden(timerMode != .emom)
            VStack(spacing: DesignTokens.Spacing.xl) {
                SharedStepperView(value: $intervalsWork, range: intervalsWorkRange, label: "Work (sec)", onChange: { syncEngineIfIdle(state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
                SharedStepperView(value: $intervalsRest, range: intervalsRestRange, label: "Rest (sec)", onChange: { syncEngineIfIdle(state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
                SharedStepperView(value: $intervalsRounds, range: intervalsRoundsRange, label: "Rounds", onChange: { syncEngineIfIdle(state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
            }
            .opacity(timerMode == .intervals ? 1 : 0)
            .allowsHitTesting(timerMode == .intervals)
            .accessibilityHidden(timerMode != .intervals)
        }
        .animation(.easeInOut(duration: 0.25), value: timerMode)
        .padding(.horizontal, DesignTokens.Spacing.xxl)
    }

    private var tvOSTopRightControls: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            tvOSSoundToggleButton
            tvOSInfoButton
        }
        .padding(DesignTokens.Spacing.lg)
    }

    private var tvOSSoundToggleButton: some View {
        Button {
            soundEnabled.toggle()
        } label: {
            Image(systemName: soundEnabled ? "speaker.wave.2" : "speaker.slash")
                .font(.system(size: TVOSTypography.lg, weight: DesignTokens.Typography.Weight.regular))
                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                .contentTransitionInterpolateCompat()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(soundEnabled ? "Mute sound" : "Unmute sound")
    }

    private var tvOSInfoButton: some View {
        Button {
            showAbout = true
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: TVOSTypography.lg, weight: DesignTokens.Typography.Weight.regular))
                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("About")
    }

    private var tvOSFlashOverlay: some View {
        DesignTokens.Common.Text.primary(scheme)
            .ignoresSafeArea()
            .opacity(flashScreen ? 0.85 : 0)
            .animation(.easeInOut(duration: 0.35), value: flashScreen)
            .accessibilityHidden(true)
    }

    private func tvOSCountdownOverlay(now: Date) -> some View {
        Group {
            if let end = countdownEndTime {
                let remaining = max(0, Int(ceil(end.timeIntervalSince(now))))
                if remaining > 0 {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Text("Get ready")
                            .font(.system(size: TVOSTypography.lg, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                            .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                        Text("\(remaining)")
                            .font(.system(size: TVOSTypography.display, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                        SharedCancelButton(action: { countdownEndTime = nil }, theme: Self.tvOSCancelTheme)
                            .frame(maxWidth: 600)
                            .padding(.top, DesignTokens.Spacing.xl)
                            .accessibilityLabel("Cancel countdown")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DesignTokens.Common.Background.app(scheme))
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Countdown, \(remaining) seconds")
                }
            }
        }
    }

    private func triggerFlash() {
        flashScreen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            flashScreen = false
        }
    }

    /// In-round audio cues. See `iOSContentView.checkInRoundCues` for full doc.
    private func checkInRoundCues(now: Date) {
        guard engine.state == .running else { return }
        let snapshot = engine.snapshot(now: now)
        let remaining = snapshot.remainingTimeInPhase
        let round = snapshot.currentRound
        let phase = snapshot.currentPhase

        let phaseDuration: TimeInterval = {
            switch engine.mode {
            case .emom(_, let spr):
                return TimeInterval(spr)
            case .intervals(let w, let r, _):
                return TimeInterval(phase == .work ? w : r)
            }
        }()

        if phaseDuration > 40 {
            let halfTime = phaseDuration / 2
            if remaining >= halfTime - 0.5, remaining <= halfTime + 0.5,
               !(lastHalfwayRound == round && lastHalfwayPhase == phase) {
                lastHalfwayRound = round
                lastHalfwayPhase = phase
                WorkoutSoundManager.speakHalfway()
            }
        }

        if phaseDuration > 15,
           remaining >= 9.5, remaining <= 10.5,
           !(lastTenSecondsRound == round && lastTenSecondsPhase == phase) {
            lastTenSecondsRound = round
            lastTenSecondsPhase = phase
            WorkoutSoundManager.speakTenSecondsLeft()
        }

        let secInt = Int(remaining.rounded())
        if (1...3).contains(secInt) {
            let isSameTrigger = lastBeepSecond == secInt && lastBeepRound == round && lastBeepPhase == phase
            if !isSameTrigger {
                lastBeepSecond = secInt
                lastBeepRound = round
                lastBeepPhase = phase
                WorkoutSoundManager.playCountdownBeep()
            }
        }
    }

    private func resetInRoundCueState() {
        lastHalfwayRound = nil
        lastHalfwayPhase = nil
        lastTenSecondsRound = nil
        lastTenSecondsPhase = nil
        lastBeepSecond = -1
        lastBeepRound = nil
        lastBeepPhase = nil
    }

    private var modeHelpText: String {
        switch timerMode {
        case .emom:
            return "Select the number of rounds, and length of each round."
        case .intervals:
            return "Set work time, rest time, and number of rounds."
        }
    }

    private func tvOSPrimaryButton(snapshot: WODTimerEngineSnapshot, now: Date) -> some View {
        let (title, action): (String, () -> Void) = switch snapshot.state {
        case .idle:
            ("Start", { countdownEndTime = now.addingTimeInterval(10) })
        case .running: ("Pause", { var e = engine; e.pause(now: now); engine = e })
        case .paused: ("Resume", { var e = engine; e.resume(now: now); engine = e })
        case .finished: ("Reset", { var e = engine; e.reset(); engine = e })
        }
        return SharedPrimaryButton(title: title, action: action, theme: Self.tvOSPrimaryTheme)
            .contentTransitionInterpolateCompat()
            .buttonStyle(.card)
            .focusEffectDisabledCompat()
            .animation(.easeInOut(duration: 0.2), value: snapshot.state)
    }

    private func syncEngineIfIdle(_ state: WODTimerEngineState) {
        guard state == .idle || state == .finished else { return }
        switch timerMode {
        case .emom:
            engine = WODTimerEngine(emomRounds: rounds, secondsPerRound: emomRoundLengthSeconds)
        case .intervals:
            engine = WODTimerEngine(workSeconds: intervalsWork, restSeconds: intervalsRest, rounds: intervalsRounds)
        }
    }
}

// MARK: - About (tvOS)

private struct tvOSAboutView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "WODrounds"
    }
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text(appName)
                    .font(.system(size: TVOSTypography.xl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                Text("Version \(version) (\(build))")
                    .font(.system(size: TVOSTypography.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            }
            .padding(.top, DesignTokens.Spacing.xxxl)

            Text(String(localized: "No analytics or tracking."))
                .font(.system(size: TVOSTypography.base, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if let url = URL(string: "https://wodrounds.iamjarl.com/support") {
                    Link(destination: url) {
                        Text("Support")
                            .font(.system(size: TVOSTypography.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                            .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                    }
                }
                if let url = URL(string: "https://wodrounds.iamjarl.com/privacy") {
                    Link(destination: url) {
                        Text("Privacy Policy")
                            .font(.system(size: TVOSTypography.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                            .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .font(.system(size: TVOSTypography.base, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
            .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .background(DesignTokens.Common.primary(scheme))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            .buttonStyle(.card)
            .focusEffectDisabledCompat()
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.bottom, DesignTokens.Spacing.xxxl)
        }
        .background(DesignTokens.Common.Background.app(scheme))
    }
}
#endif
