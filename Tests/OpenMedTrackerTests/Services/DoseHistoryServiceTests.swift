//
//  DoseHistoryServiceTests.swift
//  OpenMedTrackerTests
//
//  Integration tests for DoseHistoryService CRUD operations
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class DoseHistoryServiceTests: XCTestCase {

    var persistenceController: PersistenceController!
    var service: DoseHistoryService!
    var testSchedule: Schedule!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        service = DoseHistoryService(persistenceController: persistenceController)

        let medication = Medication(context: persistenceController.viewContext)
        medication.name = "Test Med"
        medication.dosageAmount = 10
        medication.dosageUnit = "mg"
        medication.startDate = Date()

        testSchedule = Schedule(context: persistenceController.viewContext)
        testSchedule.medication = medication
        testSchedule.timeOfDay = Date()

        try! persistenceController.saveViewContext()
    }

    override func tearDown() {
        testSchedule = nil
        service = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Create Tests

    func testCreate_Success() throws {
        let scheduledTime = Date()

        let doseHistory = try service.create(
            for: testSchedule,
            scheduledTime: scheduledTime
        )

        XCTAssertEqual(doseHistory.schedule, testSchedule)
        XCTAssertEqual(doseHistory.scheduledTime, scheduledTime)
        XCTAssertEqual(doseHistory.statusEnum, .pending)
        XCTAssertNotNil(doseHistory.id)
    }

    func testCreate_WithCustomStatus() throws {
        let doseHistory = try service.create(
            for: testSchedule,
            scheduledTime: Date(),
            status: .taken,
            timezoneIdentifier: "America/New_York"
        )

        XCTAssertEqual(doseHistory.statusEnum, .taken)
        XCTAssertEqual(doseHistory.timezoneIdentifier, "America/New_York")
    }

    func testCreateDosesForDate_Success() throws {
        let scheduleService = ScheduleService(persistenceController: persistenceController)

        let medication = try! MedicationService(persistenceController: persistenceController)
            .create(name: "Med 1", dosageAmount: 10, dosageUnit: "mg")

        try! scheduleService.create(for: medication, hour: 9, minute: 0, daysOfWeek: 127)
        try! scheduleService.create(for: medication, hour: 21, minute: 0, daysOfWeek: 127)

        let doses = try service.createDosesForDate(Date())

        XCTAssertEqual(doses.count, 2)
        XCTAssertTrue(doses.allSatisfy { $0.statusEnum == .pending })
    }

    func testCreateDosesForDate_NoSchedules() throws {
        let doses = try service.createDosesForDate(Date())

        XCTAssertEqual(doses.count, 0)
    }

    // MARK: - Read Tests

    func testFetchAll_Empty() throws {
        let doseHistories = try service.fetchAll()

        XCTAssertEqual(doseHistories.count, 0)
    }

    func testFetchAll_Multiple() throws {
        try service.create(for: testSchedule, scheduledTime: Date().addingTimeInterval(-3600))
        try service.create(for: testSchedule, scheduledTime: Date())
        try service.create(for: testSchedule, scheduledTime: Date().addingTimeInterval(3600))

        let doseHistories = try service.fetchAll()

        XCTAssertEqual(doseHistories.count, 3)
    }

    func testFetchAll_SortedByScheduledTime() throws {
        let now = Date()
        try service.create(for: testSchedule, scheduledTime: now)
        try service.create(for: testSchedule, scheduledTime: now.addingTimeInterval(-3600))
        try service.create(for: testSchedule, scheduledTime: now.addingTimeInterval(3600))

        let doseHistories = try service.fetchAll()

        // Should be sorted descending (most recent first)
        XCTAssertGreaterThan(doseHistories[0].scheduledTime, doseHistories[1].scheduledTime)
        XCTAssertGreaterThan(doseHistories[1].scheduledTime, doseHistories[2].scheduledTime)
    }

    func testFetch_ByID() throws {
        let created = try service.create(for: testSchedule, scheduledTime: Date())

        let fetched = try service.fetch(id: created.id)

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, created.id)
    }

    func testFetchHistory_ForSchedule() throws {
        let medication = Medication(context: persistenceController.viewContext)
        medication.name = "Med 2"
        medication.dosageAmount = 20
        medication.dosageUnit = "mg"
        medication.startDate = Date()

        let schedule2 = Schedule(context: persistenceController.viewContext)
        schedule2.medication = medication
        schedule2.timeOfDay = Date()

        try service.create(for: testSchedule, scheduledTime: Date())
        try service.create(for: testSchedule, scheduledTime: Date().addingTimeInterval(3600))
        try service.create(for: schedule2, scheduledTime: Date())

        let history = try service.fetchHistory(for: testSchedule)

        XCTAssertEqual(history.count, 2)
        XCTAssertTrue(history.allSatisfy { $0.schedule == testSchedule })
    }

    func testFetchDoses_WithStatus() throws {
        let pending = try service.create(for: testSchedule, scheduledTime: Date(), status: .pending)
        let taken = try service.create(for: testSchedule, scheduledTime: Date(), status: .taken)
        try service.markAsTaken(taken)

        let pendingDoses = try service.fetchDoses(withStatus: .pending)

        XCTAssertEqual(pendingDoses.count, 1)
        XCTAssertEqual(pendingDoses.first?.id, pending.id)
    }

    func testFetchDoses_DateRange() throws {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let tomorrow = now.addingTimeInterval(86400)
        let nextWeek = now.addingTimeInterval(7 * 86400)

        try service.create(for: testSchedule, scheduledTime: yesterday)
        try service.create(for: testSchedule, scheduledTime: now)
        try service.create(for: testSchedule, scheduledTime: tomorrow)
        try service.create(for: testSchedule, scheduledTime: nextWeek)

        let doses = try service.fetchDoses(from: yesterday, to: tomorrow)

        XCTAssertEqual(doses.count, 3)
    }

    func testFetchOverdueDoses() throws {
        let now = Date()

        // Overdue and pending
        try service.create(
            for: testSchedule,
            scheduledTime: now.addingTimeInterval(-3600),
            status: .pending
        )

        // Future and pending (not overdue)
        try service.create(
            for: testSchedule,
            scheduledTime: now.addingTimeInterval(3600),
            status: .pending
        )

        // Past but taken (not overdue)
        let taken = try service.create(
            for: testSchedule,
            scheduledTime: now.addingTimeInterval(-7200),
            status: .taken
        )
        try service.markAsTaken(taken)

        let overdueDoses = try service.fetchOverdueDoses()

        XCTAssertEqual(overdueDoses.count, 1)
    }

    // MARK: - Update Tests

    func testUpdate_Status() throws {
        let doseHistory = try service.create(for: testSchedule, scheduledTime: Date())

        try service.update(doseHistory, status: .taken)

        XCTAssertEqual(doseHistory.statusEnum, .taken)
    }

    func testUpdate_Notes() throws {
        let doseHistory = try service.create(for: testSchedule, scheduledTime: Date())

        try service.update(doseHistory, notes: "Took with breakfast")

        XCTAssertEqual(doseHistory.notes, "Took with breakfast")
    }

    func testMarkAsTaken_Default() throws {
        let doseHistory = try service.create(for: testSchedule, scheduledTime: Date())

        try service.markAsTaken(doseHistory)

        XCTAssertEqual(doseHistory.statusEnum, .taken)
        XCTAssertNotNil(doseHistory.actualTime)
    }

    func testMarkAsTaken_CustomTime() throws {
        let doseHistory = try service.create(for: testSchedule, scheduledTime: Date())
        let customTime = Date().addingTimeInterval(-300)

        try service.markAsTaken(doseHistory, at: customTime)

        XCTAssertEqual(doseHistory.actualTime, customTime)
    }

    func testMarkAsTaken_WithNotes() throws {
        let doseHistory = try service.create(for: testSchedule, scheduledTime: Date())

        try service.markAsTaken(doseHistory, notes: "Took with food")

        XCTAssertEqual(doseHistory.notes, "Took with food")
    }

    func testMarkAsMissed() throws {
        let doseHistory = try service.create(for: testSchedule, scheduledTime: Date())

        try service.markAsMissed(doseHistory, notes: "Forgot")

        XCTAssertEqual(doseHistory.statusEnum, .missed)
        XCTAssertEqual(doseHistory.notes, "Forgot")
    }

    func testMarkAsSkipped() throws {
        let doseHistory = try service.create(for: testSchedule, scheduledTime: Date())

        try service.markAsSkipped(doseHistory, notes: "Not feeling well")

        XCTAssertEqual(doseHistory.statusEnum, .skipped)
        XCTAssertEqual(doseHistory.notes, "Not feeling well")
    }

    // MARK: - Delete Tests

    func testDelete_Success() throws {
        let doseHistory = try service.create(for: testSchedule, scheduledTime: Date())
        let id = doseHistory.id

        try service.delete(doseHistory)

        let fetched = try service.fetch(id: id)
        XCTAssertNil(fetched)
    }

    func testDeleteHistory_OlderThan() throws {
        let now = Date()
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: now)!

        try service.create(for: testSchedule, scheduledTime: twoMonthsAgo)
        try service.create(for: testSchedule, scheduledTime: oneMonthAgo)
        try service.create(for: testSchedule, scheduledTime: now)

        try service.deleteHistory(olderThan: oneMonthAgo)

        let remaining = try service.fetchAll()
        XCTAssertEqual(remaining.count, 2)
    }

    // MARK: - Statistics Tests

    func testCalculateAdherence_Perfect() throws {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let endDate = now

        // Create 5 taken doses
        for i in 0..<5 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: now)!
            let dose = try service.create(for: testSchedule, scheduledTime: date, status: .taken)
            try service.markAsTaken(dose)
        }

        let adherence = try service.calculateAdherence(from: startDate, to: endDate)

        XCTAssertEqual(adherence, 1.0)
    }

    func testCalculateAdherence_Partial() throws {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let endDate = now

        // Create 2 taken doses
        for i in 0..<2 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: now)!
            let dose = try service.create(for: testSchedule, scheduledTime: date, status: .taken)
            try service.markAsTaken(dose)
        }

        // Create 3 missed doses
        for i in 2..<5 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: now)!
            try service.create(for: testSchedule, scheduledTime: date, status: .missed)
        }

        let adherence = try service.calculateAdherence(from: startDate, to: endDate)

        XCTAssertEqual(adherence, 0.4, accuracy: 0.01)
    }

    func testCalculateAdherence_NoDoses() throws {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let endDate = now

        let adherence = try service.calculateAdherence(from: startDate, to: endDate)

        XCTAssertEqual(adherence, 0.0)
    }

    func testCount_WithStatus() throws {
        try service.create(for: testSchedule, scheduledTime: Date(), status: .pending)
        try service.create(for: testSchedule, scheduledTime: Date(), status: .pending)
        let taken = try service.create(for: testSchedule, scheduledTime: Date(), status: .taken)
        try service.markAsTaken(taken)

        let pendingCount = try service.count(withStatus: .pending)
        let takenCount = try service.count(withStatus: .taken)

        XCTAssertEqual(pendingCount, 2)
        XCTAssertEqual(takenCount, 1)
    }

    // MARK: - Edge Cases

    func testCreate_WithDifferentTimezones() throws {
        let timezones = ["UTC", "America/New_York", "Europe/London", "Asia/Tokyo"]

        for timezone in timezones {
            let dose = try service.create(
                for: testSchedule,
                scheduledTime: Date(),
                timezoneIdentifier: timezone
            )

            XCTAssertEqual(dose.timezoneIdentifier, timezone)
        }
    }

    func testMarkAsTaken_VeryEarly() throws {
        let doseHistory = try service.create(for: testSchedule, scheduledTime: Date())
        let veryEarly = Date().addingTimeInterval(-6 * 24 * 60 * 60) // 6 days before

        try service.markAsTaken(doseHistory, at: veryEarly)

        XCTAssertEqual(doseHistory.actualTime, veryEarly)
    }

    func testFetchOverdueDoses_LargeDataset() throws {
        // Create 100 overdue doses
        for i in 0..<100 {
            try service.create(
                for: testSchedule,
                scheduledTime: Date().addingTimeInterval(Double(-i * 3600)),
                status: .pending
            )
        }

        let overdueDoses = try service.fetchOverdueDoses()

        XCTAssertEqual(overdueDoses.count, 100)
    }

    func testCalculateAdherence_LongTimeRange() throws {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: now)!

        // Create doses throughout the year
        for month in 0..<12 {
            let date = Calendar.current.date(byAdding: .month, value: -month, to: now)!
            let dose = try service.create(for: testSchedule, scheduledTime: date, status: .taken)
            try service.markAsTaken(dose)
        }

        let adherence = try service.calculateAdherence(from: startDate, to: now)

        XCTAssertEqual(adherence, 1.0)
    }

    // MARK: - Concurrency Tests

    func testConcurrentStatusUpdates() throws {
        let doses = try (0..<10).map { _ in
            try service.create(for: testSchedule, scheduledTime: Date())
        }

        let expectation = self.expectation(description: "Concurrent updates")
        expectation.expectedFulfillmentCount = 10

        let backgroundContext = persistenceController.newBackgroundContext()

        for dose in doses {
            backgroundContext.perform {
                do {
                    guard let bgDose = try backgroundContext.existingObject(with: dose.objectID) as? DoseHistory else {
                        XCTFail("Failed to fetch dose in background context")
                        return
                    }

                    try self.service.markAsTaken(bgDose)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to update dose: \(error)")
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)

        let updated = try service.fetchDoses(withStatus: .taken)
        XCTAssertEqual(updated.count, 10)
    }
}
