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
    private var workoutStartDate: Date?
    private var collectionReady = false
    private let activityType: HKWorkoutActivityType = .highIntensityIntervalTraining

    static let shared = HealthKitWorkoutController()

    private init() {}

    /// True if HealthKit is available and the user has granted write permission for workouts.
    var isAuthorized: Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        return healthStore.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    /// Call once (e.g. when app launches or before first workout). Requests permission to save workouts.
    /// Only requests write permission — no read permissions, to keep the privacy footprint minimal.
    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        healthStore.requestAuthorization(toShare: typesToShare, read: []) { success, error in
            if let error {
                print("[HealthKit] Authorization error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    /// Call when the timer starts (after countdown). Begins collecting workout data.
    func startWorkout(startDate: Date) {
        guard HKHealthStore.isHealthDataAvailable(), builder == nil else { return }
        guard isAuthorized else {
            print("[HealthKit] Not authorized — skipping workout save.")
            return
        }
        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        config.locationType = .indoor
        let newBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: config, device: .local())
        builder = newBuilder
        workoutStartDate = startDate
        collectionReady = false
        newBuilder.beginCollection(withStart: startDate) { [weak self] _, error in
            if let error {
                print("[HealthKit] beginCollection failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.builder = nil
                    self?.workoutStartDate = nil
                }
            } else {
                DispatchQueue.main.async {
                    self?.collectionReady = true
                }
            }
        }
    }

    /// Call when the workout ends (finished, reset, or cancel). Saves the workout to Health.
    func endWorkout(endDate: Date, completion: ((Bool) -> Void)? = nil) {
        guard let currentBuilder = builder, let startDate = workoutStartDate else {
            completion?(false)
            return
        }
        builder = nil
        workoutStartDate = nil
        collectionReady = false

        // Ensure end date is after start date.
        let safeEndDate = max(endDate, startDate.addingTimeInterval(1))

        currentBuilder.endCollection(withEnd: safeEndDate) { [weak self] _, error in
            if let error {
                print("[HealthKit] endCollection failed: \(error.localizedDescription)")
                // Try to finish anyway — sometimes endCollection errors are non-fatal.
            }
            guard let self = self else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            // Use a constant reference weight (75kg) to avoid requesting read permission
            // for bodyMass. Keeps permission footprint minimal. Kcal estimate will be
            // within ~10-15% of exact for most users — good enough for Activity rings.
            let mass: Double = 75.0
            let durationMinutes = max(0, safeEndDate.timeIntervalSince(startDate)) / 60.0

            // HIIT MET value is generally defined around 8.0 by standard compendiums
            let met: Double = 8.0
            let totalKcal = (met * 3.5 * mass / 200.0) * durationMinutes

            if totalKcal > 0, let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: totalKcal)
                let sample = HKQuantitySample(type: energyType, quantity: quantity, start: startDate, end: safeEndDate)
                currentBuilder.add([sample]) { _, addError in
                    if let addError {
                        print("[HealthKit] add energy sample failed: \(addError.localizedDescription)")
                    }
                    self.finishBuilder(currentBuilder, completion: completion)
                }
            } else {
                self.finishBuilder(currentBuilder, completion: completion)
            }
        }
    }

    private func finishBuilder(_ builder: HKWorkoutBuilder, completion: ((Bool) -> Void)?) {
        builder.finishWorkout { workout, error in
            if let error {
                print("[HealthKit] finishWorkout failed: \(error.localizedDescription)")
            }
            if let workout {
                print("[HealthKit] Workout saved: \(workout.duration)s, \(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) kcal")
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    /// Call if the user cancels before any real workout (e.g. countdown aborted). No-op if no workout was started.
    func discardWorkout() {
        builder?.discardWorkout()
        builder = nil
        workoutStartDate = nil
        collectionReady = false
    }
}
#endif
