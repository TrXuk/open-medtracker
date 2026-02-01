//
//  MedicationServiceTests.swift
//  OpenMedTrackerTests
//
//  Integration tests for MedicationService CRUD operations
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class MedicationServiceTests: XCTestCase {

    var persistenceController: PersistenceController!
    var service: MedicationService!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        service = MedicationService(persistenceController: persistenceController)
    }

    override func tearDown() {
        service = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Create Tests

    func testCreate_Success() throws {
        let medication = try service.create(
            name: "Aspirin",
            dosageAmount: 500,
            dosageUnit: "mg"
        )

        XCTAssertEqual(medication.name, "Aspirin")
        XCTAssertEqual(medication.dosageAmount, 500)
        XCTAssertEqual(medication.dosageUnit, "mg")
        XCTAssertTrue(medication.isActive)
        XCTAssertNotNil(medication.id)
    }

    func testCreate_WithAllParameters() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(86400 * 30)

        let medication = try service.create(
            name: "Ibuprofen",
            dosageAmount: 200,
            dosageUnit: "mg",
            instructions: "Take with food",
            prescribedBy: "Dr. Smith",
            startDate: startDate,
            endDate: endDate
        )

        XCTAssertEqual(medication.instructions, "Take with food")
        XCTAssertEqual(medication.prescribedBy, "Dr. Smith")
        XCTAssertEqual(medication.startDate, startDate)
        XCTAssertEqual(medication.endDate, endDate)
    }

    func testCreate_ValidationFailure() {
        XCTAssertThrowsError(try service.create(
            name: "",
            dosageAmount: 500,
            dosageUnit: "mg"
        ))
    }

    func testCreate_InBackgroundContext() throws {
        let backgroundContext = persistenceController.newBackgroundContext()

        let medication = try service.create(
            name: "Test Med",
            dosageAmount: 10,
            dosageUnit: "mg",
            in: backgroundContext
        )

        XCTAssertEqual(medication.managedObjectContext, backgroundContext)
    }

    // MARK: - Read Tests

    func testFetchAll_Empty() throws {
        let medications = try service.fetchAll()

        XCTAssertEqual(medications.count, 0)
    }

    func testFetchAll_Multiple() throws {
        try service.create(name: "Med 1", dosageAmount: 10, dosageUnit: "mg")
        try service.create(name: "Med 2", dosageAmount: 20, dosageUnit: "mg")
        try service.create(name: "Med 3", dosageAmount: 30, dosageUnit: "mg")

        let medications = try service.fetchAll()

        XCTAssertEqual(medications.count, 3)
    }

    func testFetchAll_ExcludesInactive() throws {
        try service.create(name: "Active Med", dosageAmount: 10, dosageUnit: "mg")
        let inactive = try service.create(name: "Inactive Med", dosageAmount: 20, dosageUnit: "mg")
        try service.deactivate(inactive)

        let medications = try service.fetchAll(includeInactive: false)

        XCTAssertEqual(medications.count, 1)
        XCTAssertEqual(medications.first?.name, "Active Med")
    }

    func testFetchAll_IncludesInactive() throws {
        try service.create(name: "Active Med", dosageAmount: 10, dosageUnit: "mg")
        let inactive = try service.create(name: "Inactive Med", dosageAmount: 20, dosageUnit: "mg")
        try service.deactivate(inactive)

        let medications = try service.fetchAll(includeInactive: true)

        XCTAssertEqual(medications.count, 2)
    }

    func testFetchAll_SortedByName() throws {
        try service.create(name: "Zebra", dosageAmount: 10, dosageUnit: "mg")
        try service.create(name: "Apple", dosageAmount: 20, dosageUnit: "mg")
        try service.create(name: "Mango", dosageAmount: 30, dosageUnit: "mg")

        let medications = try service.fetchAll()

        XCTAssertEqual(medications[0].name, "Apple")
        XCTAssertEqual(medications[1].name, "Mango")
        XCTAssertEqual(medications[2].name, "Zebra")
    }

    func testFetch_ByID() throws {
        let created = try service.create(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")

        let fetched = try service.fetch(id: created.id)

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, created.id)
        XCTAssertEqual(fetched?.name, "Test Med")
    }

    func testFetch_ByID_NotFound() throws {
        let nonExistentID = UUID()

        let fetched = try service.fetch(id: nonExistentID)

        XCTAssertNil(fetched)
    }

    func testFetchActive_OnlyCurrentlyActive() throws {
        // Active and current
        try service.create(
            name: "Active Med",
            dosageAmount: 10,
            dosageUnit: "mg",
            startDate: Date().addingTimeInterval(-86400)
        )

        // Inactive
        let inactive = try service.create(name: "Inactive Med", dosageAmount: 20, dosageUnit: "mg")
        try service.deactivate(inactive)

        // Future start date
        try service.create(
            name: "Future Med",
            dosageAmount: 30,
            dosageUnit: "mg",
            startDate: Date().addingTimeInterval(86400)
        )

        let activeMedications = try service.fetchActive()

        XCTAssertEqual(activeMedications.count, 1)
        XCTAssertEqual(activeMedications.first?.name, "Active Med")
    }

    func testSearch_FindsMatches() throws {
        try service.create(name: "Aspirin", dosageAmount: 500, dosageUnit: "mg")
        try service.create(name: "Ibuprofen", dosageAmount: 200, dosageUnit: "mg")
        try service.create(name: "Acetaminophen", dosageAmount: 650, dosageUnit: "mg")

        let results = try service.search("fen")

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.name == "Ibuprofen" })
        XCTAssertTrue(results.contains { $0.name == "Acetaminophen" })
    }

    func testSearch_CaseInsensitive() throws {
        try service.create(name: "Aspirin", dosageAmount: 500, dosageUnit: "mg")

        let results = try service.search("ASPIRIN")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Aspirin")
    }

    func testSearch_NoMatches() throws {
        try service.create(name: "Aspirin", dosageAmount: 500, dosageUnit: "mg")

        let results = try service.search("xyz")

        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Update Tests

    func testUpdate_Name() throws {
        let medication = try service.create(name: "Old Name", dosageAmount: 10, dosageUnit: "mg")

        try service.update(medication, name: "New Name")

        XCTAssertEqual(medication.name, "New Name")
    }

    func testUpdate_DosageAmount() throws {
        let medication = try service.create(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")

        try service.update(medication, dosageAmount: 20)

        XCTAssertEqual(medication.dosageAmount, 20)
    }

    func testUpdate_MultipleFields() throws {
        let medication = try service.create(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")

        try service.update(
            medication,
            name: "Updated Med",
            dosageAmount: 50,
            dosageUnit: "mcg",
            instructions: "New instructions"
        )

        XCTAssertEqual(medication.name, "Updated Med")
        XCTAssertEqual(medication.dosageAmount, 50)
        XCTAssertEqual(medication.dosageUnit, "mcg")
        XCTAssertEqual(medication.instructions, "New instructions")
    }

    func testUpdate_ValidationFailure() throws {
        let medication = try service.create(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")

        XCTAssertThrowsError(try service.update(medication, name: ""))
    }

    func testDeactivate_Success() throws {
        let medication = try service.create(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        XCTAssertTrue(medication.isActive)

        try service.deactivate(medication)

        XCTAssertFalse(medication.isActive)
        XCTAssertNotNil(medication.endDate)
    }

    func testReactivate_Success() throws {
        let medication = try service.create(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        try service.deactivate(medication)

        try service.reactivate(medication)

        XCTAssertTrue(medication.isActive)
        XCTAssertNil(medication.endDate)
    }

    // MARK: - Delete Tests

    func testDelete_Success() throws {
        let medication = try service.create(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        let id = medication.id

        try service.delete(medication)

        let fetched = try service.fetch(id: id)
        XCTAssertNil(fetched)
    }

    func testDelete_WithSchedules() throws {
        let medication = try service.create(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")

        let schedule = Schedule(context: persistenceController.viewContext)
        schedule.medication = medication
        schedule.timeOfDay = Date()
        try persistenceController.saveViewContext()

        try service.delete(medication)

        let fetched = try service.fetch(id: medication.id)
        XCTAssertNil(fetched)
    }

    func testDeleteAll_ExcludesActive() throws {
        try service.create(name: "Active Med", dosageAmount: 10, dosageUnit: "mg")
        let inactive = try service.create(name: "Inactive Med", dosageAmount: 20, dosageUnit: "mg")
        try service.deactivate(inactive)

        try service.deleteAll(includeActive: false)

        let remaining = try service.fetchAll(includeInactive: true)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.name, "Active Med")
    }

    func testDeleteAll_IncludesActive() throws {
        try service.create(name: "Active Med", dosageAmount: 10, dosageUnit: "mg")
        let inactive = try service.create(name: "Inactive Med", dosageAmount: 20, dosageUnit: "mg")
        try service.deactivate(inactive)

        try service.deleteAll(includeActive: true)

        let remaining = try service.fetchAll(includeInactive: true)
        XCTAssertEqual(remaining.count, 0)
    }

    // MARK: - Statistics Tests

    func testCount_All() throws {
        try service.create(name: "Med 1", dosageAmount: 10, dosageUnit: "mg")
        try service.create(name: "Med 2", dosageAmount: 20, dosageUnit: "mg")

        let count = try service.count(includeInactive: true)

        XCTAssertEqual(count, 2)
    }

    func testCount_ActiveOnly() throws {
        try service.create(name: "Active Med", dosageAmount: 10, dosageUnit: "mg")
        let inactive = try service.create(name: "Inactive Med", dosageAmount: 20, dosageUnit: "mg")
        try service.deactivate(inactive)

        let count = try service.count(includeInactive: false)

        XCTAssertEqual(count, 1)
    }

    // MARK: - Concurrency Tests

    func testConcurrentCreates() throws {
        let expectation = self.expectation(description: "Concurrent creates")
        expectation.expectedFulfillmentCount = 5

        let backgroundContext = persistenceController.newBackgroundContext()

        for i in 0..<5 {
            backgroundContext.perform {
                do {
                    _ = try self.service.create(
                        name: "Med \(i)",
                        dosageAmount: Double(i * 10),
                        dosageUnit: "mg",
                        in: backgroundContext
                    )
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to create medication: \(error)")
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)

        let medications = try service.fetchAll()
        XCTAssertEqual(medications.count, 5)
    }

    // MARK: - Edge Cases

    func testCreate_UnicodeCharacters() throws {
        let medication = try service.create(
            name: "测试药物 🏥",
            dosageAmount: 100,
            dosageUnit: "μg"
        )

        XCTAssertEqual(medication.name, "测试药物 🏥")
        XCTAssertEqual(medication.dosageUnit, "μg")
    }

    func testCreate_VerySmallDosage() throws {
        let medication = try service.create(
            name: "Micro Dose",
            dosageAmount: 0.001,
            dosageUnit: "mcg"
        )

        XCTAssertEqual(medication.dosageAmount, 0.001)
    }

    func testCreate_VeryLargeDosage() throws {
        let medication = try service.create(
            name: "Large Dose",
            dosageAmount: 99999,
            dosageUnit: "IU"
        )

        XCTAssertEqual(medication.dosageAmount, 99999)
    }
}
