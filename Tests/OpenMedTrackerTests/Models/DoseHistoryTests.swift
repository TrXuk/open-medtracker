//
//  DoseHistoryTests.swift
//  OpenMedTrackerTests
//
//  Unit tests for DoseHistory Core Data model
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class DoseHistoryTests: XCTestCase {

    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    var testSchedule: Schedule!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.viewContext

        let medication = Medication(context: context)
        medication.name = "Test Med"
        medication.dosageAmount = 10
        medication.dosageUnit = "mg"
        medication.startDate = Date()

        testSchedule = Schedule(context: context)
        testSchedule.medication = medication
        testSchedule.timeOfDay = Date()
    }

    override func tearDown() {
        testSchedule = nil
        context = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testDoseHistoryInitialization() {
        let doseHistory = DoseHistory(context: context)

        XCTAssertNotNil(doseHistory.id)
        XCTAssertNotNil(doseHistory.createdAt)
        XCTAssertEqual(doseHistory.status, "pending")
        XCTAssertNotNil(doseHistory.timezoneIdentifier)
    }

    // MARK: - Status Enum Tests

    func testStatusEnumValues() {
        let statuses = DoseHistory.Status.allCases
        XCTAssertEqual(statuses.count, 4)
        XCTAssertTrue(statuses.contains(.pending))
        XCTAssertTrue(statuses.contains(.taken))
        XCTAssertTrue(statuses.contains(.missed))
        XCTAssertTrue(statuses.contains(.skipped))
    }

    func testStatusDisplayNames() {
        XCTAssertEqual(DoseHistory.Status.pending.displayName, "Pending")
        XCTAssertEqual(DoseHistory.Status.taken.displayName, "Taken")
        XCTAssertEqual(DoseHistory.Status.missed.displayName, "Missed")
        XCTAssertEqual(DoseHistory.Status.skipped.displayName, "Skipped")
    }

    func testStatusEmojis() {
        XCTAssertEqual(DoseHistory.Status.pending.emoji, "⏳")
        XCTAssertEqual(DoseHistory.Status.taken.emoji, "✅")
        XCTAssertEqual(DoseHistory.Status.missed.emoji, "❌")
        XCTAssertEqual(DoseHistory.Status.skipped.emoji, "⏭️")
    }

    // MARK: - Computed Properties Tests

    func testStatusEnum_Getter() {
        let doseHistory = createTestDoseHistory()
        doseHistory.status = "taken"

        XCTAssertEqual(doseHistory.statusEnum, .taken)
    }

    func testStatusEnum_Setter() {
        let doseHistory = createTestDoseHistory()
        doseHistory.statusEnum = .missed

        XCTAssertEqual(doseHistory.status, "missed")
    }

    func testStatusEnum_InvalidValue() {
        let doseHistory = createTestDoseHistory()
        doseHistory.status = "invalid"

        XCTAssertEqual(doseHistory.statusEnum, .pending) // Default
    }

    func testWasTaken() {
        let doseHistory = createTestDoseHistory()

        doseHistory.statusEnum = .taken
        XCTAssertTrue(doseHistory.wasTaken)

        doseHistory.statusEnum = .missed
        XCTAssertFalse(doseHistory.wasTaken)
    }

    func testWasMissed() {
        let doseHistory = createTestDoseHistory()

        doseHistory.statusEnum = .missed
        XCTAssertTrue(doseHistory.wasMissed)

        doseHistory.statusEnum = .taken
        XCTAssertFalse(doseHistory.wasMissed)
    }

    func testIsPending() {
        let doseHistory = createTestDoseHistory()

        doseHistory.statusEnum = .pending
        XCTAssertTrue(doseHistory.isPending)

        doseHistory.statusEnum = .taken
        XCTAssertFalse(doseHistory.isPending)
    }

    func testIsOverdue() {
        let doseHistory = createTestDoseHistory()
        doseHistory.scheduledTime = Date().addingTimeInterval(-3600) // 1 hour ago
        doseHistory.statusEnum = .pending

        XCTAssertTrue(doseHistory.isOverdue)

        doseHistory.scheduledTime = Date().addingTimeInterval(3600) // 1 hour from now
        XCTAssertFalse(doseHistory.isOverdue)

        doseHistory.scheduledTime = Date().addingTimeInterval(-3600)
        doseHistory.statusEnum = .taken
        XCTAssertFalse(doseHistory.isOverdue)
    }

    func testTimeDifference() {
        let doseHistory = createTestDoseHistory()
        doseHistory.scheduledTime = Date()

        XCTAssertNil(doseHistory.timeDifference)

        doseHistory.actualTime = Date().addingTimeInterval(300) // 5 minutes later

        if let diff = doseHistory.timeDifference {
            XCTAssertGreaterThan(diff, 290)
            XCTAssertLessThan(diff, 310)
        } else {
            XCTFail("Time difference should not be nil")
        }
    }

    func testTimeDifferenceDescription() {
        let doseHistory = createTestDoseHistory()
        doseHistory.scheduledTime = Date()

        XCTAssertNil(doseHistory.timeDifferenceDescription)

        // 5 minutes late
        doseHistory.actualTime = Date().addingTimeInterval(300)
        if let description = doseHistory.timeDifferenceDescription {
            XCTAssertTrue(description.contains("5m") || description.contains("late"))
        }

        // 5 minutes early
        doseHistory.actualTime = Date().addingTimeInterval(-300)
        if let description = doseHistory.timeDifferenceDescription {
            XCTAssertTrue(description.contains("5m") || description.contains("early"))
        }

        // 2 hours 30 minutes late
        doseHistory.actualTime = Date().addingTimeInterval(9000)
        if let description = doseHistory.timeDifferenceDescription {
            XCTAssertTrue(description.contains("2h"))
        }
    }

    func testFormattedScheduledTime() {
        let doseHistory = createTestDoseHistory()
        doseHistory.scheduledTime = Date()

        let formatted = doseHistory.formattedScheduledTime
        XCTAssertFalse(formatted.isEmpty)
    }

    func testFormattedActualTime() {
        let doseHistory = createTestDoseHistory()

        XCTAssertNil(doseHistory.formattedActualTime)

        doseHistory.actualTime = Date()
        XCTAssertNotNil(doseHistory.formattedActualTime)
        XCTAssertFalse(doseHistory.formattedActualTime!.isEmpty)
    }

    func testMedicationName() {
        let doseHistory = createTestDoseHistory()
        XCTAssertEqual(doseHistory.medicationName, "Test Med")
    }

    // MARK: - Helper Methods Tests

    func testMarkAsTaken_Default() {
        let doseHistory = createTestDoseHistory()
        doseHistory.markAsTaken()

        XCTAssertEqual(doseHistory.statusEnum, .taken)
        XCTAssertNotNil(doseHistory.actualTime)
    }

    func testMarkAsTaken_WithTime() {
        let doseHistory = createTestDoseHistory()
        let customTime = Date().addingTimeInterval(-300)

        doseHistory.markAsTaken(at: customTime)

        XCTAssertEqual(doseHistory.statusEnum, .taken)
        XCTAssertEqual(doseHistory.actualTime, customTime)
    }

    func testMarkAsTaken_WithNotes() {
        let doseHistory = createTestDoseHistory()
        doseHistory.markAsTaken(notes: "Took with food")

        XCTAssertEqual(doseHistory.statusEnum, .taken)
        XCTAssertEqual(doseHistory.notes, "Took with food")
    }

    func testMarkAsMissed() {
        let doseHistory = createTestDoseHistory()
        doseHistory.markAsMissed(notes: "Forgot to take")

        XCTAssertEqual(doseHistory.statusEnum, .missed)
        XCTAssertEqual(doseHistory.notes, "Forgot to take")
    }

    func testMarkAsSkipped() {
        let doseHistory = createTestDoseHistory()
        doseHistory.markAsSkipped(notes: "Not feeling well")

        XCTAssertEqual(doseHistory.statusEnum, .skipped)
        XCTAssertEqual(doseHistory.notes, "Not feeling well")
    }

    func testResetToPending() {
        let doseHistory = createTestDoseHistory()
        doseHistory.statusEnum = .taken
        doseHistory.actualTime = Date()
        doseHistory.notes = "Test notes"

        doseHistory.resetToPending()

        XCTAssertEqual(doseHistory.statusEnum, .pending)
        XCTAssertNil(doseHistory.actualTime)
        XCTAssertNil(doseHistory.notes)
    }

    func testIsAffectedByTimezoneChange() {
        let doseHistory = createTestDoseHistory()

        XCTAssertFalse(doseHistory.isAffectedByTimezoneChange)

        let timezoneEvent = TimezoneEvent(context: context)
        timezoneEvent.previousTimezone = "America/New_York"
        timezoneEvent.newTimezone = "Europe/London"
        timezoneEvent.transitionTime = Date()

        doseHistory.timezoneEvent = timezoneEvent
        XCTAssertTrue(doseHistory.isAffectedByTimezoneChange)
    }

    func testTimezoneOffsetHours() {
        let doseHistory = createTestDoseHistory()
        doseHistory.timezoneIdentifier = "UTC"

        XCTAssertEqual(doseHistory.timezoneOffsetHours, 0)
    }

    // MARK: - Helper Methods

    private func createTestDoseHistory() -> DoseHistory {
        let doseHistory = DoseHistory(context: context)
        doseHistory.schedule = testSchedule
        doseHistory.scheduledTime = Date()
        return doseHistory
    }
}
