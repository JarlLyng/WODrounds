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
    // For Time cap; 0 = "No cap" sentinel (see forTimeCapRange).
    @AppStorage("forTimeCapSeconds") private var forTimeCapSeconds: Int = 0
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
                .onChange(of: timeline.date) { _, newDate in
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
                .onChange(of: engine.snapshot(now: timeline.date).currentRound) { _, newRound in
                    if (engine.state == .running || engine.state == .paused), timerMode == .emom, newRound > lastHapticRound {
                        triggerFlash()
                        lastHapticRound = newRound
                        WorkoutSoundManager.checkRoundsRemaining(currentRound: newRound, totalRounds: rounds)
                    }
                }
                .onChange(of: engine.snapshot(now: timeline.date).currentPhase) { _, newPhase in
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
                .onChange(of: engine.state) { _, newState in
                    if newState == .finished {
                        WorkoutSoundManager.playYouDidIt()
                    }
                    if newState == .idle || newState == .finished {
                        lastHapticRound = 0
                        lastHapticPhase = nil
                        lastRoundsRemainingRound = 0
                        resetInRoundCueState()
                    }
                    applyIdleTimer()
                }
                // Hold the screensaver off during the count-in too: the engine is
                // still idle then, and the remote isn't touched once Start is pressed.
                .onChange(of: countdownEndTime) { _, _ in applyIdleTimer() }
                .onAppear { applyIdleTimer() }
                .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
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
        // During the count-in, the overlay covers the idle controls but they'd
        // otherwise stay in the focus engine — the Siri Remote could land on the
        // hidden mode switch / steppers / Start behind the overlay. Disabling the
        // underlying content (before the overlay) removes them from focus, leaving
        // only the count-in's Cancel button focusable.
        .disabled(countdownEndTime != nil)
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
                SharedDoneView(totalRounds: totalRounds, theme: Self.tvOSDoneTheme,
                               finishedTime: timerMode == .forTime ? snapshot.elapsedTime : nil)
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
            // For Time counts up (floored so the shown time never runs ahead);
            // EMOM shows the per-round countdown; Intervals the total countdown.
            Text(sharedTimeString(from: tvOSActiveDisplayTime(snapshot: snapshot)))
                .font(.system(size: TVOSTypography.display, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                .frame(maxWidth: .infinity)
            if timerMode == .forTime {
                // No rounds in For Time; show the cap as context when one is set.
                if let cap = engine.forTimeCapSeconds {
                    Text("Cap \(sharedFormatEmomLength(cap))")
                        .font(.system(size: TVOSTypography.lg, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                        .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                }
            } else {
                Text(sharedRoundLabel(snapshot: snapshot, totalRounds: totalRounds))
                    .font(.system(size: TVOSTypography.lg, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            }
            if timerMode == .intervals {
                Text(snapshot.currentPhase == .work ? "Work" : "Rest")
                    .font(.system(size: TVOSTypography.sm, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }
        }
        .transition(.opacity)
    }

    private func tvOSActiveDisplayTime(snapshot: WODTimerEngineSnapshot) -> TimeInterval {
        switch timerMode {
        case .emom: return snapshot.remainingTimeInPhase
        case .intervals: return snapshot.remainingTime
        case .forTime: return floor(snapshot.elapsedTime)
        }
    }

    private func tvOSIdleSettingsView(state: WODTimerEngineState) -> some View {
        // Render only the active mode's steppers. The previous ZStack overlay kept
        // the inactive mode's steppers in the view at opacity 0 — but opacity /
        // allowsHitTesting / accessibilityHidden do NOT remove them from the tvOS
        // focus engine, so the Siri Remote could move focus into invisible buttons
        // and get stuck. Conditional rendering removes them entirely.
        VStack(spacing: DesignTokens.Spacing.xl) {
            switch timerMode {
            case .emom:
                SharedStepperView(value: $rounds, range: roundsRange, label: "Rounds", onChange: { syncEngineIfIdle(state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
                SharedStepperView(value: $emomRoundLengthSeconds, range: emomLengthRange, step: 30, displayString: sharedFormatEmomLength(emomRoundLengthSeconds), label: "Round length", onChange: { syncEngineIfIdle(state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
            case .intervals:
                SharedStepperView(value: $intervalsWork, range: intervalsWorkRange, label: "Work (sec)", onChange: { syncEngineIfIdle(state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
                SharedStepperView(value: $intervalsRest, range: intervalsRestRange, label: "Rest (sec)", onChange: { syncEngineIfIdle(state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
                SharedStepperView(value: $intervalsRounds, range: intervalsRoundsRange, label: "Rounds", onChange: { syncEngineIfIdle(state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
            case .forTime:
                // Single stepper covers both "no cap" and the cap value: the 0
                // sentinel renders as "No cap" and steps to 0:30, 1:00, … 60:00.
                SharedStepperView(value: $forTimeCapSeconds, range: forTimeCapRange, step: forTimeCapStep, displayString: forTimeCapDisplay(forTimeCapSeconds), label: "Time cap", onChange: { syncEngineIfIdle(state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
            }
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
        .tvCalmButtonStyle()
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
        .tvCalmButtonStyle()
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

    /// Keep the Apple TV screensaver away while a workout is on screen.
    /// Nobody touches the remote during an EMOM, so without this the system
    /// screensaver covers the timer a few minutes in. Mirrors the iOS behaviour
    /// (see `iOSContentView.applyIdleTimer`) and always releases when idle.
    private func applyIdleTimer() {
        let workoutOnScreen = engine.state == .running
            || engine.state == .paused
            || countdownEndTime != nil
        UIApplication.shared.isIdleTimerDisabled = workoutOnScreen
    }

    /// In-round audio cues. See `iOSContentView.checkInRoundCues` for full doc.
    private func checkInRoundCues(now: Date) {
        guard engine.state == .running else { return }
        // For Time counts up with no rounds/phases — none of the in-round cues apply.
        if case .forTime = engine.mode { return }
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
            case .forTime:
                return 0 // unreachable (guarded above); keeps the switch exhaustive
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
        case .forTime:
            return "The clock counts up. Press Stop when you finish, or set an optional time cap."
        }
    }

    private func tvOSPrimaryButton(snapshot: WODTimerEngineSnapshot, now: Date) -> some View {
        let (title, action): (String, () -> Void) = switch snapshot.state {
        case .idle:
            ("Start", { countdownEndTime = now.addingTimeInterval(10) })
        case .running:
            // For Time: the clock runs until you stop it. Stop freezes the final
            // time via finish(now:); Cancel below still discards.
            timerMode == .forTime
                ? ("Stop", { var e = engine; e.finish(now: now); engine = e })
                : ("Pause", { var e = engine; e.pause(now: now); engine = e })
        case .paused: ("Resume", { var e = engine; e.resume(now: now); engine = e })
        case .finished: ("Reset", { var e = engine; e.reset(); engine = e })
        }
        return SharedPrimaryButton(title: title, action: action, theme: Self.tvOSPrimaryTheme)
            .contentTransitionInterpolateCompat()
            .animation(.easeInOut(duration: 0.2), value: snapshot.state)
    }

    private func syncEngineIfIdle(_ state: WODTimerEngineState) {
        guard state == .idle || state == .finished else { return }
        switch timerMode {
        case .emom:
            engine = WODTimerEngine(emomRounds: rounds, secondsPerRound: emomRoundLengthSeconds)
        case .intervals:
            engine = WODTimerEngine(workSeconds: intervalsWork, restSeconds: intervalsRest, rounds: intervalsRounds)
        case .forTime:
            engine = WODTimerEngine(forTimeCapSeconds: forTimeEngineCap(forTimeCapSeconds))
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

            VStack(spacing: DesignTokens.Spacing.sm) {
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
            .frame(maxWidth: .infinity)
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
            .tvCalmButtonStyle()
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.bottom, DesignTokens.Spacing.xxxl)
        }
        .background(DesignTokens.Common.Background.app(scheme))
    }
}
#endif
