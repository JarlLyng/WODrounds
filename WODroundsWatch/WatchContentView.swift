//
//  WatchContentView.swift
//  WODrounds Watch App
//
//  Timer + count-in; synced with iPhone when workout is started there.
//

import SwiftUI
import WatchKit

// Local copies of the shared setup ranges (ContentView.swift is not a member
// of the Watch target). Keep in sync with WODrounds/ContentView.swift.
private let watchRoundsRange = 1 ... 120
private let watchEmomLengthRange = 30 ... 570
private let watchIntervalsWorkRange = 5 ... 300
private let watchIntervalsRestRange = 0 ... 180
private let watchIntervalsRoundsRange = 1 ... 60

// MARK: - Watch Content View

struct WatchContentView: View {
    // Local (standalone) workout configuration, persisted between launches.
    @AppStorage("watchTimerMode") private var storedMode: String = "emom"
    @AppStorage("watchEmomRounds") private var emomRounds: Int = 10
    @AppStorage("watchEmomLength") private var emomLength: Int = 60
    @AppStorage("watchIntervalsWork") private var intervalsWork: Int = 30
    @AppStorage("watchIntervalsRest") private var intervalsRest: Int = 15
    @AppStorage("watchIntervalsRounds") private var intervalsRounds: Int = 8

    @State private var engine = WODTimerEngine(emomRounds: 10, secondsPerRound: 60)
    @State private var countdownEndTime: Date? = nil
    @Environment(\.colorScheme) private var colorScheme
    @State private var flashScreen = false
    @State private var lastFlashRound = 0
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var workoutSession = WatchWorkoutSession.shared
    @State private var wasWorkoutActive = false

    private func rebuildEngine() {
        if storedMode == "intervals" {
            engine = WODTimerEngine(workSeconds: intervalsWork, restSeconds: intervalsRest, rounds: intervalsRounds)
        } else {
            engine = WODTimerEngine(emomRounds: emomRounds, secondsPerRound: emomLength)
        }
    }

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
            // Synced For Time counts up and has no rounds (Watch only follows iPhone
            // For Time; there is no local For Time mode on the Watch).
            let isSyncedForTime = useSynced && syncedPayload?.mode == "forTime"
            let (displayTime, currentRound, totalRounds, state): (TimeInterval, Int, Int, WODTimerEngineState) = {
                if useSynced, let s = syncedSnapshot, let payload = syncedPayload {
                    let disp: TimeInterval
                    switch payload.mode {
                    case "emom": disp = s.remainingTimeInPhase
                    case "forTime": disp = s.elapsedTime
                    default: disp = s.remainingTime
                    }
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

                if !useSynced && state == .idle {
                    // Standalone setup: mode switch + steppers + Start (#32/#33).
                    configView(now: now)
                } else {
                    VStack(spacing: WatchDesign.Spacing.lg) {
                        if useSynced {
                            Text("iPhone", bundle: .main)
                                .font(.system(size: WatchDesign.roundFontSize, weight: .medium, design: .rounded))
                                .foregroundStyle(WatchDesign.Colors.textTertiary(colorScheme))
                        }

                        // Count-up (For Time) floors so the shown time never runs ahead;
                        // count-down keeps ceiling so 0 is only shown when truly done.
                        Text(timeString(from: isSyncedForTime ? floor(displayTime) : displayTime))
                            .font(.system(size: WatchDesign.timerFontSize, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(WatchDesign.Colors.textPrimary(colorScheme))

                        if !isSyncedForTime {
                            Text("R \(currentRound)/\(totalRounds)")
                                .font(.system(size: WatchDesign.roundFontSize, weight: .semibold, design: .rounded))
                                .foregroundStyle(WatchDesign.Colors.textSecondary(colorScheme))
                        }

                        if useSynced {
                            Text("Following iPhone", bundle: .main)
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundStyle(WatchDesign.Colors.textTertiary(colorScheme))
                        } else {
                            HStack(spacing: WatchDesign.Spacing.sm) {
                                switch state {
                                case .idle:
                                    EmptyView() // idle renders configView above
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
                }

                // Full-screen flash overlay (placed at ZStack level so it covers the entire
                // screen — previously it was attached to the padded VStack and only covered
                // the content area).
                WatchDesign.Colors.textPrimary(colorScheme)
                    .ignoresSafeArea()
                    .opacity(flashScreen ? 0.85 : 0)
                    .animation(.easeInOut(duration: 0.35), value: flashScreen)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                // Full-screen countdown overlay
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
                        .ignoresSafeArea()
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Countdown, \(remaining) seconds")
                    }
                }
            }
            .onChange(of: timeline.date) { newDate in
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
            .onChange(of: useSynced) { _ in
                // When sync state toggles (iPhone connects/disconnects mid-workout), the
                // displayed currentRound may jump (e.g., from local 0 to synced 5). Reset
                // the haptic baseline so we don't fire a spurious notification haptic for
                // a jump that isn't a real round transition.
                lastFlashRound = currentRound
            }
            .onChange(of: currentRound) { newRound in
                if (state == .running || state == .paused), newRound > lastFlashRound {
                    triggerFlash()
                    WKInterfaceDevice.current().play(.notification)
                    lastFlashRound = newRound
                }
            }
            .onChange(of: state) { newState in
                if newState == .finished {
                    WKInterfaceDevice.current().play(.success)
                }
                if newState == .idle {
                    // Reset baseline so next workout starts fresh
                    lastFlashRound = 0
                }
            }
            .onChange(of: workoutActive) { isActive in
                if isActive {
                    workoutSession.startIfNeeded()
                } else {
                    workoutSession.stop()
                }
            }
            .onAppear {
                rebuildEngine()
            }
        }
    }

    // MARK: - Standalone setup (#32 / #33)

    private func lengthString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func configView(now: Date) -> some View {
        ScrollView {
            VStack(spacing: WatchDesign.Spacing.md) {
                // Mode switch
                HStack(spacing: WatchDesign.Spacing.sm) {
                    modeButton("EMOM", mode: "emom")
                    modeButton("Intervals", mode: "intervals")
                }

                if storedMode == "intervals" {
                    configRow("WORK", value: lengthString(intervalsWork),
                              range: watchIntervalsWorkRange, step: 5, binding: $intervalsWork)
                    configRow("REST", value: lengthString(intervalsRest),
                              range: watchIntervalsRestRange, step: 5, binding: $intervalsRest)
                    configRow("ROUNDS", value: "\(intervalsRounds)",
                              range: watchIntervalsRoundsRange, step: 1, binding: $intervalsRounds)
                } else {
                    configRow("ROUNDS", value: "\(emomRounds)",
                              range: watchRoundsRange, step: 1, binding: $emomRounds)
                    configRow("LENGTH", value: lengthString(emomLength),
                              range: watchEmomLengthRange, step: 30, binding: $emomLength)
                }

                Button("Start") {
                    rebuildEngine()
                    countdownEndTime = now.addingTimeInterval(10)
                    // Start the HKWorkoutSession immediately so the app stays
                    // alive during the 10s countdown (same fix as before).
                    workoutSession.startIfNeeded()
                }
                .buttonStyle(.borderedProminent)
                .tint(WatchDesign.Colors.primary(colorScheme))
                .foregroundStyle(WatchDesign.Colors.onPrimary)
                .padding(.top, WatchDesign.Spacing.xs)
            }
            .padding(.horizontal, WatchDesign.Spacing.md)
            .padding(.vertical, WatchDesign.Spacing.sm)
        }
    }

    private func modeButton(_ title: LocalizedStringKey, mode: String) -> some View {
        let isActive = storedMode == mode
        return Button(title) {
            storedMode = mode
            rebuildEngine()
        }
        .font(.system(size: 11, weight: isActive ? .semibold : .regular, design: .rounded))
        .buttonStyle(.bordered)
        .tint(isActive ? WatchDesign.Colors.primary(colorScheme) : nil)
        .foregroundStyle(isActive
                         ? WatchDesign.Colors.textPrimary(colorScheme)
                         : WatchDesign.Colors.textSecondary(colorScheme))
    }

    /// `label` is the English catalog key ("WORK"), localized here for display and
    /// again for the VoiceOver labels. Without those labels the three rows read out
    /// as six identical "plus" / "minus" buttons with no clue what each one changes.
    private func configRow(_ label: String, value: String,
                           range: ClosedRange<Int>, step: Int,
                           binding: Binding<Int>) -> some View {
        let name = String(localized: String.LocalizationValue(label))
        return HStack(spacing: WatchDesign.Spacing.sm) {
            Button {
                binding.wrappedValue = max(range.lowerBound, binding.wrappedValue - step)
                rebuildEngine()
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(.bordered)
            .disabled(binding.wrappedValue <= range.lowerBound)
            .accessibilityLabel(String(localized: "Decrease \(name)"))

            VStack(spacing: 0) {
                Text(LocalizedStringKey(label))
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(WatchDesign.Colors.textTertiary(colorScheme))
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WatchDesign.Colors.textPrimary(colorScheme))
            }
            .frame(maxWidth: .infinity)
            // Otherwise the name and the number are two separate stops.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(name)
            .accessibilityValue(value)

            Button {
                binding.wrappedValue = min(range.upperBound, binding.wrappedValue + step)
                rebuildEngine()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
            .disabled(binding.wrappedValue >= range.upperBound)
            .accessibilityLabel(String(localized: "Increase \(name)"))
        }
    }

    private func triggerFlash() {
        flashScreen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            flashScreen = false
        }
    }
}
