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

    @State private var repeatWorkItem: DispatchWorkItem?
    @State private var repeatStartTime: Date?
    @State private var repeatCancelled = false
    @State private var showCancelConfirmation = false
    @State private var lastHapticRound: Int = 0
    @State private var lastHapticPhase: WODTimerPhase?
    @State private var showAbout = false

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
                modeSwitch
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
                doneView(totalRounds: totalRounds)
                    .transition(.opacity)
            } else if !canEdit {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    Text(timeString(from: snapshot.remainingTime))
                        .font(.system(size: DesignTokens.Typography.Size.display, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                        .frame(maxWidth: .infinity)

                    Text(roundLabel(snapshot: snapshot, totalRounds: totalRounds))
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
                    roundsSelector(applyToEngine: { syncEngineIfIdle(snapshot.state) })
                        .opacity(timerMode == .emom ? 1 : 0)
                        .allowsHitTesting(timerMode == .emom)
                    intervalsControls(syncEngine: { syncEngineIfIdle(snapshot.state) })
                        .opacity(timerMode == .intervals ? 1 : 0)
                        .allowsHitTesting(timerMode == .intervals)
                }
                .animation(.easeInOut(duration: 0.25), value: timerMode)
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }

            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                primaryButton(snapshot: snapshot, now: now)
                if showCancel {
                    cancelButton
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
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .confirmationDialog("Cancel workout?", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            Button("Cancel workout", role: .destructive) {
                var e = engine
                e.reset()
                engine = e
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("You’ll return to setup. Current progress will be lost.")
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

    private func roundLabel(snapshot: WODTimerEngineSnapshot, totalRounds: Int) -> String {
        "Round \(snapshot.currentRound) / \(totalRounds) Rounds"
    }

    private func doneView(totalRounds: Int) -> some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(DesignTokens.Common.primary(scheme))
            Text("Done")
                .font(.system(size: DesignTokens.Typography.Size.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
            Text("You completed \(totalRounds) round\(totalRounds == 1 ? "" : "s")")
                .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
        }
        .padding(.vertical, DesignTokens.Spacing.xxl)
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

    private var modeSwitch: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(TimerUIMode.allCases, id: \.self) { mode in
                Button {
                    timerMode = mode
                    syncEngineIfIdle(engine.state)
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                        .foregroundStyle(timerMode == mode ? DesignTokens.Common.onPrimary(scheme) : DesignTokens.Common.Text.primary(scheme))
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(timerMode == mode ? DesignTokens.Common.primary(scheme) : DesignTokens.Common.Background.card(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func intervalsControls(syncEngine: @escaping () -> Void) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            intervalStepper(label: "Work (sec)", value: $intervalsWork, range: intervalsWorkRange) { syncEngine() }
            intervalStepper(label: "Rest (sec)", value: $intervalsRest, range: intervalsRestRange) { syncEngine() }
            intervalStepper(label: "Rounds", value: $intervalsRounds, range: intervalsRoundsRange) { syncEngine() }
        }
    }

    private func intervalStepper(label: String, value: Binding<Int>, range: ClosedRange<Int>, onChange: @escaping () -> Void) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text(label)
                .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            HStack(spacing: DesignTokens.Spacing.xl) {
                Button("−") {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
                    onChange()
                }
                .font(.system(size: DesignTokens.Typography.Size.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .frame(width: DesignTokens.Spacing.xxxl * 2, height: DesignTokens.Spacing.xxxl * 2)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .buttonStyle(.plain)
                Text("\(value.wrappedValue)")
                    .font(.system(size: DesignTokens.Typography.Size.title, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                    .frame(minWidth: DesignTokens.Spacing.xxxl * 2)
                Button("+") {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
                    onChange()
                }
                .font(.system(size: DesignTokens.Typography.Size.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .frame(width: DesignTokens.Spacing.xxxl * 2, height: DesignTokens.Spacing.xxxl * 2)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .buttonStyle(.plain)
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }

    private var cancelButton: some View {
        Button {
            showCancelConfirmation = true
        } label: {
            Text("Cancel")
                .font(.system(size: DesignTokens.Typography.Size.lg, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.ColorToken.State.onError)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .background(DesignTokens.ColorToken.State.error)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
        }
        .buttonStyle(.plain)
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

    private func roundsSelector(applyToEngine: @escaping () -> Void) -> some View {
        func step(by delta: Int) {
            let next = rounds + delta
            rounds = min(roundsRange.upperBound, max(roundsRange.lowerBound, next))
            applyToEngine()
        }

        return VStack(spacing: DesignTokens.Spacing.lg) {
            Text("Rounds")
                .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))

            HStack(spacing: DesignTokens.Spacing.xl) {
                roundStepperButton(sign: -1, step: step)
                Text("\(rounds)")
                    .font(.system(size: DesignTokens.Typography.Size.title, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                    .frame(minWidth: DesignTokens.Spacing.xxxl * 2)
                roundStepperButton(sign: 1, step: step)
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }

    private func roundStepperButton(sign: Int, step: @escaping (Int) -> Void) -> some View {
        let label = sign < 0 ? "−" : "+"
        return Button {
            step(sign)
        } label: {
            Text(label)
                .font(.system(size: DesignTokens.Typography.Size.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .frame(width: DesignTokens.Spacing.xxxl * 2, height: DesignTokens.Spacing.xxxl * 2)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.4, pressing: { pressing in
            if pressing {
                startRepeat(by: sign, step: step)
            } else {
                stopRepeat()
            }
        }) {}
    }

    private func startRepeat(by delta: Int, step: @escaping (Int) -> Void) {
        stopRepeat()
        repeatCancelled = false
        repeatStartTime = Date()
        func scheduleNext(interval: TimeInterval) {
            guard !repeatCancelled else { return }
            let item = DispatchWorkItem {
                guard !repeatCancelled else { return }
                step(delta)
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

    private func primaryButton(snapshot: WODTimerEngineSnapshot, now: Date) -> some View {
        let (title, action): (String, () -> Void) = switch snapshot.state {
        case .idle:
            ("Start", {
                Haptics.light()
                lastHapticRound = 1
                lastHapticPhase = .work
                var e = engine
                e.start(now: now)
                engine = e
            })
        case .running: ("Pause", { var e = engine; e.pause(now: now); engine = e })
        case .paused: ("Resume", { var e = engine; e.resume(now: now); engine = e })
        case .finished: ("Reset", { var e = engine; e.reset(); engine = e })
        }
        return Button(action: action) {
            Text(title)
                .font(.system(size: DesignTokens.Typography.Size.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .contentTransition(.interpolate)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: snapshot.state)
    }

    private func timeString(from interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded()))
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
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
                Text("Support: https://example.com/support")
                    .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                Text("Privacy Policy: https://example.com/privacy")
                    .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
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

// MARK: - watchOS (minimal timer + controls)

#if os(watchOS)
struct ContentView: View {
    @State private var engine = WODTimerEngine(totalDurationMinutes: 10)
    @State private var now: Date = Date()

    private let tickInterval: TimeInterval = 1.0

    var body: some View {
        let snapshot = engine.snapshot(now: now)

        VStack(spacing: 8) {
            Text(timeString(from: snapshot.remainingTime))
                .font(.system(.title2, design: .monospaced).monospacedDigit())

            Text("R \(snapshot.currentRound)/\(engine.totalDurationMinutes)")
                .font(.caption)
                .opacity(0.8)

            HStack(spacing: 6) {
                switch snapshot.state {
                case .idle:
                    Button("Start") {
                        engine.start(now: now)
                    }
                case .running:
                    Button("Pause") {
                        engine.pause(now: now)
                    }
                case .paused:
                    Button("Resume") {
                        engine.resume(now: now)
                    }
                case .finished:
                    Button("Reset") {
                        engine.reset()
                    }
                }
            }
        }
        .onAppear {
            startTicker()
        }
    }

    private func startTicker() {
        Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
            now = Date()
            var e = engine
            e.tick(now: now)
            engine = e
        }
    }

    private func timeString(from interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded()))
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
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

    @Environment(\.colorScheme) private var scheme

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
                var e = engine
                e.reset()
                engine = e
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
                    modeSwitch
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
                    doneView(totalRounds: totalRounds)
                        .transition(.opacity)
                } else if !canEdit {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Text(timeString(from: snapshot.remainingTime))
                            .font(.system(size: TVOSTypography.display, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                            .frame(maxWidth: .infinity)

                        Text(roundLabel(snapshot: snapshot, totalRounds: totalRounds))
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
                        roundsSelector()
                            .opacity(timerMode == .emom ? 1 : 0)
                            .allowsHitTesting(timerMode == .emom)
                        intervalsControls()
                            .opacity(timerMode == .intervals ? 1 : 0)
                            .allowsHitTesting(timerMode == .intervals)
                    }
                    .animation(.easeInOut(duration: 0.25), value: timerMode)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                }

                Spacer()

                VStack(spacing: DesignTokens.Spacing.xl) {
                    primaryButton(snapshot: snapshot, now: now)
                    if showCancel {
                        cancelButton
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
    }

    private var modeHelpText: String {
        switch timerMode {
        case .emom:
            return "Select the number of rounds. Each round is one minute."
        case .intervals:
            return "Set work time, rest time, and number of rounds."
        }
    }

    private var modeSwitch: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ForEach(TimerUIMode.allCases, id: \.self) { mode in
                Button {
                    timerMode = mode
                    syncEngineIfIdle(engine.state)
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: TVOSTypography.base, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                        .foregroundStyle(timerMode == mode ? DesignTokens.Common.onPrimary(scheme) : DesignTokens.Common.Text.primary(scheme))
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(timerMode == mode ? DesignTokens.Common.primary(scheme) : DesignTokens.Common.Background.card(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                }
                .buttonStyle(.card)
                .focusEffectDisabled()
            }
        }
    }

    private func roundsSelector() -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text("Rounds")
                .font(.system(size: TVOSTypography.sm, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))

            HStack(spacing: DesignTokens.Spacing.xxl) {
                Button("−") {
                    rounds = max(roundsRange.lowerBound, rounds - 1)
                    syncEngineIfIdle(engine.state)
                }
                .font(.system(size: TVOSTypography.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .frame(width: 80, height: 80)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .buttonStyle(.plain)

                Text("\(rounds)")
                    .font(.system(size: TVOSTypography.title, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                    .frame(minWidth: 100)

                Button("+") {
                    rounds = min(roundsRange.upperBound, rounds + 1)
                    syncEngineIfIdle(engine.state)
                }
                .font(.system(size: TVOSTypography.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .frame(width: 80, height: 80)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .buttonStyle(.plain)
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }

    private func intervalsControls() -> some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            intervalStepper(label: "Work (sec)", value: $intervalsWork, range: intervalsWorkRange)
            intervalStepper(label: "Rest (sec)", value: $intervalsRest, range: intervalsRestRange)
            intervalStepper(label: "Rounds", value: $intervalsRounds, range: intervalsRoundsRange)
        }
    }

    private func intervalStepper(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text(label)
                .font(.system(size: TVOSTypography.sm, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            HStack(spacing: DesignTokens.Spacing.xxl) {
                Button("−") {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
                    syncEngineIfIdle(engine.state)
                }
                .font(.system(size: TVOSTypography.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .frame(width: 80, height: 80)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .buttonStyle(.plain)

                Text("\(value.wrappedValue)")
                    .font(.system(size: TVOSTypography.title, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                    .frame(minWidth: 100)

                Button("+") {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
                    syncEngineIfIdle(engine.state)
                }
                .font(.system(size: TVOSTypography.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .frame(width: 80, height: 80)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .buttonStyle(.plain)
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
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

    private func roundLabel(snapshot: WODTimerEngineSnapshot, totalRounds: Int) -> String {
        "Round \(snapshot.currentRound) / \(totalRounds) Rounds"
    }

    private func doneView(totalRounds: Int) -> some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80, weight: .medium))
                .foregroundStyle(DesignTokens.Common.primary(scheme))
            Text("Done")
                .font(.system(size: TVOSTypography.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
            Text("You completed \(totalRounds) round\(totalRounds == 1 ? "" : "s")")
                .font(.system(size: TVOSTypography.base, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
        }
        .padding(.vertical, DesignTokens.Spacing.xxxl)
    }

    private func primaryButton(snapshot: WODTimerEngineSnapshot, now: Date) -> some View {
        let (title, action): (String, () -> Void) = switch snapshot.state {
        case .idle:
            ("Start", { var e = engine; e.start(now: now); engine = e })
        case .running: ("Pause", { var e = engine; e.pause(now: now); engine = e })
        case .paused: ("Resume", { var e = engine; e.resume(now: now); engine = e })
        case .finished: ("Reset", { var e = engine; e.reset(); engine = e })
        }
        return Button(action: action) {
            Text(title)
                .font(.system(size: TVOSTypography.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .contentTransition(.interpolate)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.lg)
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
        .buttonStyle(.card)
        .focusEffectDisabled()
        .animation(.easeInOut(duration: 0.2), value: snapshot.state)
    }

    private var cancelButton: some View {
        Button {
            showCancelConfirmation = true
        } label: {
            Text("Cancel")
                .font(.system(size: TVOSTypography.lg, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.ColorToken.State.onError)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .background(DesignTokens.ColorToken.State.error)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
        }
        .buttonStyle(.card)
        .focusEffectDisabled()
    }

    private func timeString(from interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded()))
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
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
                Text("Support: https://example.com/support")
                    .font(.system(size: TVOSTypography.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                Text("Privacy Policy: https://example.com/privacy")
                    .font(.system(size: TVOSTypography.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
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

    @State private var repeatWorkItem: DispatchWorkItem?
    @State private var repeatStartTime: Date?
    @State private var repeatCancelled = false
    @State private var showCancelConfirmation = false
    @State private var showAbout = false

    var body: some View {
        let snapshot = engine.snapshot(now: now)
        let isIdle = snapshot.state == .idle
        let isFinished = snapshot.state == .finished
        let showCancel = snapshot.state == .running || snapshot.state == .paused
        let totalRounds = engine.rounds

        ZStack(alignment: .topTrailing) {
            VStack(spacing: DesignTokens.Spacing.xxxl) {
                if isIdle {
                    modeSwitch
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
                    macDoneView(totalRounds: totalRounds)
                        .transition(.opacity)
                } else if snapshot.state == .running || snapshot.state == .paused {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Text(timeString(from: snapshot.remainingTime))
                            .font(.system(size: DesignTokens.Typography.Size.display, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                            .frame(maxWidth: .infinity)
                        Text(roundLabel(snapshot: snapshot, totalRounds: totalRounds))
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
                        roundsSelector(applyToEngine: { syncEngineIfIdle(engine.state) })
                            .opacity(timerMode == .emom ? 1 : 0)
                            .allowsHitTesting(timerMode == .emom)
                        intervalsControls(syncEngine: { syncEngineIfIdle(engine.state) })
                            .opacity(timerMode == .intervals ? 1 : 0)
                            .allowsHitTesting(timerMode == .intervals)
                    }
                    .animation(.easeInOut(duration: 0.25), value: timerMode)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }

                Spacer()

                VStack(spacing: DesignTokens.Spacing.lg) {
                    primaryButton(snapshot: snapshot, now: now)
                    if showCancel { cancelButton }
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
        .sheet(isPresented: $showAbout) { MacAboutView() }
        .confirmationDialog("Cancel workout?", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            Button("Cancel workout", role: .destructive) {
                var e = engine
                e.reset()
                engine = e
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("You'll return to setup. Current progress will be lost.")
        }
    }

    private func roundLabel(snapshot: WODTimerEngineSnapshot, totalRounds: Int) -> String {
        "Round \(snapshot.currentRound) / \(totalRounds) Rounds"
    }

    private func macDoneView(totalRounds: Int) -> some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(DesignTokens.Common.primary(scheme))
            Text("Done")
                .font(.system(size: DesignTokens.Typography.Size.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
            Text("You completed \(totalRounds) round\(totalRounds == 1 ? "" : "s")")
                .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
        }
        .padding(.vertical, DesignTokens.Spacing.xxl)
    }

    private var modeHelpText: String {
        switch timerMode {
        case .emom: return "Select the number of rounds. Each round is one minute."
        case .intervals: return "Set work time, rest time, and number of rounds."
        }
    }

    private var modeSwitch: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(TimerUIMode.allCases, id: \.self) { mode in
                Button {
                    timerMode = mode
                    syncEngineIfIdle(engine.state)
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                        .foregroundStyle(timerMode == mode ? DesignTokens.Common.onPrimary(scheme) : DesignTokens.Common.Text.primary(scheme))
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(timerMode == mode ? DesignTokens.Common.primary(scheme) : DesignTokens.Common.Background.card(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func intervalsControls(syncEngine: @escaping () -> Void) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            intervalStepper(label: "Work (sec)", value: $intervalsWork, range: intervalsWorkRange) { syncEngine() }
            intervalStepper(label: "Rest (sec)", value: $intervalsRest, range: intervalsRestRange) { syncEngine() }
            intervalStepper(label: "Rounds", value: $intervalsRounds, range: intervalsRoundsRange) { syncEngine() }
        }
    }

    private func intervalStepper(label: String, value: Binding<Int>, range: ClosedRange<Int>, onChange: @escaping () -> Void) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text(label)
                .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            HStack(spacing: DesignTokens.Spacing.xl) {
                Button("−") { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1); onChange() }
                    .font(.system(size: DesignTokens.Typography.Size.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                    .frame(width: DesignTokens.Spacing.xxxl * 2, height: DesignTokens.Spacing.xxxl * 2)
                    .background(DesignTokens.Common.primary(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    .buttonStyle(.plain)
                Text("\(value.wrappedValue)")
                    .font(.system(size: DesignTokens.Typography.Size.title, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                    .frame(minWidth: DesignTokens.Spacing.xxxl * 2)
                Button("+") { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1); onChange() }
                    .font(.system(size: DesignTokens.Typography.Size.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                    .frame(width: DesignTokens.Spacing.xxxl * 2, height: DesignTokens.Spacing.xxxl * 2)
                    .background(DesignTokens.Common.primary(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    .buttonStyle(.plain)
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }

    private var cancelButton: some View {
        Button { showCancelConfirmation = true } label: {
            Text("Cancel")
                .font(.system(size: DesignTokens.Typography.Size.lg, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.ColorToken.State.onError)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .background(DesignTokens.ColorToken.State.error)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
        }
        .buttonStyle(.plain)
    }

    private func syncEngineIfIdle(_ state: WODTimerEngineState) {
        guard state == .idle || state == .finished else { return }
        switch timerMode {
        case .emom: engine = WODTimerEngine(totalDurationMinutes: rounds)
        case .intervals: engine = WODTimerEngine(workSeconds: intervalsWork, restSeconds: intervalsRest, rounds: intervalsRounds)
        }
    }

    private func roundsSelector(applyToEngine: @escaping () -> Void) -> some View {
        func step(by delta: Int) {
            rounds = min(roundsRange.upperBound, max(roundsRange.lowerBound, rounds + delta))
            applyToEngine()
        }
        return VStack(spacing: DesignTokens.Spacing.lg) {
            Text("Rounds")
                .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            HStack(spacing: DesignTokens.Spacing.xl) {
                roundStepperButton(sign: -1, step: step)
                Text("\(rounds)")
                    .font(.system(size: DesignTokens.Typography.Size.title, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                    .frame(minWidth: DesignTokens.Spacing.xxxl * 2)
                roundStepperButton(sign: 1, step: step)
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }

    private func roundStepperButton(sign: Int, step: @escaping (Int) -> Void) -> some View {
        let label = sign < 0 ? "−" : "+"
        return Button { step(sign) } label: {
            Text(label)
                .font(.system(size: DesignTokens.Typography.Size.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .frame(width: DesignTokens.Spacing.xxxl * 2, height: DesignTokens.Spacing.xxxl * 2)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.4, pressing: { pressing in
            if pressing { startRepeat(by: sign, step: step) } else { stopRepeat() }
        }) {}
    }

    private func startRepeat(by delta: Int, step: @escaping (Int) -> Void) {
        stopRepeat()
        repeatCancelled = false
        repeatStartTime = Date()
        func scheduleNext(interval: TimeInterval) {
            guard !repeatCancelled else { return }
            let item = DispatchWorkItem {
                guard !repeatCancelled else { return }
                step(delta)
                let elapsed = repeatStartTime.map { Date().timeIntervalSince($0) } ?? 0
                scheduleNext(interval: elapsed > 0.8 ? 0.12 : 0.35)
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

    private func primaryButton(snapshot: WODTimerEngineSnapshot, now: Date) -> some View {
        let (title, action): (String, () -> Void) = switch snapshot.state {
        case .idle: ("Start", { var e = engine; e.start(now: now); engine = e })
        case .running: ("Pause", { var e = engine; e.pause(now: now); engine = e })
        case .paused: ("Resume", { var e = engine; e.resume(now: now); engine = e })
        case .finished: ("Reset", { var e = engine; e.reset(); engine = e })
        }
        return Button(action: action) {
            Text(title)
                .font(.system(size: DesignTokens.Typography.Size.xxl, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
                .contentTransition(.interpolate)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: snapshot.state)
    }

    private func timeString(from interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded()))
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
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
                Text("Support: https://example.com/support")
                    .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                Text("Privacy Policy: https://example.com/privacy")
                    .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
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
