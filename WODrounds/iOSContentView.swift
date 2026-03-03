//
//  iOSContentView.swift
//  WODrounds
//
//  iOS / iPadOS content: timer UI, haptics, HealthKit triggers, sound cues.
//

#if os(iOS)
import SwiftUI
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
            .onChange(of: timeline.date) { _, newDate in
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

    @State private var showCancelConfirmation = false
    @State private var lastHapticRound: Int = 0
    @State private var lastHapticPhase: WODTimerPhase?
    @State private var showAbout = false
    @State private var countdownEndTime: Date? = nil
    @State private var flashScreen = false
    @State private var last30SecondWarningRound: Int? = nil
    @State private var last30SecondWarningPhase: WODTimerPhase? = nil

    private static let iosDoneTheme = DoneViewTheme(
        checkmarkSize: 64,
        titleSize: DesignTokens.Typography.Size.xxl,
        bodySize: DesignTokens.Typography.Size.base,
        verticalSpacing: DesignTokens.Spacing.xxl
    )
    private static let iosStepperTheme = StepperTheme(
        labelFontSize: DesignTokens.Typography.Size.sm,
        valueFontSize: DesignTokens.Typography.Size.title,
        buttonSize: DesignTokens.Spacing.xxxl * 2,
        cornerRadius: DesignTokens.Radius.md,
        stackSpacing: DesignTokens.Spacing.lg,
        verticalPadding: DesignTokens.Spacing.sm
    )
    private static let iosPrimaryTheme = PrimaryButtonTheme(
        titleSize: DesignTokens.Typography.Size.xxl,
        verticalPadding: DesignTokens.Spacing.md,
        horizontalPadding: DesignTokens.Spacing.xl,
        cornerRadius: DesignTokens.Radius.md
    )
    private static let iosCancelTheme = CancelButtonTheme(
        titleSize: DesignTokens.Typography.Size.lg,
        verticalPadding: DesignTokens.Spacing.sm,
        horizontalPadding: DesignTokens.Spacing.xl,
        cornerRadius: DesignTokens.Radius.sm
    )
    private static let iosModeSwitchTheme = ModeSwitchTheme(
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
            mainVStack(snapshot: snapshot, totalRounds: totalRounds)
            infoButton
        }
        .padding(DesignTokens.Spacing.md)
        .overlay { flashOverlay }
        .overlay { countdownOverlay }
        .onChange(of: now) { _, newDate in
            handleDateChange(newDate)
            check30SecondsRemainingSound(now: newDate)
        }
        .onChange(of: engine.state) { _, newState in
            applyIdleTimer(newState)
            if newState == .idle || newState == .finished {
                lastHapticRound = 0
                lastHapticPhase = nil
                last30SecondWarningRound = nil
                last30SecondWarningPhase = nil
            }
            if newState == .finished {
                Haptics.strong()
                HealthKitWorkoutController.shared.endWorkout(endDate: engine.effectiveWorkoutEndDate(now: Date()) ?? Date())
                WorkoutSoundManager.playYouDidIt()
            }
        }
        .onChange(of: snapshot.currentRound) { _, newRound in
            if (engine.state == .running || engine.state == .paused), timerMode == .emom, newRound > lastHapticRound {
                Haptics.light()
                triggerFlash()
                lastHapticRound = newRound
            }
        }
        .onChange(of: snapshot.currentPhase) { _, newPhase in
            if (engine.state == .running || engine.state == .paused), timerMode == .intervals, newPhase != lastHapticPhase {
                Haptics.medium()
                triggerFlash()
                lastHapticPhase = newPhase
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
        VStack(spacing: DesignTokens.Spacing.xxxl) {
            if snapshot.state == .idle {
                idleHeaderView
            }

            Spacer()

            if snapshot.state == .finished {
                SharedDoneView(totalRounds: totalRounds, theme: Self.iosDoneTheme)
                    .transition(.opacity)
            } else if snapshot.state == .running || snapshot.state == .paused {
                activeTimerView(snapshot: snapshot, totalRounds: totalRounds)
            }

            Spacer()

            if snapshot.state == .idle {
                idleSettingsView(state: snapshot.state)
            }

            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                iosPrimaryButton(snapshot: snapshot, now: now)
                if snapshot.state == .running || snapshot.state == .paused {
                    SharedCancelButton(action: { showCancelConfirmation = true }, theme: Self.iosCancelTheme)
                    Text("Open WODrounds on your Apple Watch to see this workout.")
                        .font(.system(size: DesignTokens.Typography.Size.xs, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                        .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .animation(.easeInOut(duration: 0.25), value: snapshot.state)
        .animation(.easeInOut(duration: 0.25), value: timerMode)
    }

    private var idleHeaderView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            SharedModeSwitch(timerMode: $timerMode, onModeChange: { syncEngineIfIdle(engine.state) }, theme: Self.iosModeSwitchTheme)
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
                SharedStepperView(value: $rounds, range: roundsRange, label: "Rounds", onChange: { syncEngineIfIdle(state) }, theme: Self.iosStepperTheme, useLongPressRepeat: true)
                SharedStepperView(value: $emomRoundLength, range: emomLengthRange, step: 30, displayString: sharedFormatEmomLength(emomRoundLength), label: "Round length", onChange: { syncEngineIfIdle(state) }, theme: Self.iosStepperTheme, useLongPressRepeat: true)
            }
                .opacity(timerMode == .emom ? 1 : 0)
                .allowsHitTesting(timerMode == .emom)
                .accessibilityHidden(timerMode != .emom)
            VStack(spacing: DesignTokens.Spacing.lg) {
                SharedStepperView(value: $intervalsWork, range: intervalsWorkRange, label: "Work (sec)", onChange: { syncEngineIfIdle(state) }, theme: Self.iosStepperTheme, useLongPressRepeat: true)
                SharedStepperView(value: $intervalsRest, range: intervalsRestRange, label: "Rest (sec)", onChange: { syncEngineIfIdle(state) }, theme: Self.iosStepperTheme, useLongPressRepeat: true)
                SharedStepperView(value: $intervalsRounds, range: intervalsRoundsRange, label: "Rounds", onChange: { syncEngineIfIdle(state) }, theme: Self.iosStepperTheme, useLongPressRepeat: true)
            }
            .opacity(timerMode == .intervals ? 1 : 0)
            .allowsHitTesting(timerMode == .intervals)
            .accessibilityHidden(timerMode != .intervals)
        }
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
            .animation(.easeInOut(duration: 0.35), value: flashScreen)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var countdownOverlay: some View {
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
                .transition(.opacity)
                .accessibilityElement(children: .ignore)
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

    private func check30SecondsRemainingSound(now: Date) {
        guard engine.state == .running else { return }
        let snapshot = engine.snapshot(now: now)
        let remaining = snapshot.remainingTimeInPhase
        guard remaining >= 29.5, remaining <= 30.5 else { return }
        if last30SecondWarningRound == snapshot.currentRound, last30SecondWarningPhase == snapshot.currentPhase { return }
        last30SecondWarningRound = snapshot.currentRound
        last30SecondWarningPhase = snapshot.currentPhase
        WorkoutSoundManager.play30SecondsRemaining()
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
        return SharedPrimaryButton(title: title, action: action, theme: Self.iosPrimaryTheme)
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
