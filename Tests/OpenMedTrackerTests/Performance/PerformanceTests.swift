//
//  PerformanceTests.swift
//  OpenMedTrackerTests
//
//  Performance tests for critical operations
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class PerformanceTests: XCTestCase {

    var persistenceController: PersistenceController!
    var medicationService: MedicationService!
    var scheduleService: ScheduleService!
    var doseHistoryService: DoseHistoryService!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        medicationService = MedicationService(persistenceController: persistenceController)
        scheduleService = ScheduleService(persistenceController: persistenceController)
        doseHistoryService = DoseHistoryService(persistenceController: persistenceController)
    }

    override func tearDown() {
        persistenceController = nil
        medicationService = nil
        scheduleService = nil
        doseHistoryService = nil
        super.tearDown()
    }

    // MARK: - Batch Delete Performance

    func testDeleteManyMedicationsPerformance() throws {
        // Create 1000 medications
        for i in 0..<1000 {
            try medicationService.create(
                name: "Medication \(i)",
                dosageAmount: Double(i),
                dosageUnit: "mg"
            )
        }

        // Measure deletion performance
        measure {
            do {
                try medicationService.deleteAll(includeActive: true)
            } catch {
                XCTFail("Delete failed: \(error)")
            }
        }
    }

    func testDeleteManySchedulesPerformance() throws {
        // Create medication
        let medication = try medicationService.create(
            name: "Test Med",
            dosageAmount: 500,
            dosageUnit: "mg"
        )

        // Create 500 schedules
        for i in 0..<500 {
            try scheduleService.create(
                for: medication,
                hour: i % 24,
                minute: i % 60
            )
        }

        // Measure deletion performance
        measure {
            do {
                try scheduleService.deleteSchedules(for: medication)
            } catch {
                XCTFail("Delete failed: \(error)")
            }

            // Recreate schedules for next iteration
            for i in 0..<500 {
                try! scheduleService.create(
                    for: medication,
                    hour: i % 24,
                    minute: i % 60
                )
            }
        }
    }

    func testDeleteOldDoseHistoryPerformance() throws {
        // Create medication and schedule
        let medication = try medicationService.create(
            name: "Test Med",
            dosageAmount: 500,
            dosageUnit: "mg"
        )

        let schedule = try scheduleService.create(
            for: medication,
            hour: 9,
            minute: 0
        )

        // Create 5000 dose history records (simulating 1+ year of data)
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -365, to: Date())!

        for i in 0..<5000 {
            let scheduledTime = calendar.date(byAdding: .hour, value: i, to: startDate)!
            try doseHistoryService.create(
                for: schedule,
                scheduledTime: scheduledTime
            )
        }

        // Measure deletion of old records
        let cutoffDate = calendar.date(byAdding: .day, value: -180, to: Date())!

        measure {
            do {
                try doseHistoryService.deleteHistory(olderThan: cutoffDate)
            } catch {
                XCTFail("Delete failed: \(error)")
            }

            // Recreate records for next iteration
            for i in 0..<5000 {
                let scheduledTime = calendar.date(byAdding: .hour, value: i, to: startDate)!
                try! doseHistoryService.create(
                    for: schedule,
                    scheduledTime: scheduledTime
                )
            }
        }
    }

    // MARK: - Fetch Performance

    func testFetchSchedulesDuePerformance() throws {
        // Create 50 medications with 2 schedules each
        for i in 0..<50 {
            let medication = try medicationService.create(
                name: "Medication \(i)",
                dosageAmount: Double(i * 10),
                dosageUnit: "mg"
            )

            try scheduleService.create(for: medication, hour: 8, minute: 0)
            try scheduleService.create(for: medication, hour: 20, minute: 0)
        }

        // Measure fetching schedules due today
        let today = Date()

        measure {
            do {
                _ = try scheduleService.fetchSchedulesDue(on: today)
            } catch {
                XCTFail("Fetch failed: \(error)")
            }
        }
    }

    func testFetchActiveMedicationsPerformance() throws {
        // Create 500 medications (mix of active and inactive)
        for i in 0..<500 {
            let medication = try medicationService.create(
                name: "Medication \(i)",
                dosageAmount: Double(i * 10),
                dosageUnit: "mg"
            )

            if i % 3 == 0 {
                try medicationService.deactivate(medication)
            }
        }

        // Measure fetching active medications
        measure {
            do {
                _ = try medicationService.fetchActive()
            } catch {
                XCTFail("Fetch failed: \(error)")
            }
        }
    }

    func testSearchMedicationsPerformance() throws {
        // Create 1000 medications with varied names
        let prefixes = ["Asp", "Ibu", "Para", "Amox", "Lipitor", "Metform", "Omepraz"]

        for i in 0..<1000 {
            let prefix = prefixes[i % prefixes.count]
            try medicationService.create(
                name: "\(prefix)irin \(i)",
                dosageAmount: Double(i * 10),
                dosageUnit: "mg"
            )
        }

        // Measure search performance
        measure {
            do {
                _ = try medicationService.search("Asp")
            } catch {
                XCTFail("Search failed: \(error)")
            }
        }
    }

    // MARK: - DateFormatter Performance

    func testDateFormatterCachingPerformance() {
        let dates = (0..<1000).map { Date().addingTimeInterval(TimeInterval($0 * 3600)) }

        // Test WITHOUT caching (current implementation)
        measure(metrics: [XCTClockMetric()]) {
            for date in dates {
                // Simulates current implementation
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd-HHmm"
                _ = formatter.string(from: date)
            }
        }
    }

    func testDateFormatterCachedPerformance() {
        let dates = (0..<1000).map { Date().addingTimeInterval(TimeInterval($0 * 3600)) }

        // Test WITH caching (proposed implementation)
        let cachedFormatter = DateFormatter()
        cachedFormatter.dateFormat = "yyyyMMdd-HHmm"

        measure(metrics: [XCTClockMetric()]) {
            for date in dates {
                _ = cachedFormatter.string(from: date)
            }
        }
    }

    // MARK: - Adherence Calculation Performance

    func testAdherenceCalculationPerformance() throws {
        // Create medication and schedule
        let medication = try medicationService.create(
            name: "Test Med",
            dosageAmount: 500,
            dosageUnit: "mg"
        )

        let schedule = try scheduleService.create(
            for: medication,
            hour: 9,
            minute: 0
        )

        // Create 1000 dose history records
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -100, to: Date())!
        let endDate = Date()

        for i in 0..<1000 {
            let scheduledTime = calendar.date(byAdding: .hour, value: i, to: startDate)!
            let dose = try doseHistoryService.create(
                for: schedule,
                scheduledTime: scheduledTime
            )

            // Mark some as taken
            if i % 3 != 0 {
                try doseHistoryService.markAsTaken(dose)
            }
        }

        // Measure adherence calculation
        measure {
            do {
                _ = try doseHistoryService.calculateAdherence(from: startDate, to: endDate)
            } catch {
                XCTFail("Adherence calculation failed: \(error)")
            }
        }
    }

    // MARK: - Memory Performance

    func testMemoryUsageWithManyMedications() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            // Create and fetch 500 medications
            for i in 0..<500 {
                try! medicationService.create(
                    name: "Medication \(i)",
                    dosageAmount: Double(i * 10),
                    dosageUnit: "mg"
                )
            }

            _ = try! medicationService.fetchAll()

            // Clean up
            try! medicationService.deleteAll(includeActive: true)
        }
    }

    func testMemoryUsageWithManySchedules() throws {
        let medication = try medicationService.create(
            name: "Test Med",
            dosageAmount: 500,
            dosageUnit: "mg"
        )

        measure(metrics: [XCTMemoryMetric()]) {
            // Create and fetch 200 schedules
            for i in 0..<200 {
                try! scheduleService.create(
                    for: medication,
                    hour: i % 24,
                    minute: (i * 10) % 60
                )
            }

            _ = try! scheduleService.fetchSchedules(for: medication)

            // Clean up
            try! scheduleService.deleteSchedules(for: medication)
        }
    }
}
