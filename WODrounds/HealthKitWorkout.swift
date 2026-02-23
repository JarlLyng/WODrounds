//
//  HealthKitWorkout.swift
//  WODrounds
//
//  Saves completed workouts to Apple Health so Fitness and Activity show training.
//  iOS only.
//

#if os(iOS)
import Foundation
import HealthKit

/// Starts and ends a HealthKit workout so it appears in Apple Health when the user trains.
final class HealthKitWorkoutController {
    private let healthStore = HKHealthStore()
    private var builder: HKWorkoutBuilder?
    private let activityType: HKWorkoutActivityType = .highIntensityIntervalTraining

    static let shared = HealthKitWorkoutController()

    private init() {}

    /// Call once (e.g. when app launches or before first workout). Requests permission to save workouts.
    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        let typesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        healthStore.requestAuthorization(toShare: typesToShare, read: nil) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    /// Call when the timer starts (after countdown). Begins collecting workout data.
    /// Only starts if Health is available and app is authorized to share workout type (see Apple: "Check for authorization before saving data").
    func startWorkout(startDate: Date) {
        guard HKHealthStore.isHealthDataAvailable(), builder == nil else { return }
        let workoutType = HKObjectType.workoutType()
        guard healthStore.authorizationStatus(for: workoutType) == .sharingAuthorized else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        config.locationType = .indoor
        let newBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: config, device: .local())
        builder = newBuilder
        newBuilder.beginCollection(withStart: startDate) { [weak self] _, error in
            if error != nil {
                self?.builder = nil
            }
        }
    }

    /// Call when the workout ends (finished, reset, or cancel). Saves the workout to Health.
    func endWorkout(endDate: Date, completion: ((Bool) -> Void)? = nil) {
        guard let currentBuilder = builder else {
            completion?(false)
            return
        }
        builder = nil
        currentBuilder.endCollection(withEnd: endDate) { [weak currentBuilder] _, error in
            guard error == nil, let b = currentBuilder else {
                DispatchQueue.main.async { completion?(false) }
                return
            }
            b.finishWorkout { _, finishError in
                DispatchQueue.main.async {
                    completion?(finishError == nil)
                }
            }
        }
    }

    /// Call if the user cancels before any real workout (e.g. countdown aborted). No-op if no workout was started.
    func discardWorkout() {
        builder?.discardWorkout()
        builder = nil
    }
}
#endif
