//
//  ContentView.swift
//  WODrounds
//

import SwiftUI

#if os(iOS)
import UIKit
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
private let roundsRange = 1 ... 120
private let roundsPresets = [10, 12, 20, 30]
private let intervalsWorkRange = 5 ... 300
private let intervalsRestRange = 0 ... 180
private let intervalsRoundsRange = 1 ... 60

enum TimerUIMode: String, CaseIterable {
    case emom = "EMOM"
    case intervals = "Intervals"
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
        let showCancel = snapshot.state == .running || snapshot.state == .paused
        let totalRounds = engine.rounds

        ZStack(alignment: .topTrailing) {
        VStack(spacing: DesignTokens.Spacing.xxxl) {
            Spacer()

            Text(timeString(from: snapshot.remainingTime))
                .font(.system(size: DesignTokens.Typography.Size.display, weight: DesignTokens.Typography.Weight.bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                .frame(maxWidth: .infinity)

            Text(roundLabel(snapshot: snapshot, totalRounds: totalRounds))
                .font(.system(size: DesignTokens.Typography.Size.lg, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))

            if canEdit && timerMode == .emom {
                Text("1:00 per round")
                    .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                Text("Total: \(timeString(from: engine.totalDurationSeconds))")
                    .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }
            if canEdit && timerMode == .intervals {
                Text("Total: \(timeString(from: engine.totalDurationSeconds))")
                    .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }
            if !canEdit && timerMode == .intervals {
                Text(snapshot.currentPhase == .work ? "Work" : "Rest")
                    .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }

            Spacer()

            VStack(spacing: DesignTokens.Spacing.xxl) {
                if canEdit {
                    modeSwitch
                    if timerMode == .emom {
                        roundsSelector(applyToEngine: { syncEngineIfIdle(snapshot.state) })
                        presetChips(applyToEngine: { syncEngineIfIdle(snapshot.state) })
                    } else {
                        intervalsControls(syncEngine: { syncEngineIfIdle(snapshot.state) })
                    }
                }

                primaryButton(snapshot: snapshot, now: now)

                if showCancel {
                    cancelButton
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)

            Spacer()
        }
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

    private func applyIdleTimer(_ state: WODTimerEngineState) {
        switch state {
        case .running, .paused:
            UIApplication.shared.isIdleTimerDisabled = true
        case .idle, .finished:
            UIApplication.shared.isIdleTimerDisabled = false
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
        HStack(spacing: DesignTokens.Spacing.sm) {
            Text(label)
                .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                .frame(width: DesignTokens.Spacing.xxxl * 1.5, alignment: .leading)
            Button("-") {
                value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
                onChange()
            }
            .font(.system(size: DesignTokens.Typography.Size.lg, weight: .bold, design: .monospaced))
            .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
            .frame(width: DesignTokens.Spacing.xxl, height: DesignTokens.Spacing.xxl)
            .background(DesignTokens.Common.primary(scheme))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            .buttonStyle(.plain)
            Text("\(value.wrappedValue)")
                .font(.system(size: DesignTokens.Typography.Size.base, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                .frame(minWidth: DesignTokens.Spacing.xl)
            Button("+") {
                value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
                onChange()
            }
            .font(.system(size: DesignTokens.Typography.Size.lg, weight: .bold, design: .monospaced))
            .foregroundStyle(DesignTokens.Common.onPrimary(scheme))
            .frame(width: DesignTokens.Spacing.xxl, height: DesignTokens.Spacing.xxl)
            .background(DesignTokens.Common.primary(scheme))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            .buttonStyle(.plain)
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

    private func presetChips(applyToEngine: @escaping () -> Void) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(roundsPresets, id: \.self) { value in
                Button {
                    rounds = value
                    applyToEngine()
                } label: {
                    Text("\(value)")
                        .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(rounds == value ? DesignTokens.Common.onPrimary(scheme) : DesignTokens.Common.Text.primary(scheme))
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(rounds == value ? DesignTokens.Common.primary(scheme) : DesignTokens.Common.Background.card(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                }
                .buttonStyle(.plain)
            }
        }
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
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .background(DesignTokens.Common.primary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
        .buttonStyle(.plain)
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
            engine.tick(now: now)
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

// MARK: - tvOS (minimal timer + focusable controls)

#if os(tvOS)
struct ContentView: View {
    @State private var engine = WODTimerEngine(totalDurationMinutes: 10)
    @State private var now: Date = Date()

    private let tickInterval: TimeInterval = 1.0

    var body: some View {
        let snapshot = engine.snapshot(now: now)

        VStack(spacing: 40) {
            Text(timeString(from: snapshot.remainingTime))
                .font(.system(size: 96, weight: .bold, design: .monospaced))
                .focusable(false)

            Text("Round \(snapshot.currentRound) / \(engine.totalDurationMinutes)")
                .font(.title2)
                .opacity(0.8)

            HStack(spacing: 32) {
                switch snapshot.state {
                case .idle:
                    Button("Start") {
                        engine.start(now: now)
                    }
                    .buttonStyle(.card)
                case .running:
                    Button("Pause") {
                        engine.pause(now: now)
                    }
                    .buttonStyle(.card)
                case .paused:
                    Button("Resume") {
                        engine.resume(now: now)
                    }
                    .buttonStyle(.card)
                case .finished:
                    Button("Reset") {
                        engine.reset()
                    }
                    .buttonStyle(.card)
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
            engine.tick(now: now)
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

// MARK: - macOS / visionOS (placeholder or reuse)

#if os(macOS) || os(visionOS)
struct ContentView: View {
    @State private var minutes: Int = 10
    @State private var engine = WODTimerEngine(totalDurationMinutes: 10)
    @State private var now: Date = Date()

    private let tickInterval: TimeInterval = 1.0

    var body: some View {
        let snapshot = engine.snapshot(now: now)

        VStack(spacing: 32) {
            Spacer()

            Text(timeString(from: snapshot.remainingTime))
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .frame(maxWidth: .infinity)

            Text("Round \(snapshot.currentRound) / \(engine.totalDurationMinutes)")
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .opacity(0.7)

            Spacer()

            VStack(spacing: 16) {
                if snapshot.state == .idle || snapshot.state == .finished {
                    Stepper("Minutes: \(minutes)", value: $minutes, in: 1...120)
                        .onChange(of: minutes) { _, newValue in
                            engine = WODTimerEngine(totalDurationMinutes: newValue)
                        }
                }

                HStack(spacing: 16) {
                    switch snapshot.state {
                    case .idle:
                        primaryButton(title: "Start") { engine.start(now: now) }
                    case .running:
                        primaryButton(title: "Pause") { engine.pause(now: now) }
                    case .paused:
                        primaryButton(title: "Resume") { engine.resume(now: now) }
                    case .finished:
                        primaryButton(title: "Reset") { engine.reset() }
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .onAppear { startTicker() }
    }

    private func startTicker() {
        Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
            now = Date()
            engine.tick(now: now)
        }
    }

    private func timeString(from interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded()))
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    @ViewBuilder
    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
    }
}
#endif

// MARK: - Previews (iOS only)

#if os(iOS)
#Preview {
    ContentView()
}
#endif
