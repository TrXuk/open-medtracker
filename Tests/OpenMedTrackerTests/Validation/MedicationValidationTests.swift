//
//  MedicationValidationTests.swift
//  OpenMedTrackerTests
//
//  Validation tests for Medication entity
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class MedicationValidationTests: XCTestCase {

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

    // MARK: - Name Validation Tests

    func testValidation_ValidMedication() throws {
        let medication = createValidMedication()

        XCTAssertNoThrow(try medication.validate())
    }

    func testValidation_EmptyName() {
        let medication = createValidMedication()
        medication.name = ""

        XCTAssertThrowsError(try medication.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .emptyField(let field) = validationError {
                XCTAssertEqual(field, "name")
            } else {
                XCTFail("Expected emptyField error")
            }
        }
    }

    func testValidation_WhitespaceName() {
        let medication = createValidMedication()
        medication.name = "   "

        XCTAssertThrowsError(try medication.validate()) { error in
            XCTAssertTrue(error is ValidationError)
        }
    }

    func testValidation_NameTooLong() {
        let medication = createValidMedication()
        medication.name = String(repeating: "A", count: 201)

        XCTAssertThrowsError(try medication.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidValue(let field, _) = validationError {
                XCTAssertEqual(field, "name")
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }

    func testValidation_NameMaxLength() throws {
        let medication = createValidMedication()
        medication.name = String(repeating: "A", count: 200)

        XCTAssertNoThrow(try medication.validate())
    }

    // MARK: - Dosage Amount Validation Tests

    func testValidation_ZeroDosageAmount() {
        let medication = createValidMedication()
        medication.dosageAmount = 0

        XCTAssertThrowsError(try medication.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidRange(let field, _, _) = validationError {
                XCTAssertEqual(field, "dosageAmount")
            } else {
                XCTFail("Expected invalidRange error")
            }
        }
    }

    func testValidation_NegativeDosageAmount() {
        let medication = createValidMedication()
        medication.dosageAmount = -10

        XCTAssertThrowsError(try medication.validate())
    }

    func testValidation_DosageAmountTooLarge() {
        let medication = createValidMedication()
        medication.dosageAmount = 100001

        XCTAssertThrowsError(try medication.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidRange(let field, _, _) = validationError {
                XCTAssertEqual(field, "dosageAmount")
            } else {
                XCTFail("Expected invalidRange error")
            }
        }
    }

    func testValidation_DosageAmountMaxValue() throws {
        let medication = createValidMedication()
        medication.dosageAmount = 100000

        XCTAssertNoThrow(try medication.validate())
    }

    func testValidation_DosageAmountMinValue() throws {
        let medication = createValidMedication()
        medication.dosageAmount = 0.001

        XCTAssertNoThrow(try medication.validate())
    }

    // MARK: - Dosage Unit Validation Tests

    func testValidation_EmptyDosageUnit() {
        let medication = createValidMedication()
        medication.dosageUnit = ""

        XCTAssertThrowsError(try medication.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .emptyField(let field) = validationError {
                XCTAssertEqual(field, "dosageUnit")
            } else {
                XCTFail("Expected emptyField error")
            }
        }
    }

    func testValidation_DosageUnitTooLong() {
        let medication = createValidMedication()
        medication.dosageUnit = String(repeating: "A", count: 51)

        XCTAssertThrowsError(try medication.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidValue(let field, _) = validationError {
                XCTAssertEqual(field, "dosageUnit")
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }

    func testValidation_DosageUnitMaxLength() throws {
        let medication = createValidMedication()
        medication.dosageUnit = String(repeating: "A", count: 50)

        XCTAssertNoThrow(try medication.validate())
    }

    // MARK: - Date Validation Tests

    func testValidation_EndDateBeforeStartDate() {
        let medication = createValidMedication()
        medication.startDate = Date()
        medication.endDate = Date().addingTimeInterval(-86400) // Yesterday

        XCTAssertThrowsError(try medication.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidDate(let field, _) = validationError {
                XCTAssertEqual(field, "endDate")
            } else {
                XCTFail("Expected invalidDate error")
            }
        }
    }

    func testValidation_EndDateEqualToStartDate() throws {
        let medication = createValidMedication()
        let now = Date()
        medication.startDate = now
        medication.endDate = now

        XCTAssertNoThrow(try medication.validate())
    }

    func testValidation_EndDateAfterStartDate() throws {
        let medication = createValidMedication()
        medication.startDate = Date()
        medication.endDate = Date().addingTimeInterval(86400)

        XCTAssertNoThrow(try medication.validate())
    }

    func testValidation_StartDateTooFarInFuture() {
        let medication = createValidMedication()
        let calendar = Calendar.current
        medication.startDate = calendar.date(byAdding: .year, value: 6, to: Date())!

        XCTAssertThrowsError(try medication.validate()) { error in
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

    func testValidation_StartDate5YearsInFuture() throws {
        let medication = createValidMedication()
        let calendar = Calendar.current
        medication.startDate = calendar.date(byAdding: .year, value: 5, to: Date())!

        XCTAssertNoThrow(try medication.validate())
    }

    // MARK: - Instructions Validation Tests

    func testValidation_InstructionsNil() throws {
        let medication = createValidMedication()
        medication.instructions = nil

        XCTAssertNoThrow(try medication.validate())
    }

    func testValidation_InstructionsTooLong() {
        let medication = createValidMedication()
        medication.instructions = String(repeating: "A", count: 1001)

        XCTAssertThrowsError(try medication.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidValue(let field, _) = validationError {
                XCTAssertEqual(field, "instructions")
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }

    func testValidation_InstructionsMaxLength() throws {
        let medication = createValidMedication()
        medication.instructions = String(repeating: "A", count: 1000)

        XCTAssertNoThrow(try medication.validate())
    }

    // MARK: - PrescribedBy Validation Tests

    func testValidation_PrescribedByNil() throws {
        let medication = createValidMedication()
        medication.prescribedBy = nil

        XCTAssertNoThrow(try medication.validate())
    }

    func testValidation_PrescribedByTooLong() {
        let medication = createValidMedication()
        medication.prescribedBy = String(repeating: "A", count: 201)

        XCTAssertThrowsError(try medication.validate()) { error in
            guard let validationError = error as? ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }

            if case .invalidValue(let field, _) = validationError {
                XCTAssertEqual(field, "prescribedBy")
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }

    func testValidation_PrescribedByMaxLength() throws {
        let medication = createValidMedication()
        medication.prescribedBy = String(repeating: "A", count: 200)

        XCTAssertNoThrow(try medication.validate())
    }

    // MARK: - Core Data Integration Tests

    func testValidateForInsert() throws {
        let medication = createValidMedication()

        XCTAssertNoThrow(try medication.validateForInsert())
    }

    func testValidateForInsert_Invalid() {
        let medication = createValidMedication()
        medication.name = ""

        XCTAssertThrowsError(try medication.validateForInsert())
    }

    func testValidateForUpdate() throws {
        let medication = createValidMedication()
        try context.save()

        medication.name = "Updated Name"
        XCTAssertNoThrow(try medication.validateForUpdate())
    }

    func testValidateForUpdate_Invalid() throws {
        let medication = createValidMedication()
        try context.save()

        medication.dosageAmount = -10
        XCTAssertThrowsError(try medication.validateForUpdate())
    }

    // MARK: - Helper Methods

    private func createValidMedication() -> Medication {
        let medication = Medication(context: context)
        medication.name = "Test Medication"
        medication.dosageAmount = 500
        medication.dosageUnit = "mg"
        medication.startDate = Date()
        return medication
    }
}
