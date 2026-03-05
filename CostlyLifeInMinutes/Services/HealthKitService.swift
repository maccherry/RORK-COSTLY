import Foundation
import HealthKit

@Observable
@MainActor
class HealthKitService {
    var stepCount: Int = 0
    var activeMinutes: Int = 0
    var sleepHours: Double = 0
    var heartRate: Double = 0
    var distanceKm: Double = 0
    var caloriesBurned: Int = 0
    var isAuthorized: Bool = false
    var isAvailable: Bool = HKHealthStore.isHealthDataAvailable()

    private let healthStore = HKHealthStore()

    private let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(energy) }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(hr) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        if let exercise = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) { types.insert(exercise) }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) { types.insert(distance) }
        return types
    }()

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchAllData()
        } catch {
            isAuthorized = false
        }
    }

    func fetchAllData() async {
        guard isAuthorized else { return }
        async let s = fetchTodaySteps()
        async let e = fetchTodayExerciseMinutes()
        async let sl = fetchLastNightSleep()
        async let hr = fetchLatestHeartRate()
        async let d = fetchTodayDistance()
        async let c = fetchTodayCalories()
        let (steps, exercise, sleep, heartR, dist, cal) = await (s, e, sl, hr, d, c)
        stepCount = steps
        activeMinutes = exercise
        sleepHours = sleep
        heartRate = heartR
        distanceKm = dist
        caloriesBurned = cal
    }

    var healthMinutesBalance: Int {
        var total = 0
        let stepBonus = stepCount / 1000
        total += stepBonus
        total += activeMinutes
        if sleepHours >= 7.5 {
            total += 15
        } else if sleepHours >= 6.0 {
            total += 0
        } else if sleepHours > 0 {
            total -= 10
        }
        return total
    }

    private func fetchTodaySteps() async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(value))
            }
            healthStore.execute(query)
        }
    }

    private func fetchTodayExerciseMinutes() async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return 0 }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                continuation.resume(returning: Int(value))
            }
            healthStore.execute(query)
        }
    }

    private func fetchLastNightSleep() async -> Double {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                let asleepSamples = samples.filter { $0.value != HKCategoryValueSleepAnalysis.inBed.rawValue }
                let totalSeconds = asleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: totalSeconds / 3600.0)
            }
            healthStore.execute(query)
        }
    }

    private func fetchLatestHeartRate() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return 0 }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0)
                    return
                }
                let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: bpm)
            }
            healthStore.execute(query)
        }
    }

    private func fetchTodayDistance() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return 0 }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchTodayCalories() async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: Int(value))
            }
            healthStore.execute(query)
        }
    }
}
