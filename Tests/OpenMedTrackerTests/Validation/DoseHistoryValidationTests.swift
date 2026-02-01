//
//  DoseHistoryValidationTests.swift
//  OpenMedTrackerTests
//
//  Validation tests for DoseHistory entity
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class DoseHistoryValidationTests: XCTestCase {

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

    // MARK: - Basic Validation Tests

    func testValidation_ValidDoseHistory() throws {
        let doseHistory = createValidDoseHistory()

        XCTAssertNoThrow(try doseHistory.validate())
    }

    // MARK: - Schedule Relationship Validation

    func testValidation_NoSchedule() {
        let doseHistory = DoseHistory(context: context)
        doseHistory.scheduledTime = Date()
        doseHistory.status = "pending"
        doseHistory.timezoneIdentifier = "UTC"

        XCTAssertThrowsError(try doseHistory.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidRelationship(let field, _) = validationError {
                XCTAssertEqual(field, "schedule")
            } else {
                XCTFail("Expected invalidRelationship error")
            }
        }
    }

    // MARK: - Status Validation

    func testValidation_ValidStatuses() throws {
        let validStatuses = ["pending", "taken", "missed", "skipped"]

        for status in validStatuses {
            let doseHistory = createValidDoseHistory()
            doseHistory.status = status

            if status == "taken" {
                doseHistory.actualTime = Date()
            } else {
                doseHistory.actualTime = nil
            }

            XCTAssertNoThrow(try doseHistory.validate(), "Status '\(status)' should be valid")
        }
    }

    func testValidation_InvalidStatus() {
        let doseHistory = createValidDoseHistory()
        doseHistory.status = "invalid"

        XCTAssertThrowsError(try doseHistory.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidValue(let field, _) = validationError {
                XCTAssertEqual(field, "status")
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }

    // MARK: - Timezone Validation

    func testValidation_EmptyTimezone() {
        let doseHistory = createValidDoseHistory()
        doseHistory.timezoneIdentifier = ""

        XCTAssertThrowsError(try doseHistory.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .emptyField(let field) = validationError {
                XCTAssertEqual(field, "timezoneIdentifier")
            } else {
                XCTFail("Expected emptyField error")
            }
        }
    }

    func testValidation_InvalidTimezone() {
        let doseHistory = createValidDoseHistory()
        doseHistory.timezoneIdentifier = "Invalid/Timezone"

        XCTAssertThrowsError(try doseHistory.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidValue(let field, _) = validationError {
                XCTAssertEqual(field, "timezoneIdentifier")
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }

    func testValidation_ValidTimezones() throws {
        let validTimezones = ["UTC", "America/New_York", "Europe/London", "Asia/Tokyo"]

        for timezone in validTimezones {
            let doseHistory = createValidDoseHistory()
            doseHistory.timezoneIdentifier = timezone

            XCTAssertNoThrow(try doseHistory.validate(), "Timezone '\(timezone)' should be valid")
        }
    }

    // MARK: - Actual Time Business Rules

    func testValidation_ActualTimeWithTakenStatus() throws {
        let doseHistory = createValidDoseHistory()
        doseHistory.statusEnum = .taken
        doseHistory.actualTime = Date()

        XCTAssertNoThrow(try doseHistory.validate())
    }

    func testValidation_ActualTimeWithNonTakenStatus() {
        let doseHistory = createValidDoseHistory()
        doseHistory.statusEnum = .missed
        doseHistory.actualTime = Date()

        XCTAssertThrowsError(try doseHistory.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .businessRuleViolation(_) = validationError {
                // Expected
            } else {
                XCTFail("Expected businessRuleViolation error")
            }
        }
    }

    func testValidation_ActualTimeInFuture() {
        let doseHistory = createValidDoseHistory()
        doseHistory.statusEnum = .taken
        doseHistory.actualTime = Date().addingTimeInterval(7200) // 2 hours in future

        XCTAssertThrowsError(try doseHistory.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .businessRuleViolation(_) = validationError {
                // Expected
            } else {
                XCTFail("Expected businessRuleViolation error")
            }
        }
    }

    func testValidation_ActualTimeWithinOneHourFuture() throws {
        let doseHistory = createValidDoseHistory()
        doseHistory.statusEnum = .taken
        doseHistory.actualTime = Date().addingTimeInterval(1800) // 30 minutes in future

        XCTAssertNoThrow(try doseHistory.validate())
    }

    func testValidation_ActualTimeTooEarly() {
        let doseHistory = createValidDoseHistory()
        doseHistory.statusEnum = .taken
        doseHistory.scheduledTime = Date()
        doseHistory.actualTime = Date().addingTimeInterval(-8 * 24 * 60 * 60) // 8 days before

        XCTAssertThrowsError(try doseHistory.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .businessRuleViolation(_) = validationError {
                // Expected
            } else {
                XCTFail("Expected businessRuleViolation error")
            }
        }
    }

    func testValidation_ActualTimeWithinOneWeekBefore() throws {
        let doseHistory = createValidDoseHistory()
        doseHistory.statusEnum = .taken
        doseHistory.scheduledTime = Date()
        doseHistory.actualTime = Date().addingTimeInterval(-6 * 24 * 60 * 60) // 6 days before

        XCTAssertNoThrow(try doseHistory.validate())
    }

    func testValidation_PendingStatusWithActualTime() {
        let doseHistory = createValidDoseHistory()
        doseHistory.statusEnum = .pending
        doseHistory.actualTime = Date()

        XCTAssertThrowsError(try doseHistory.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .businessRuleViolation(_) = validationError {
                // Expected
            } else {
                XCTFail("Expected businessRuleViolation error")
            }
        }
    }

    func testValidation_PendingStatusWithoutActualTime() throws {
        let doseHistory = createValidDoseHistory()
        doseHistory.statusEnum = .pending
        doseHistory.actualTime = nil

        XCTAssertNoThrow(try doseHistory.validate())
    }

    // MARK: - Notes Validation

    func testValidation_NotesNil() throws {
        let doseHistory = createValidDoseHistory()
        doseHistory.notes = nil

        XCTAssertNoThrow(try doseHistory.validate())
    }

    func testValidation_NotesTooLong() {
        let doseHistory = createValidDoseHistory()
        doseHistory.notes = String(repeating: "A", count: 1001)

        XCTAssertThrowsError(try doseHistory.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidValue(let field, _) = validationError {
                XCTAssertEqual(field, "notes")
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }

    func testValidation_NotesMaxLength() throws {
        let doseHistory = createValidDoseHistory()
        doseHistory.notes = String(repeating: "A", count: 1000)

        XCTAssertNoThrow(try doseHistory.validate())
    }

    // MARK: - Scheduled Time Validation

    func testValidation_ScheduledTimeTooFarInPast() {
        let doseHistory = createValidDoseHistory()
        let calendar = Calendar.current
        doseHistory.scheduledTime = calendar.date(byAdding: .year, value: -3, to: Date())!

        XCTAssertThrowsError(try doseHistory.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidDate(let field, _) = validationError {
                XCTAssertEqual(field, "scheduledTime")
            } else {
                XCTFail("Expected invalidDate error")
            }
        }
    }

    func testValidation_ScheduledTimeTooFarInFuture() {
        let doseHistory = createValidDoseHistory()
        let calendar = Calendar.current
        doseHistory.scheduledTime = calendar.date(byAdding: .year, value: 3, to: Date())!

        XCTAssertThrowsError(try doseHistory.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidDate(let field, _) = validationError {
                XCTAssertEqual(field, "scheduledTime")
            } else {
                XCTFail("Expected invalidDate error")
            }
        }
    }

    func testValidation_ScheduledTimeWithin2Years() throws {
        let calendar = Calendar.current

        let doseHistory1 = createValidDoseHistory()
        doseHistory1.scheduledTime = calendar.date(byAdding: .year, value: -2, to: Date())!
        XCTAssertNoThrow(try doseHistory1.validate())

        let doseHistory2 = createValidDoseHistory()
        doseHistory2.scheduledTime = calendar.date(byAdding: .year, value: 2, to: Date())!
        XCTAssertNoThrow(try doseHistory2.validate())
    }

    // MARK: - Core Data Integration Tests

    func testValidateForInsert() throws {
        let doseHistory = createValidDoseHistory()

        XCTAssertNoThrow(try doseHistory.validateForInsert())
    }

    func testValidateForInsert_Invalid() {
        let doseHistory = createValidDoseHistory()
        doseHistory.status = "invalid"

        XCTAssertThrowsError(try doseHistory.validateForInsert())
    }

    func testValidateForUpdate() throws {
        let doseHistory = createValidDoseHistory()
        try context.save()

        doseHistory.statusEnum = .taken
        doseHistory.actualTime = Date()
        XCTAssertNoThrow(try doseHistory.validateForUpdate())
    }

    func testValidateForUpdate_Invalid() throws {
        let doseHistory = createValidDoseHistory()
        try context.save()

        doseHistory.timezoneIdentifier = "Invalid/Timezone"
        XCTAssertThrowsError(try doseHistory.validateForUpdate())
    }

    // MARK: - Helper Methods

    private func createValidDoseHistory() -> DoseHistory {
        let doseHistory = DoseHistory(context: context)
        doseHistory.schedule = testSchedule
        doseHistory.scheduledTime = Date()
        doseHistory.status = "pending"
        doseHistory.timezoneIdentifier = "UTC"
        return doseHistory
    }
}
