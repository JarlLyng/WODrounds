//
//  WatchContentView.swift
//  WODrounds Watch App
//
//  Timer + count-in; synced with iPhone when workout is started there.
//

import SwiftUI
import WatchKit

// MARK: - Watch Content View

struct WatchContentView: View {
    @State private var engine = WODTimerEngine(emomRounds: 10, secondsPerRound: 60)
    @State private var countdownEndTime: Date? = nil
    @Environment(\.colorScheme) private var colorScheme
    @State private var flashScreen = false
    @State private var lastFlashRound = 0
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var workoutSession = WatchWorkoutSession.shared
    @State private var wasWorkoutActive = false

    private func timeString(from interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(ceil(interval)))
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
            let now = timeline.date
            let syncedPayload = sessionManager.receivedPayload
            let syncedSnapshot = syncedPayload.flatMap { WODTimerSync.snapshot(from: $0, now: now) }
            let useSynced = syncedSnapshot.map { $0.state == .running || $0.state == .paused } ?? false
            let (displayTime, currentRound, totalRounds, state): (TimeInterval, Int, Int, WODTimerEngineState) = {
                if useSynced, let s = syncedSnapshot, let payload = syncedPayload {
                    let disp = payload.mode == "emom" ? s.remainingTimeInPhase : s.remainingTime
                    return (disp, s.currentRound, s.totalRounds, s.state)
                }
                let local = engine.snapshot(now: now)
                let isLocalEmom: Bool
                if case .emom = engine.mode { isLocalEmom = true } else { isLocalEmom = false }
                let disp = isLocalEmom ? local.remainingTimeInPhase : local.remainingTime
                // Use engine.rounds (handles both EMOM and Intervals) instead of totalDurationMinutes
                // which returns 0 for intervals. Prevents "R x/0" bug when Watch gains local interval config.
                return (disp, local.currentRound, engine.rounds, local.state)
            }()
            let workoutActive = useSynced || engine.state == .running || engine.state == .paused

            ZStack {
                WatchDesign.Colors.background(colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: WatchDesign.Spacing.lg) {
                    if useSynced {
                        Text("iPhone", bundle: .main)
                            .font(.system(size: WatchDesign.roundFontSize, weight: .medium, design: .rounded))
                            .foregroundStyle(WatchDesign.Colors.textTertiary(colorScheme))
                    }

                    Text(timeString(from: displayTime))
                        .font(.system(size: WatchDesign.timerFontSize, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(WatchDesign.Colors.textPrimary(colorScheme))

                    Text("R \(currentRound)/\(totalRounds)")
                        .font(.system(size: WatchDesign.roundFontSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(WatchDesign.Colors.textSecondary(colorScheme))

                    if useSynced {
                        Text("Following iPhone", bundle: .main)
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(WatchDesign.Colors.textTertiary(colorScheme))
                    } else {
                        HStack(spacing: WatchDesign.Spacing.sm) {
                            switch state {
                            case .idle:
                                Button("Start") {
                                    countdownEndTime = now.addingTimeInterval(10)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(WatchDesign.Colors.primary(colorScheme))
                                .foregroundStyle(WatchDesign.Colors.onPrimary)
                            case .running:
                                Button("Pause") {
                                    engine.pause(now: now)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(WatchDesign.Colors.primary(colorScheme))
                                .foregroundStyle(WatchDesign.Colors.onPrimary)
                            case .paused:
                                Button("Resume") {
                                    engine.resume(now: now)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(WatchDesign.Colors.primary(colorScheme))
                                .foregroundStyle(WatchDesign.Colors.onPrimary)
                            case .finished:
                                Button("Reset") {
                                    engine.reset()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding(WatchDesign.Spacing.md)
                .overlay {
                    WatchDesign.Colors.textPrimary(colorScheme)
                        .ignoresSafeArea()
                        .opacity(flashScreen ? 0.85 : 0)
                        .animation(.easeInOut(duration: 0.35), value: flashScreen)
                        .accessibilityHidden(true)
                }
                .overlay {
                    if let end = countdownEndTime {
                        let remaining = max(0, Int(ceil(end.timeIntervalSince(now))))
                        if remaining > 0 {
                            VStack(spacing: WatchDesign.Spacing.sm) {
                                Text("Get ready")
                                    .font(.system(size: WatchDesign.countdownTitleFontSize, weight: .semibold, design: .rounded))
                                    .foregroundStyle(WatchDesign.Colors.textSecondary(colorScheme))
                                Text("\(remaining)")
                                    .font(.system(size: WatchDesign.countdownNumberFontSize, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(WatchDesign.Colors.textPrimary(colorScheme))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(WatchDesign.Colors.background(colorScheme))
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Countdown, \(remaining) seconds")
                        }
                    }
                }
                .onChange(of: timeline.date) { _, newDate in
                    if let end = countdownEndTime, newDate >= end {
                        var e = engine
                        e.start(now: end)
                        engine = e
                        countdownEndTime = nil
                        WKInterfaceDevice.current().play(.start)
                    } else if engine.state == .running {
                        var e = engine
                        e.tick(now: newDate)
                        engine = e
                    }
                }
                .onChange(of: currentRound) { _, newRound in
                    if (state == .running || state == .paused), newRound > lastFlashRound {
                        triggerFlash()
                        WKInterfaceDevice.current().play(.notification)
                        lastFlashRound = newRound
                    }
                }
                .onChange(of: state) { _, newState in
                    if newState == .finished {
                        WKInterfaceDevice.current().play(.success)
                    }
                }
                .onChange(of: workoutActive) { _, isActive in
                    if isActive {
                        workoutSession.startIfNeeded()
                    } else {
                        workoutSession.stop()
                    }
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
}
