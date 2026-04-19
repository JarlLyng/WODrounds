//
//  WatchWorkoutSession.swift
//  WODrounds Watch App
//
//  Manages an HKWorkoutSession to keep the Watch app active during workouts.
//  Unlike WKExtendedRuntimeSession (which expires), HKWorkoutSession keeps
//  the app running indefinitely while a workout is in progress.
//

import Foundation
import HealthKit

final class WatchWorkoutSession: NSObject, ObservableObject, HKWorkoutSessionDelegate {
    static let shared = WatchWorkoutSession()

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    @Published var isSessionActive = false

    private override init() {
        super.init()
    }

    /// Request HealthKit authorization (call once, e.g. at app launch).
    func requestAuthorizationIfNeeded() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let typesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        let typesToRead: Set<HKObjectType> = []
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { _, error in
            if let error {
                print("[WatchWorkout] Authorization error: \(error.localizedDescription)")
            }
        }
    }

    /// Start an HKWorkoutSession to keep the Watch app in the foreground.
    func startIfNeeded() {
        guard session == nil, HKHealthStore.isHealthDataAvailable() else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .highIntensityIntervalTraining
        config.locationType = .indoor
        do {
            let newSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            newSession.delegate = self
            session = newSession
            newSession.startActivity(with: Date())
            DispatchQueue.main.async { self.isSessionActive = true }
        } catch {
            print("[WatchWorkout] Failed to create session: \(error.localizedDescription)")
        }
    }

    /// End the session when the workout finishes or is cancelled.
    func stop() {
        guard let s = session else { return }
        s.end()
        session = nil
        DispatchQueue.main.async { self.isSessionActive = false }
    }

    // MARK: - HKWorkoutSessionDelegate

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        DispatchQueue.main.async {
            self.isSessionActive = (toState == .running || toState == .paused)
        }
        if toState == .ended {
            DispatchQueue.main.async {
                self.session = nil
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didFailWithError error: Error) {
        print("[WatchWorkout] Session failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.session = nil
            self.isSessionActive = false
        }
    }
}
