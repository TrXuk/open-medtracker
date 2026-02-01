//
//  ScheduleValidationTests.swift
//  OpenMedTrackerTests
//
//  Validation tests for Schedule entity
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class ScheduleValidationTests: XCTestCase {

    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    var testMedication: Medication!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.viewContext

        testMedication = Medication(context: context)
        testMedication.name = "Test Med"
        testMedication.dosageAmount = 10
        testMedication.dosageUnit = "mg"
        testMedication.startDate = Date()
        testMedication.isActive = true
    }

    override func tearDown() {
        testMedication = nil
        context = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Basic Validation Tests

    func testValidation_ValidSchedule() throws {
        let schedule = createValidSchedule()

        XCTAssertNoThrow(try schedule.validate())
    }

    // MARK: - Medication Relationship Validation

    func testValidation_NoMedication() {
        let schedule = Schedule(context: context)
        schedule.timeOfDay = Date()
        schedule.frequency = "daily"
        schedule.daysOfWeek = 127

        XCTAssertThrowsError(try schedule.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidRelationship(let field, _) = validationError {
                XCTAssertEqual(field, "medication")
            } else {
                XCTFail("Expected invalidRelationship error")
            }
        }
    }

    // MARK: - Frequency Validation

    func testValidation_ValidFrequencies() throws {
        let validFrequencies = ["daily", "weekly", "as-needed", "custom"]

        for frequency in validFrequencies {
            let schedule = createValidSchedule()
            schedule.frequency = frequency

            XCTAssertNoThrow(try schedule.validate(), "Frequency '\(frequency)' should be valid")
        }
    }

    func testValidation_InvalidFrequency() {
        let schedule = createValidSchedule()
        schedule.frequency = "invalid"

        XCTAssertThrowsError(try schedule.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidValue(let field, _) = validationError {
                XCTAssertEqual(field, "frequency")
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }

    func testValidation_FrequencyCaseInsensitive() throws {
        let schedule = createValidSchedule()
        schedule.frequency = "DAILY"

        XCTAssertNoThrow(try schedule.validate())
    }

    // MARK: - DaysOfWeek Validation

    func testValidation_DaysOfWeekNegative() {
        let schedule = createValidSchedule()
        schedule.daysOfWeek = -1

        XCTAssertThrowsError(try schedule.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidRange(let field, _, _) = validationError {
                XCTAssertEqual(field, "daysOfWeek")
            } else {
                XCTFail("Expected invalidRange error")
            }
        }
    }

    func testValidation_DaysOfWeekTooLarge() {
        let schedule = createValidSchedule()
        schedule.daysOfWeek = 128

        XCTAssertThrowsError(try schedule.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidRange(let field, _, _) = validationError {
                XCTAssertEqual(field, "daysOfWeek")
            } else {
                XCTFail("Expected invalidRange error")
            }
        }
    }

    func testValidation_DaysOfWeekZero() {
        let schedule = createValidSchedule()
        schedule.daysOfWeek = 0

        XCTAssertThrowsError(try schedule.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .businessRuleViolation(_) = validationError {
                // Expected - at least one day must be selected
            } else {
                XCTFail("Expected businessRuleViolation error")
            }
        }
    }

    func testValidation_DaysOfWeekMinValid() throws {
        let schedule = createValidSchedule()
        schedule.daysOfWeek = 1 // Only Sunday

        XCTAssertNoThrow(try schedule.validate())
    }

    func testValidation_DaysOfWeekMaxValid() throws {
        let schedule = createValidSchedule()
        schedule.daysOfWeek = 127 // All days

        XCTAssertNoThrow(try schedule.validate())
    }

    // MARK: - Time Validation

    func testValidation_ValidTimeOfDay() throws {
        let schedule = createValidSchedule()
        let calendar = Calendar.current
        let now = Date()

        schedule.timeOfDay = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: now)!

        XCTAssertNoThrow(try schedule.validate())
    }

    func testValidation_MidnightTime() throws {
        let schedule = createValidSchedule()
        let calendar = Calendar.current
        let now = Date()

        schedule.timeOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now)!

        XCTAssertNoThrow(try schedule.validate())
    }

    func testValidation_EndOfDayTime() throws {
        let schedule = createValidSchedule()
        let calendar = Calendar.current
        let now = Date()

        schedule.timeOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!

        XCTAssertNoThrow(try schedule.validate())
    }

    // MARK: - Business Rule Validation

    func testValidation_EnabledScheduleWithInactiveMedication() {
        let schedule = createValidSchedule()
        schedule.isEnabled = true
        testMedication.isActive = false

        XCTAssertThrowsError(try schedule.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .businessRuleViolation(_) = validationError {
                // Expected - cannot enable schedule for inactive medication
            } else {
                XCTFail("Expected businessRuleViolation error")
            }
        }
    }

    func testValidation_DisabledScheduleWithInactiveMedication() throws {
        let schedule = createValidSchedule()
        schedule.isEnabled = false
        testMedication.isActive = false

        XCTAssertNoThrow(try schedule.validate())
    }

    func testValidation_EnabledScheduleWithActiveMedication() throws {
        let schedule = createValidSchedule()
        schedule.isEnabled = true
        testMedication.isActive = true

        XCTAssertNoThrow(try schedule.validate())
    }

    // MARK: - Core Data Integration Tests

    func testValidateForInsert() throws {
        let schedule = createValidSchedule()

        XCTAssertNoThrow(try schedule.validateForInsert())
    }

    func testValidateForInsert_Invalid() {
        let schedule = createValidSchedule()
        schedule.frequency = "invalid"

        XCTAssertThrowsError(try schedule.validateForInsert())
    }

    func testValidateForUpdate() throws {
        let schedule = createValidSchedule()
        try context.save()

        schedule.daysOfWeek = 62 // Weekdays
        XCTAssertNoThrow(try schedule.validateForUpdate())
    }

    func testValidateForUpdate_Invalid() throws {
        let schedule = createValidSchedule()
        try context.save()

        schedule.daysOfWeek = 0
        XCTAssertThrowsError(try schedule.validateForUpdate())
    }

    // MARK: - Helper Methods

    private func createValidSchedule() -> Schedule {
        let schedule = Schedule(context: context)
        schedule.medication = testMedication
        schedule.timeOfDay = Date()
        schedule.frequency = "daily"
        schedule.daysOfWeek = 127
        schedule.isEnabled = true
        return schedule
    }
}
