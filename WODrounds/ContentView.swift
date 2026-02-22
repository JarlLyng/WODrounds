//
//  ContentView.swift
//  WODrounds
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

// MARK: - Shared (iOS + macOS + tvOS)

#if os(iOS) || os(macOS) || os(tvOS)
private let roundsRange = 1 ... 120
private let intervalsWorkRange = 5 ... 300
private let intervalsRestRange = 0 ... 180
private let intervalsRoundsRange = 1 ... 60

enum TimerUIMode: String, CaseIterable {
    case emom = "EMOM"
    case intervals = "Intervals"
}
#endif

// MARK: - iOS / iPadOS (IAMJARL design tokens, light + dark)

#if os(iOS)
// MARK: - Haptics (iOS only; no third-party)
private enum Haptics {
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
    @State private var intervalsWork: Int = 30
    @State private var intervalsRest: Int = 15
    @State private var intervalsRounds: Int = 8
    @State private var engine = WODTimerEngine(totalDurationMinutes: 10)

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
            iOSContent(
                engine: $engine,
                timerMode: $timerMode,
                rounds: $rounds,
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
        let canEdit = snapshot.state == .idle || snapshot.state == .finished
        let isIdle = snapshot.state == .idle
        let isFinished = snapshot.state == .finished
        let showCancel = snapshot.state == .running || snapshot.state == .paused
        let totalRounds = engine.rounds

        ZStack(alignment: .topTrailing) {
        VStack(spacing: DesignTokens.Spacing.xxxl) {
            if isIdle {
                SharedModeSwitch(timerMode: $timerMode, onModeChange: { syncEngineIfIdle(engine.state) }, theme: Self.iosModeSwitchTheme)
                Text(modeHelpText)
                    .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }

            Spacer()

            if isFinished {
                SharedDoneView(totalRounds: totalRounds, theme: Self.iosDoneTheme)
                    .transition(.opacity)
            } else if !canEdit {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    Text(sharedTimeString(from: snapshot.remainingTime))
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

            Spacer()

            if isIdle {
                ZStack(alignment: .top) {
                    SharedStepperView(value: $rounds, range: roundsRange, label: "Rounds", onChange: { syncEngineIfIdle(snapshot.state) }, theme: Self.iosStepperTheme, useLongPressRepeat: true)
                        .opacity(timerMode == .emom ? 1 : 0)
                        .allowsHitTesting(timerMode == .emom)
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        SharedStepperView(value: $intervalsWork, range: intervalsWorkRange, label: "Work (sec)", onChange: { syncEngineIfIdle(snapshot.state) }, theme: Self.iosStepperTheme, useLongPressRepeat: true)
                        SharedStepperView(value: $intervalsRest, range: intervalsRestRange, label: "Rest (sec)", onChange: { syncEngineIfIdle(snapshot.state) }, theme: Self.iosStepperTheme, useLongPressRepeat: true)
                        SharedStepperView(value: $intervalsRounds, range: intervalsRoundsRange, label: "Rounds", onChange: { syncEngineIfIdle(snapshot.state) }, theme: Self.iosStepperTheme, useLongPressRepeat: true)
                    }
                    .opacity(timerMode == .intervals ? 1 : 0)
                    .allowsHitTesting(timerMode == .intervals)
                }
                .animation(.easeInOut(duration: 0.25), value: timerMode)
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }

            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                iosPrimaryButton(snapshot: snapshot, now: now)
                if showCancel {
                    SharedCancelButton(action: { showCancelConfirmation = true }, theme: Self.iosCancelTheme)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .animation(.easeInOut(duration: 0.25), value: snapshot.state)
        .animation(.easeInOut(duration: 0.25), value: timerMode)
        Button {
            showAbout = true
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: DesignTokens.Typography.Size.lg, weight: DesignTokens.Typography.Weight.regular))
                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
        }
        .buttonStyle(.plain)
        .padding(DesignTokens.Spacing.md)
        }
        .overlay {
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
                }
            }
        }
        .onChange(of: now) { _, newDate in
            if let end = countdownEndTime, newDate >= end {
                Haptics.light()
                lastHapticRound = 1
                lastHapticPhase = .work
                var e = engine
                e.start(now: end)
                engine = e
                countdownEndTime = nil
                WODTimerSync.write(engine.syncPayload(now: end))
                #if os(iOS)
                HealthKitWorkoutController.shared.startWorkout(startDate: end)
                #endif
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .confirmationDialog("Cancel workout?", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            Button("Cancel workout", role: .destructive) {
                let endDate = engine.effectiveWorkoutEndDate(now: Date()) ?? Date()
                var e = engine
                e.reset()
                engine = e
                WODTimerSync.write(engine.syncPayload(now: Date()))
                #if os(iOS)
                HealthKitWorkoutController.shared.endWorkout(endDate: endDate)
                #endif
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("You'll return to setup. Current progress will be lost.")
        }
        .onAppear {
            applyIdleTimer(engine.state)
        }
        .onChange(of: engine.state) { _, newState in
            applyIdleTimer(newState)
            switch newState {
            case .running, .paused:
                break
            case .idle, .finished:
                lastHapticRound = 0
                lastHapticPhase = nil
            }
            if newState == .finished {
                Haptics.strong()
                #if os(iOS)
                HealthKitWorkoutController.shared.endWorkout(endDate: engine.effectiveWorkoutEndDate(now: Date()) ?? Date())
                #endif
            }
        }
        .onChange(of: snapshot.currentRound) { _, newRound in
            if (engine.state == .running || engine.state == .paused), timerMode == .emom, newRound > lastHapticRound {
                Haptics.light()
                lastHapticRound = newRound
            }
        }
        .onChange(of: snapshot.currentPhase) { _, newPhase in
            if (engine.state == .running || engine.state == .paused), timerMode == .intervals, newPhase != lastHapticPhase {
                Haptics.medium()
                lastHapticPhase = newPhase
            }
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
            return "Select the number of rounds. Each round is one minute."
        case .intervals:
            return "Set work time, rest time, and number of rounds."
        }
    }

    private func syncEngineIfIdle(_ state: WODTimerEngineState) {
        guard state == .idle || state == .finished else { return }
        switch timerMode {
        case .emom:
            engine = WODTimerEngine(totalDurationMinutes: rounds)
        case .intervals:
            engine = WODTimerEngine(workSeconds: intervalsWork, restSeconds: intervalsRest, rounds: intervalsRounds)
        }
    }

    private func iosPrimaryButton(snapshot: WODTimerEngineSnapshot, now: Date) -> some View {
        let (title, action): (String, () -> Void) = switch snapshot.state {
        case .idle:
            ("Start", {
                #if os(iOS)
                HealthKitWorkoutController.shared.requestAuthorizationIfNeeded { _ in
                    countdownEndTime = Date().addingTimeInterval(10)
                }
                #else
                countdownEndTime = now.addingTimeInterval(10)
                #endif
            })
        case .running: ("Pause", { var e = engine; e.pause(now: now); engine = e; WODTimerSync.write(engine.syncPayload(now: now)) })
        case .paused: ("Resume", { var e = engine; e.resume(now: now); engine = e; WODTimerSync.write(engine.syncPayload(now: now)) })
        case .finished: ("Reset", {
            let endDate = engine.effectiveWorkoutEndDate(now: now) ?? now
            var e = engine
            e.reset()
            engine = e
            WODTimerSync.write(engine.syncPayload(now: now))
            #if os(iOS)
            HealthKitWorkoutController.shared.endWorkout(endDate: endDate)
            #endif
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

            Text("No data collected. No analytics.")
                .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if let url = URL(string: "https://github.com/JarlLyng/WODrounds/blob/main/Support.md") {
                    Link(destination: url) {
                        Text("Support: https://github.com/JarlLyng/WODrounds/blob/main/Support.md")
                            .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                            .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                    }
                }
                if let url = URL(string: "https://github.com/JarlLyng/WODrounds/blob/main/PrivacyPolicy.md") {
                    Link(destination: url) {
                        Text("Privacy Policy: https://github.com/JarlLyng/WODrounds/blob/main/PrivacyPolicy.md")
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
#endif

// MARK: - tvOS (full UI, DesignTokens, focusable controls)

#if os(tvOS)
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
    @State private var engine = WODTimerEngine(totalDurationMinutes: 10)
    @State private var showCancelConfirmation = false
    @State private var showAbout = false
    @State private var countdownEndTime: Date? = nil

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
            tvOSContent(now: timeline.date)
                .onChange(of: timeline.date) { _, newDate in
                    if engine.state == .running {
                        var e = engine
                        e.tick(now: newDate)
                        engine = e
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
                let endDate = engine.effectiveWorkoutEndDate(now: Date()) ?? Date()
                var e = engine
                e.reset()
                engine = e
                WODTimerSync.write(engine.syncPayload(now: Date()))
                #if os(iOS)
                HealthKitWorkoutController.shared.endWorkout(endDate: endDate)
                #endif
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("You'll return to setup. Current progress will be lost.")
        }
    }

    private func tvOSContent(now: Date) -> some View {
        let snapshot = engine.snapshot(now: now)
        let canEdit = snapshot.state == .idle || snapshot.state == .finished
        let isIdle = snapshot.state == .idle
        let isFinished = snapshot.state == .finished
        let showCancel = snapshot.state == .running || snapshot.state == .paused
        let totalRounds = engine.rounds

        return ZStack(alignment: .topTrailing) {
            VStack(spacing: DesignTokens.Spacing.xxxl) {
                if isIdle {
                    SharedModeSwitch(timerMode: $timerMode, onModeChange: { syncEngineIfIdle(engine.state) }, theme: Self.tvOSModeSwitchTheme)
                    Text(modeHelpText)
                        .font(.system(size: TVOSTypography.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                        .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                }

                Spacer()

                if isFinished {
                    SharedDoneView(totalRounds: totalRounds, theme: Self.tvOSDoneTheme)
                        .transition(.opacity)
                } else if !canEdit {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Text(sharedTimeString(from: snapshot.remainingTime))
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

                Spacer()

                if isIdle {
                    ZStack(alignment: .top) {
                        SharedStepperView(value: $rounds, range: roundsRange, label: "Rounds", onChange: { syncEngineIfIdle(engine.state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
                            .opacity(timerMode == .emom ? 1 : 0)
                            .allowsHitTesting(timerMode == .emom)
                        VStack(spacing: DesignTokens.Spacing.xl) {
                            SharedStepperView(value: $intervalsWork, range: intervalsWorkRange, label: "Work (sec)", onChange: { syncEngineIfIdle(engine.state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
                            SharedStepperView(value: $intervalsRest, range: intervalsRestRange, label: "Rest (sec)", onChange: { syncEngineIfIdle(engine.state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
                            SharedStepperView(value: $intervalsRounds, range: intervalsRoundsRange, label: "Rounds", onChange: { syncEngineIfIdle(engine.state) }, theme: Self.tvOSStepperTheme, useLongPressRepeat: false)
                        }
                        .opacity(timerMode == .intervals ? 1 : 0)
                        .allowsHitTesting(timerMode == .intervals)
                    }
                    .animation(.easeInOut(duration: 0.25), value: timerMode)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                }

                Spacer()

                VStack(spacing: DesignTokens.Spacing.xl) {
                    tvOSPrimaryButton(snapshot: snapshot, now: now)
                    if showCancel {
                        SharedCancelButton(action: { showCancelConfirmation = true }, theme: Self.tvOSCancelTheme)
                            .buttonStyle(.card)
                            .focusEffectDisabled()
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
            .animation(.easeInOut(duration: 0.25), value: snapshot.state)
            .animation(.easeInOut(duration: 0.25), value: timerMode)

            Button {
                showAbout = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: TVOSTypography.lg, weight: DesignTokens.Typography.Weight.regular))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }
            .buttonStyle(.plain)
            .padding(DesignTokens.Spacing.lg)
        }
        .overlay {
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
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DesignTokens.Common.Background.app(scheme))
                }
            }
        }
        .onChange(of: now) { _, newDate in
            if let end = countdownEndTime, newDate >= end {
                var e = engine
                e.start(now: end)
                engine = e
                countdownEndTime = nil
            }
        }
    }

    private var modeHelpText: String {
        switch timerMode {
        case .emom:
            return "Select the number of rounds. Each round is one minute."
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
            .contentTransition(.interpolate)
            .buttonStyle(.card)
            .focusEffectDisabled()
            .animation(.easeInOut(duration: 0.2), value: snapshot.state)
    }

    private func syncEngineIfIdle(_ state: WODTimerEngineState) {
        guard state == .idle || state == .finished else { return }
        switch timerMode {
        case .emom:
            engine = WODTimerEngine(totalDurationMinutes: rounds)
        case .intervals:
            engine = WODTimerEngine(workSeconds: intervalsWork, restSeconds: intervalsRest, rounds: intervalsRounds)
        }
    }

}

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

            Text("No data collected. No analytics.")
                .font(.system(size: TVOSTypography.base, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if let url = URL(string: "https://github.com/JarlLyng/WODrounds/blob/main/Support.md") {
                    Link(destination: url) {
                        Text("Support: https://github.com/JarlLyng/WODrounds/blob/main/Support.md")
                            .font(.system(size: TVOSTypography.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                            .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                    }
                }
                if let url = URL(string: "https://github.com/JarlLyng/WODrounds/blob/main/PrivacyPolicy.md") {
                    Link(destination: url) {
                        Text("Privacy Policy: https://github.com/JarlLyng/WODrounds/blob/main/PrivacyPolicy.md")
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
            .focusEffectDisabled()
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.bottom, DesignTokens.Spacing.xxxl)
        }
        .background(DesignTokens.Common.Background.app(scheme))
    }
}
#endif

// MARK: - macOS (full UI, same as iOS with DesignTokens)

#if os(macOS)
struct ContentView: View {
    @State private var timerMode: TimerUIMode = .emom
    @State private var rounds: Int = 10
    @State private var intervalsWork: Int = 30
    @State private var intervalsRest: Int = 15
    @State private var intervalsRounds: Int = 8
    @State private var engine = WODTimerEngine(totalDurationMinutes: 10)

    @Environment(\.colorScheme) private var scheme

    private let maxContentWidth: CGFloat = 320
    private let maxContentHeight: CGFloat = 520

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
            MacContent(
                engine: $engine,
                timerMode: $timerMode,
                rounds: $rounds,
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
    @Binding var intervalsWork: Int
    @Binding var intervalsRest: Int
    @Binding var intervalsRounds: Int
    let now: Date
    @Environment(\.colorScheme) private var scheme

    @State private var showCancelConfirmation = false
    @State private var showAbout = false
    @State private var countdownEndTime: Date? = nil

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
        let isIdle = snapshot.state == .idle
        let isFinished = snapshot.state == .finished
        let showCancel = snapshot.state == .running || snapshot.state == .paused
        let totalRounds = engine.rounds

        ZStack(alignment: .topTrailing) {
            VStack(spacing: DesignTokens.Spacing.xxxl) {
                if isIdle {
                    SharedModeSwitch(timerMode: $timerMode, onModeChange: { syncEngineIfIdle(engine.state) }, theme: Self.macModeSwitchTheme)
                    Text(modeHelpText)
                        .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                        .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, DesignTokens.Spacing.xl)
                }

                Spacer()

                if isFinished {
                    SharedDoneView(totalRounds: totalRounds, theme: Self.macDoneTheme)
                        .transition(.opacity)
                } else if snapshot.state == .running || snapshot.state == .paused {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Text(sharedTimeString(from: snapshot.remainingTime))
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

                Spacer()

                if isIdle {
                    ZStack(alignment: .top) {
                        SharedStepperView(value: $rounds, range: roundsRange, label: "Rounds", onChange: { syncEngineIfIdle(engine.state) }, theme: Self.macStepperTheme, useLongPressRepeat: true)
                            .opacity(timerMode == .emom ? 1 : 0)
                            .allowsHitTesting(timerMode == .emom)
                        VStack(spacing: DesignTokens.Spacing.lg) {
                            SharedStepperView(value: $intervalsWork, range: intervalsWorkRange, label: "Work (sec)", onChange: { syncEngineIfIdle(engine.state) }, theme: Self.macStepperTheme, useLongPressRepeat: true)
                            SharedStepperView(value: $intervalsRest, range: intervalsRestRange, label: "Rest (sec)", onChange: { syncEngineIfIdle(engine.state) }, theme: Self.macStepperTheme, useLongPressRepeat: true)
                            SharedStepperView(value: $intervalsRounds, range: intervalsRoundsRange, label: "Rounds", onChange: { syncEngineIfIdle(engine.state) }, theme: Self.macStepperTheme, useLongPressRepeat: true)
                        }
                        .opacity(timerMode == .intervals ? 1 : 0)
                        .allowsHitTesting(timerMode == .intervals)
                    }
                    .animation(.easeInOut(duration: 0.25), value: timerMode)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
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

            Button {
                showAbout = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: DesignTokens.Typography.Size.lg, weight: DesignTokens.Typography.Weight.regular))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }
            .buttonStyle(.plain)
            .padding(DesignTokens.Spacing.md)
        }
        .overlay {
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
                }
            }
        }
        .onChange(of: now) { _, newDate in
            if let end = countdownEndTime, newDate >= end {
                var e = engine
                e.start(now: end)
                engine = e
                countdownEndTime = nil
            }
        }
        .sheet(isPresented: $showAbout) { MacAboutView() }
        .confirmationDialog("Cancel workout?", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            Button("Cancel workout", role: .destructive) {
                let endDate = engine.effectiveWorkoutEndDate(now: Date()) ?? Date()
                var e = engine
                e.reset()
                engine = e
                WODTimerSync.write(engine.syncPayload(now: Date()))
                #if os(iOS)
                HealthKitWorkoutController.shared.endWorkout(endDate: endDate)
                #endif
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("You'll return to setup. Current progress will be lost.")
        }
    }

    private var modeHelpText: String {
        switch timerMode {
        case .emom: return "Select the number of rounds. Each round is one minute."
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
            .contentTransition(.interpolate)
            .animation(.easeInOut(duration: 0.2), value: snapshot.state)
    }

    private func syncEngineIfIdle(_ state: WODTimerEngineState) {
        guard state == .idle || state == .finished else { return }
        switch timerMode {
        case .emom: engine = WODTimerEngine(totalDurationMinutes: rounds)
        case .intervals: engine = WODTimerEngine(workSeconds: intervalsWork, restSeconds: intervalsRest, rounds: intervalsRounds)
        }
    }
}

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
            Text("No data collected. No analytics.")
                .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if let url = URL(string: "https://github.com/JarlLyng/WODrounds/blob/main/Support.md") {
                    Link(destination: url) {
                        Text("Support: https://github.com/JarlLyng/WODrounds/blob/main/Support.md")
                            .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                            .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                    }
                }
                if let url = URL(string: "https://github.com/JarlLyng/WODrounds/blob/main/PrivacyPolicy.md") {
                    Link(destination: url) {
                        Text("Privacy Policy: https://github.com/JarlLyng/WODrounds/blob/main/PrivacyPolicy.md")
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

// MARK: - Previews (iOS only)

#if os(iOS)
#Preview {
    ContentView()
}
#endif
