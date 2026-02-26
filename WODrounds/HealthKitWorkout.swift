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
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        ]
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    /// Call when the timer starts (after countdown). Begins collecting workout data.
    /// Requests authorization is done before countdown (in UI); we try to start and rely on beginCollection error if not authorized.
    func startWorkout(startDate: Date) {
        guard HKHealthStore.isHealthDataAvailable(), builder == nil else { return }
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
        currentBuilder.endCollection(withEnd: endDate) { [weak self, weak currentBuilder] _, error in
            guard error == nil, let b = currentBuilder, let self = self else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            self.fetchLatestBodyMass { weightInKg in
                let mass = weightInKg ?? 75.0 // Fallback to 75kg if no weight permission/data
                let startDate = b.startDate ?? endDate
                let durationMinutes = max(0, endDate.timeIntervalSince(startDate)) / 60.0

                // HIIT MET value is generally defined around 8.0 by standard compendiums
                let met: Double = 8.0
                let totalKcal = (met * 3.5 * mass / 200.0) * durationMinutes

                if totalKcal > 0, let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                    let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: totalKcal)
                    let sample = HKQuantitySample(type: energyType, quantity: quantity, start: startDate, end: endDate)
                    b.add([sample]) { _, _ in
                        b.finishWorkout { _, finishError in
                            DispatchQueue.main.async { completion?(finishError == nil) }
                        }
                    }
                } else {
                    b.finishWorkout { _, finishError in
                        DispatchQueue.main.async { completion?(finishError == nil) }
                    }
                }
            }
        }
    }

    private func fetchLatestBodyMass(completion: @escaping (Double?) -> Void) {
        guard let massType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: massType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            let weightInKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            completion(weightInKg)
        }
        healthStore.execute(query)
    }

    /// Call if the user cancels before any real workout (e.g. countdown aborted). No-op if no workout was started.
    func discardWorkout() {
        builder?.discardWorkout()
        builder = nil
    }
}
#endif
