//
//  TimezoneEventValidationTests.swift
//  OpenMedTrackerTests
//
//  Validation tests for TimezoneEvent entity
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class TimezoneEventValidationTests: XCTestCase {

    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.viewContext
    }

    override func tearDown() {
        context = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Basic Validation Tests

    func testValidation_ValidTimezoneEvent() throws {
        let event = createValidEvent()

        XCTAssertNoThrow(try event.validate())
    }

    // MARK: - Previous Timezone Validation

    func testValidation_EmptyPreviousTimezone() {
        let event = createValidEvent()
        event.previousTimezone = ""

        XCTAssertThrowsError(try event.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .emptyField(let field) = validationError {
                XCTAssertEqual(field, "previousTimezone")
            } else {
                XCTFail("Expected emptyField error")
            }
        }
    }

    func testValidation_InvalidPreviousTimezone() {
        let event = createValidEvent()
        event.previousTimezone = "Invalid/Timezone"

        XCTAssertThrowsError(try event.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidValue(let field, _) = validationError {
                XCTAssertEqual(field, "previousTimezone")
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }

    func testValidation_ValidPreviousTimezones() throws {
        let validTimezones = ["UTC", "America/New_York", "Europe/London", "Asia/Tokyo", "Pacific/Auckland"]

        for timezone in validTimezones {
            let event = createValidEvent()
            event.previousTimezone = timezone

            XCTAssertNoThrow(try event.validate(), "Timezone '\(timezone)' should be valid")
        }
    }

    // MARK: - New Timezone Validation

    func testValidation_EmptyNewTimezone() {
        let event = createValidEvent()
        event.newTimezone = ""

        XCTAssertThrowsError(try event.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .emptyField(let field) = validationError {
                XCTAssertEqual(field, "newTimezone")
            } else {
                XCTFail("Expected emptyField error")
            }
        }
    }

    func testValidation_InvalidNewTimezone() {
        let event = createValidEvent()
        event.newTimezone = "Invalid/Timezone"

        XCTAssertThrowsError(try event.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidValue(let field, _) = validationError {
                XCTAssertEqual(field, "newTimezone")
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }

    // MARK: - Business Rules

    func testValidation_SameTimezones() {
        let event = createValidEvent()
        event.previousTimezone = "America/New_York"
        event.newTimezone = "America/New_York"

        XCTAssertThrowsError(try event.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .businessRuleViolation(_) = validationError {
                // Expected - timezones must be different
            } else {
                XCTFail("Expected businessRuleViolation error")
            }
        }
    }

    func testValidation_DifferentTimezones() throws {
        let event = createValidEvent()
        event.previousTimezone = "America/New_York"
        event.newTimezone = "Europe/London"

        XCTAssertNoThrow(try event.validate())
    }

    // MARK: - Transition Time Validation

    func testValidation_TransitionTimeTooFarInPast() {
        let event = createValidEvent()
        let calendar = Calendar.current
        event.transitionTime = calendar.date(byAdding: .year, value: -3, to: Date())!

        XCTAssertThrowsError(try event.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidDate(let field, _) = validationError {
                XCTAssertEqual(field, "transitionTime")
            } else {
                XCTFail("Expected invalidDate error")
            }
        }
    }

    func testValidation_TransitionTimeInFuture() {
        let event = createValidEvent()
        event.transitionTime = Date().addingTimeInterval(3600) // 1 hour in future

        XCTAssertThrowsError(try event.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidDate(let field, _) = validationError {
                XCTAssertEqual(field, "transitionTime")
            } else {
                XCTFail("Expected invalidDate error")
            }
        }
    }

    func testValidation_TransitionTimeWithin2Years() throws {
        let calendar = Calendar.current

        let event1 = createValidEvent()
        event1.transitionTime = calendar.date(byAdding: .year, value: -2, to: Date())!
        XCTAssertNoThrow(try event1.validate())

        let event2 = createValidEvent()
        event2.transitionTime = Date()
        XCTAssertNoThrow(try event2.validate())
    }

    // MARK: - Location Validation

    func testValidation_LocationNil() throws {
        let event = createValidEvent()
        event.location = nil

        XCTAssertNoThrow(try event.validate())
    }

    func testValidation_LocationEmpty() {
        let event = createValidEvent()
        event.location = ""

        XCTAssertThrowsError(try event.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidValue(let field, _) = validationError {
                XCTAssertEqual(field, "location")
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }

    func testValidation_LocationTooLong() {
        let event = createValidEvent()
        event.location = String(repeating: "A", count: 201)

        XCTAssertThrowsError(try event.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidValue(let field, _) = validationError {
                XCTAssertEqual(field, "location")
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }

    func testValidation_LocationMaxLength() throws {
        let event = createValidEvent()
        event.location = String(repeating: "A", count: 200)

        XCTAssertNoThrow(try event.validate())
    }

    func testValidation_LocationValid() throws {
        let event = createValidEvent()
        event.location = "New York, NY"

        XCTAssertNoThrow(try event.validate())
    }

    // MARK: - Notes Validation

    func testValidation_NotesNil() throws {
        let event = createValidEvent()
        event.notes = nil

        XCTAssertNoThrow(try event.validate())
    }

    func testValidation_NotesTooLong() {
        let event = createValidEvent()
        event.notes = String(repeating: "A", count: 1001)

        XCTAssertThrowsError(try event.validate()) { error in
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
        let event = createValidEvent()
        event.notes = String(repeating: "A", count: 1000)

        XCTAssertNoThrow(try event.validate())
    }

    // MARK: - Large Timezone Changes (Warning Test)

    func testValidation_LargeTimezoneChange() throws {
        // Test that large timezone changes don't fail validation,
        // but should log a warning (we can't test the print statement directly)
        let event = createValidEvent()
        event.previousTimezone = "Pacific/Fiji"       // UTC+12
        event.newTimezone = "Pacific/Midway"          // UTC-11

        // Should not throw error, just log warning
        XCTAssertNoThrow(try event.validate())
    }

    func testValidation_SmallTimezoneChange() throws {
        let event = createValidEvent()
        event.previousTimezone = "America/New_York"   // UTC-5
        event.newTimezone = "America/Chicago"         // UTC-6

        XCTAssertNoThrow(try event.validate())
    }

    // MARK: - Edge Cases

    func testValidation_UTCToUTC() {
        let event = createValidEvent()
        event.previousTimezone = "UTC"
        event.newTimezone = "UTC"

        // Should fail - same timezone
        XCTAssertThrowsError(try event.validate())
    }

    func testValidation_AliasedTimezones() {
        let event = createValidEvent()
        event.previousTimezone = "US/Eastern"
        event.newTimezone = "America/New_York"

        // These are the same timezone (aliases), should fail
        XCTAssertThrowsError(try event.validate())
    }

    func testValidation_DateLineCrossing() throws {
        let event = createValidEvent()
        event.previousTimezone = "Pacific/Auckland"   // UTC+12
        event.newTimezone = "America/Los_Angeles"     // UTC-8

        // Should be valid despite large offset
        XCTAssertNoThrow(try event.validate())
    }

    // MARK: - Core Data Integration Tests

    func testValidateForInsert() throws {
        let event = createValidEvent()

        XCTAssertNoThrow(try event.validateForInsert())
    }

    func testValidateForInsert_Invalid() {
        let event = createValidEvent()
        event.previousTimezone = ""

        XCTAssertThrowsError(try event.validateForInsert())
    }

    func testValidateForUpdate() throws {
        let event = createValidEvent()
        try context.save()

        event.location = "Updated Location"
        XCTAssertNoThrow(try event.validateForUpdate())
    }

    func testValidateForUpdate_Invalid() throws {
        let event = createValidEvent()
        try context.save()

        event.newTimezone = "Invalid/Timezone"
        XCTAssertThrowsError(try event.validateForUpdate())
    }

    // MARK: - Helper Methods

    private func createValidEvent() -> TimezoneEvent {
        let event = TimezoneEvent(context: context)
        event.previousTimezone = "America/New_York"
        event.newTimezone = "Europe/London"
        event.transitionTime = Date()
        return event
    }
}
