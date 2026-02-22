//
//  WatchContentView.swift
//  WODrounds Watch App
//
//  Timer + count-in; synced with iPhone when workout is started there.
//

import SwiftUI

struct WatchContentView: View {
    @State private var engine = WODTimerEngine(totalDurationMinutes: 10)
    @State private var countdownEndTime: Date? = nil
    @Environment(\.colorScheme) private var colorScheme

    private func timeString(from interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(ceil(interval)))
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
            let now = timeline.date
            let syncedPayload = WODTimerSync.read()
            let syncedSnapshot = syncedPayload.flatMap { WODTimerSync.snapshot(from: $0, now: now) }
            let useSynced = syncedSnapshot.map { $0.state == .running || $0.state == .paused } ?? false
            let (remainingTime, currentRound, totalRounds, state): (TimeInterval, Int, Int, WODTimerEngineState) = {
                if useSynced, let s = syncedSnapshot {
                    return (s.remainingTime, s.currentRound, s.totalRounds, s.state)
                }
                let local = engine.snapshot(now: now)
                return (local.remainingTime, local.currentRound, engine.totalDurationMinutes, local.state)
            }()

            ZStack {
                WatchDesign.Colors.background(colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: WatchDesign.Spacing.lg) {
                    if useSynced {
                        Text("iPhone", bundle: .main)
                            .font(.system(size: WatchDesign.roundFontSize, weight: .medium, design: .rounded))
                            .foregroundStyle(WatchDesign.Colors.textTertiary(colorScheme))
                    }

                    Text(timeString(from: remainingTime))
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
                            case .running:
                                Button("Pause") {
                                    engine.pause(now: now)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(WatchDesign.Colors.primary(colorScheme))
                            case .paused:
                                Button("Resume") {
                                    engine.resume(now: now)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(WatchDesign.Colors.primary(colorScheme))
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
                        }
                    }
                }
                .onChange(of: timeline.date) { _, newDate in
                    if let end = countdownEndTime, newDate >= end {
                        var e = engine
                        e.start(now: end)
                        engine = e
                        countdownEndTime = nil
                    } else if engine.state == .running {
                        var e = engine
                        e.tick(now: newDate)
                        engine = e
                    }
                }
            }
        }
    }
}
