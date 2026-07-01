//
//  iOSContentView.swift
//  WODrounds
//
//  iOS / iPadOS content: timer UI, haptics, HealthKit triggers, sound cues.
//

#if os(iOS)
import SwiftUI
import StoreKit
import UIKit

// MARK: - Haptics (iOS only; no third-party)
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func strong() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct ContentView: View {
    @State private var timerMode: TimerUIMode = .emom
    @State private var rounds: Int = 10
    @AppStorage("emomRoundLengthSeconds") private var emomRoundLengthSeconds: Int = 60
    @State private var intervalsWork: Int = 30
    @State private var intervalsRest: Int = 15
    @State private var intervalsRounds: Int = 8
    @State private var engine = WODTimerEngine(emomRounds: 10, secondsPerRound: 60)

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
            iOSContent(
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
                    WODTimerSync.write(engine.syncPayload(now: newDate))
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Common.Background.app(scheme))
    }

    @Environment(\.colorScheme) private var scheme
}

private struct iOSContent: View {
    @Binding var engine: WODTimerEngine
    @Binding var timerMode: TimerUIMode
    @Binding var rounds: Int
    @Binding var emomRoundLength: Int
    @Binding var intervalsWork: Int
    @Binding var intervalsRest: Int
    @Binding var intervalsRounds: Int
    let now: Date
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var showCancelConfirmation = false
    @State private var lastHapticRound: Int = 0
    @State private var lastHapticPhase: WODTimerPhase?
    // Tracks the last round we announced a "rounds remaining" cue for, so the
    // cue fires once per round even though Intervals changes phase twice per round.
    @State private var lastRoundsRemainingRound: Int = 0
    @State private var showAbout = false
    @State private var countdownEndTime: Date? = nil
    @State private var flashScreen = false
    // In-round cue state — tracks which cues have fired this (round, phase) so each fires once.
    @State private var lastHalfwayRound: Int? = nil
    @State private var lastHalfwayPhase: WODTimerPhase? = nil
    @State private var lastTenSecondsRound: Int? = nil
    @State private var lastTenSecondsPhase: WODTimerPhase? = nil
    @State private var lastBeepSecond: Int = -1
    @State private var lastBeepRound: Int? = nil
    @State private var lastBeepPhase: WODTimerPhase? = nil
    @AppStorage("completedWorkoutCount") private var completedWorkoutCount: Int = 0
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @Environment(\.requestReview) private var requestReview

    // MARK: - iPad adaptation
    // iPad has both size classes regular. iPhone in landscape has horizontal=regular but
    // vertical=compact, so requiring both prevents iPhone Plus models from getting iPad styling.
    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    private var fontScale: CGFloat { isIPad ? 1.5 : 1.0 }
    private var spacingScale: CGFloat { isIPad ? 1.3 : 1.0 }
    /// Max content width on iPad keeps stepper +/- buttons within reach. nil = unconstrained on iPhone.
    private var maxContentWidth: CGFloat? { isIPad ? 600 : nil }

    private var doneTheme: DoneViewTheme {
        DoneViewTheme(
            checkmarkSize: 64 * fontScale,
            titleSize: DesignTokens.Typography.Size.xxl * fontScale,
            bodySize: DesignTokens.Typography.Size.base * fontScale,
            verticalSpacing: DesignTokens.Spacing.xxl * spacingScale
        )
    }
    private var stepperTheme: StepperTheme {
        StepperTheme(
            labelFontSize: DesignTokens.Typography.Size.sm * fontScale,
            valueFontSize: DesignTokens.Typography.Size.title * fontScale,
            buttonSize: DesignTokens.Spacing.xxxl * 2 * spacingScale,
            cornerRadius: DesignTokens.Radius.md,
            stackSpacing: DesignTokens.Spacing.lg * spacingScale,
            verticalPadding: DesignTokens.Spacing.sm
        )
    }
    private var primaryTheme: PrimaryButtonTheme {
        PrimaryButtonTheme(
            titleSize: DesignTokens.Typography.Size.xxl * fontScale,
            verticalPadding: DesignTokens.Spacing.md * spacingScale,
            horizontalPadding: DesignTokens.Spacing.xl,
            cornerRadius: DesignTokens.Radius.md
        )
    }
    private var cancelTheme: CancelButtonTheme {
        CancelButtonTheme(
            titleSize: DesignTokens.Typography.Size.lg * fontScale,
            verticalPadding: DesignTokens.Spacing.sm * spacingScale,
            horizontalPadding: DesignTokens.Spacing.xl,
            cornerRadius: DesignTokens.Radius.sm
        )
    }
    private var modeSwitchTheme: ModeSwitchTheme {
        ModeSwitchTheme(
            fontSize: DesignTokens.Typography.Size.base * fontScale,
            horizontalPadding: DesignTokens.Spacing.md * spacingScale,
            verticalPadding: DesignTokens.Spacing.sm,
            spacing: DesignTokens.Spacing.sm,
            cornerRadius: DesignTokens.Radius.sm,
            useCardStyle: false
        )
    }

    var body: some View {
        let snapshot = engine.snapshot(now: now)
        let totalRounds = engine.rounds

        ZStack(alignment: .topTrailing) {
            // Wrap in HStack with spacers so iPad gets centered max-600pt content
            // while iPhone uses full width (maxContentWidth = nil → no constraint).
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                mainVStack(snapshot: snapshot, totalRounds: totalRounds)
                    .frame(maxWidth: maxContentWidth)
                Spacer(minLength: 0)
            }
            topRightControls
        }
        .padding(DesignTokens.Spacing.md)
        .overlay { flashOverlay }
        .overlay { countdownOverlay }
        .onChange(of: now) { newDate in
            handleDateChange(newDate)
            checkInRoundCues(now: newDate)
        }
        .onChange(of: engine.state) { newState in
            applyIdleTimer(newState)
            if newState == .idle || newState == .finished {
                lastHapticRound = 0
                lastHapticPhase = nil
                lastRoundsRemainingRound = 0
                resetInRoundCueState()
            }
            if newState == .finished {
                Haptics.strong()
                HealthKitWorkoutController.shared.endWorkout(endDate: engine.effectiveWorkoutEndDate(now: Date()) ?? Date())
                WorkoutSoundManager.playYouDidIt()
                completedWorkoutCount += 1
                if completedWorkoutCount == 5 || completedWorkoutCount == 15 || completedWorkoutCount == 50 {
                    // Delay so the Done screen is visible before the system dialog appears.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        requestReview()
                    }
                }
            }
        }
        .onChange(of: snapshot.currentRound) { newRound in
            if (engine.state == .running || engine.state == .paused), timerMode == .emom, newRound > lastHapticRound {
                Haptics.light()
                triggerFlash()
                lastHapticRound = newRound
                WorkoutSoundManager.checkRoundsRemaining(currentRound: newRound, totalRounds: rounds)
            }
        }
        .onChange(of: snapshot.currentPhase) { newPhase in
            if (engine.state == .running || engine.state == .paused), timerMode == .intervals, newPhase != lastHapticPhase {
                Haptics.medium()
                triggerFlash()
                lastHapticPhase = newPhase
                // Phase changes twice per round (work→rest, rest→work); only announce
                // rounds-remaining once per round so the cue isn't spoken twice.
                if snapshot.currentRound != lastRoundsRemainingRound {
                    lastRoundsRemainingRound = snapshot.currentRound
                    WorkoutSoundManager.checkRoundsRemaining(currentRound: snapshot.currentRound, totalRounds: intervalsRounds)
                }
            }
        }
        .onAppear { applyIdleTimer(engine.state) }
        .sheet(isPresented: $showAbout) { AboutView() }
        .confirmationDialog("Cancel workout?", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            cancelConfirmationContent
        } message: {
            Text("You'll return to setup. Current progress will be lost.")
        }
    }

    @ViewBuilder
    private func mainVStack(snapshot: WODTimerEngineSnapshot, totalRounds: Int) -> some View {
        VStack(spacing: DesignTokens.Spacing.xxxl * spacingScale) {
            if snapshot.state == .idle {
                idleHeaderView
            }

            Spacer()

            if snapshot.state == .finished {
                SharedDoneView(totalRounds: totalRounds, theme: doneTheme)
                    .transition(.opacity)
            } else if snapshot.state == .running || snapshot.state == .paused {
                activeTimerView(snapshot: snapshot, totalRounds: totalRounds)
            }

            Spacer()

            if snapshot.state == .idle {
                idleSettingsView(state: snapshot.state)
            }

            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg * spacingScale) {
                iosPrimaryButton(snapshot: snapshot, now: now)
                if snapshot.state == .running || snapshot.state == .paused {
                    SharedCancelButton(action: { showCancelConfirmation = true }, theme: cancelTheme)
                    Text("Open WODrounds on your Apple Watch to see this workout.")
                        .font(.system(size: DesignTokens.Typography.Size.xs * fontScale, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                        .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxl * spacingScale)
        }
        .animation(.easeInOut(duration: 0.25), value: snapshot.state)
        .animation(.easeInOut(duration: 0.25), value: timerMode)
    }

    private var idleHeaderView: some View {
        VStack(spacing: DesignTokens.Spacing.md * spacingScale) {
            SharedModeSwitch(timerMode: $timerMode, onModeChange: { syncEngineIfIdle(engine.state) }, theme: modeSwitchTheme)
            Text(modeHelpText)
                .font(.system(size: DesignTokens.Typography.Size.sm * fontScale, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, DesignTokens.Spacing.xl)
        }
    }

    private func activeTimerView(snapshot: WODTimerEngineSnapshot, totalRounds: Int) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg * spacingScale) {
            Text(sharedTimeString(from: timerMode == .emom ? snapshot.remainingTimeInPhase : snapshot.remainingTime))
                .font(.system(size: DesignTokens.Typography.Size.display * fontScale, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                .frame(maxWidth: .infinity)

            Text(sharedRoundLabel(snapshot: snapshot, totalRounds: totalRounds))
                .font(.system(size: DesignTokens.Typography.Size.lg * fontScale, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))

            if timerMode == .intervals {
                Text(snapshot.currentPhase == .work ? "Work" : "Rest")
                    .font(.system(size: DesignTokens.Typography.Size.sm * fontScale, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }
        }
        .transition(.opacity)
    }

    private func idleSettingsView(state: WODTimerEngineState) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: DesignTokens.Spacing.lg * spacingScale) {
                SharedStepperView(value: $rounds, range: roundsRange, label: "Rounds", onChange: { syncEngineIfIdle(state) }, theme: stepperTheme, useLongPressRepeat: true)
                SharedStepperView(value: $emomRoundLength, range: emomLengthRange, step: 30, displayString: sharedFormatEmomLength(emomRoundLength), label: "Round length", onChange: { syncEngineIfIdle(state) }, theme: stepperTheme, useLongPressRepeat: true)
            }
                .opacity(timerMode == .emom ? 1 : 0)
                .allowsHitTesting(timerMode == .emom)
                .accessibilityHidden(timerMode != .emom)
            VStack(spacing: DesignTokens.Spacing.lg * spacingScale) {
                SharedStepperView(value: $intervalsWork, range: intervalsWorkRange, label: "Work (sec)", onChange: { syncEngineIfIdle(state) }, theme: stepperTheme, useLongPressRepeat: true)
                SharedStepperView(value: $intervalsRest, range: intervalsRestRange, label: "Rest (sec)", onChange: { syncEngineIfIdle(state) }, theme: stepperTheme, useLongPressRepeat: true)
                SharedStepperView(value: $intervalsRounds, range: intervalsRoundsRange, label: "Rounds", onChange: { syncEngineIfIdle(state) }, theme: stepperTheme, useLongPressRepeat: true)
            }
            .opacity(timerMode == .intervals ? 1 : 0)
            .allowsHitTesting(timerMode == .intervals)
            .accessibilityHidden(timerMode != .intervals)
        }
    }

    private var topRightControls: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            soundToggleButton
            infoButton
        }
    }

    private var soundToggleButton: some View {
        Button {
            soundEnabled.toggle()
            // Brief haptic confirms the toggle was registered.
            Haptics.light()
        } label: {
            Image(systemName: soundEnabled ? "speaker.wave.2" : "speaker.slash")
                .font(.system(size: DesignTokens.Typography.Size.lg, weight: DesignTokens.Typography.Weight.regular))
                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                .contentTransitionInterpolateCompat()
                .frame(minWidth: 44, minHeight: 44)
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
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("About")
    }

    private var flashOverlay: some View {
        DesignTokens.Common.Text.primary(scheme)
            .ignoresSafeArea()
            .opacity(flashScreen ? 0.85 : 0)
            .animation(.easeInOut(duration: 0.35), value: flashScreen)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var countdownOverlay: some View {
        if let end = countdownEndTime {
            let remaining = max(0, Int(ceil(end.timeIntervalSince(now))))
            if remaining > 0 {
                VStack(spacing: DesignTokens.Spacing.lg * spacingScale) {
                    Text("Get ready")
                        .font(.system(size: DesignTokens.Typography.Size.lg * fontScale, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                        .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                    Text("\(remaining)")
                        .font(.system(size: DesignTokens.Typography.Size.display * fontScale, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                    SharedCancelButton(action: {
                        countdownEndTime = nil
                        Haptics.light()
                    }, theme: cancelTheme)
                    .frame(maxWidth: maxContentWidth)
                    .padding(.top, DesignTokens.Spacing.xl * spacingScale)
                    .padding(.horizontal, DesignTokens.Spacing.xxxl)
                    .accessibilityLabel("Cancel countdown")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DesignTokens.Common.Background.app(scheme))
                .transition(.opacity)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Countdown, \(remaining) seconds")
            }
        }
    }

    @ViewBuilder
    private var cancelConfirmationContent: some View {
        Button("Cancel workout", role: .destructive) {
            let endDate = engine.effectiveWorkoutEndDate(now: Date()) ?? Date()
            var e = engine
            e.reset()
            engine = e
            WODTimerSync.write(engine.syncPayload(now: Date()))
            HealthKitWorkoutController.shared.endWorkout(endDate: endDate)
        }
        Button("Keep going", role: .cancel) {}
    }

    private func handleDateChange(_ newDate: Date) {
        if let end = countdownEndTime, newDate >= end {
            Haptics.light()
            lastHapticRound = 1
            lastHapticPhase = .work
            var e = engine
            e.start(now: end)
            engine = e
            countdownEndTime = nil
            WODTimerSync.write(engine.syncPayload(now: end))
            HealthKitWorkoutController.shared.startWorkout(startDate: end)
            WorkoutSoundManager.playGetReadyStart()
        }
    }

    /// In-round audio cues that fire during a running phase:
    /// - **Halfway**: voice "halfway" when half of the phase is left (only if phase > 40s)
    /// - **Ten seconds**: voice "ten seconds" at 10s left (only if phase > 15s)
    /// - **3-2-1 countdown**: short beep at 3, 2, 1 seconds left (always)
    ///
    /// Idempotent — each cue fires at most once per (round, phase) tuple.
    private func checkInRoundCues(now: Date) {
        guard engine.state == .running else { return }
        // For Time counts up with no rounds/phases — none of the in-round cues apply.
        if case .forTime = engine.mode { return }
        let snapshot = engine.snapshot(now: now)
        let remaining = snapshot.remainingTimeInPhase
        let round = snapshot.currentRound
        let phase = snapshot.currentPhase

        // Phase duration depends on mode
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

        // Halfway voice cue — only on phases long enough to keep cues separated.
        if phaseDuration > 40 {
            let halfTime = phaseDuration / 2
            if remaining >= halfTime - 0.5, remaining <= halfTime + 0.5,
               !(lastHalfwayRound == round && lastHalfwayPhase == phase) {
                lastHalfwayRound = round
                lastHalfwayPhase = phase
                WorkoutSoundManager.speakHalfway()
            }
        }

        // Ten-seconds voice cue
        if phaseDuration > 15,
           remaining >= 9.5, remaining <= 10.5,
           !(lastTenSecondsRound == round && lastTenSecondsPhase == phase) {
            lastTenSecondsRound = round
            lastTenSecondsPhase = phase
            WorkoutSoundManager.speakTenSecondsLeft()
        }

        // 3-2-1 countdown beep — fires at 3, 2, 1 seconds left in any phase.
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

    private func triggerFlash() {
        flashScreen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            flashScreen = false
        }
    }

    private func applyIdleTimer(_ state: WODTimerEngineState) {
        switch state {
        case .running, .paused:
            UIApplication.shared.isIdleTimerDisabled = true
        case .idle, .finished:
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var modeHelpText: String {
        switch timerMode {
        case .emom:
            return "Select the number of rounds, and length of each round."
        case .intervals:
            return "Set work time, rest time, and number of rounds."
        }
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

    private func iosPrimaryButton(snapshot: WODTimerEngineSnapshot, now: Date) -> some View {
        let (title, action): (String, () -> Void) = switch snapshot.state {
        case .idle:
            ("Start", {
                // Request Health permission first so the dialog appears before countdown.
                // Countdown starts only after the user has responded; then startWorkout can save to Health.
                HealthKitWorkoutController.shared.requestAuthorizationIfNeeded { _ in
                    countdownEndTime = Date().addingTimeInterval(10)
                }
            })
        case .running: ("Pause", { var e = engine; e.pause(now: now); engine = e; WODTimerSync.write(engine.syncPayload(now: now)) })
        case .paused: ("Resume", { var e = engine; e.resume(now: now); engine = e; WODTimerSync.write(engine.syncPayload(now: now)) })
        case .finished: ("Reset", {
            let endDate = engine.effectiveWorkoutEndDate(now: now) ?? now
            var e = engine
            e.reset()
            engine = e
            WODTimerSync.write(engine.syncPayload(now: now))
            HealthKitWorkoutController.shared.endWorkout(endDate: endDate)
        })
        }
        return SharedPrimaryButton(title: title, action: action, theme: primaryTheme)
            .animation(.easeInOut(duration: 0.2), value: snapshot.state)
    }
}

// MARK: - About (iOS/iPadOS)

private struct AboutView: View {
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
                    .font(.system(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                Text("Version \(version) (\(build))")
                    .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            }
            .padding(.top, DesignTokens.Spacing.xxl)

            Text(String(localized: "No analytics or tracking. Only crash reports are sent to help fix bugs."))
                .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

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
            .padding(.horizontal)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
            .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .background(DesignTokens.Common.primary(scheme))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            .buttonStyle(.plain)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .background(DesignTokens.Common.Background.app(scheme))
    }
}

// MARK: - Previews

#Preview {
    ContentView()
}
#endif
