//
//  MedicationTests.swift
//  OpenMedTrackerTests
//
//  Unit tests for Medication Core Data model
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class MedicationTests: XCTestCase {

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

    // MARK: - Initialization Tests

    func testMedicationInitialization() {
        let medication = Medication(context: context)

        XCTAssertNotNil(medication.id, "ID should be auto-generated")
        XCTAssertNotNil(medication.createdAt, "CreatedAt should be auto-set")
        XCTAssertNotNil(medication.updatedAt, "UpdatedAt should be auto-set")
        XCTAssertTrue(medication.isActive, "Should be active by default")
    }

    func testMedicationCreationWithProperties() {
        let medication = createTestMedication(
            name: "Aspirin",
            dosageAmount: 500,
            dosageUnit: "mg"
        )

        XCTAssertEqual(medication.name, "Aspirin")
        XCTAssertEqual(medication.dosageAmount, 500)
        XCTAssertEqual(medication.dosageUnit, "mg")
    }

    // MARK: - Computed Properties Tests

    func testFullDescription() {
        let medication = createTestMedication(
            name: "Ibuprofen",
            dosageAmount: 200,
            dosageUnit: "mg"
        )

        XCTAssertEqual(medication.fullDescription, "Ibuprofen - 200.0mg")
    }

    func testIsCurrentlyActive_WithActiveFlag() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        medication.isActive = true
        medication.startDate = Date().addingTimeInterval(-86400) // Yesterday

        XCTAssertTrue(medication.isCurrentlyActive)
    }

    func testIsCurrentlyActive_WithInactiveFlag() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        medication.isActive = false

        XCTAssertFalse(medication.isCurrentlyActive)
    }

    func testIsCurrentlyActive_WithFutureStartDate() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        medication.isActive = true
        medication.startDate = Date().addingTimeInterval(86400) // Tomorrow

        XCTAssertFalse(medication.isCurrentlyActive)
    }

    func testIsCurrentlyActive_WithPastEndDate() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        medication.isActive = true
        medication.startDate = Date().addingTimeInterval(-172800) // 2 days ago
        medication.endDate = Date().addingTimeInterval(-86400) // Yesterday

        XCTAssertFalse(medication.isCurrentlyActive)
    }

    func testIsCurrentlyActive_WithFutureEndDate() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        medication.isActive = true
        medication.startDate = Date().addingTimeInterval(-86400) // Yesterday
        medication.endDate = Date().addingTimeInterval(86400) // Tomorrow

        XCTAssertTrue(medication.isCurrentlyActive)
    }

    func testActiveScheduleCount() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")

        let schedule1 = Schedule(context: context)
        schedule1.medication = medication
        schedule1.isEnabled = true
        schedule1.timeOfDay = Date()

        let schedule2 = Schedule(context: context)
        schedule2.medication = medication
        schedule2.isEnabled = true
        schedule2.timeOfDay = Date()

        let schedule3 = Schedule(context: context)
        schedule3.medication = medication
        schedule3.isEnabled = false
        schedule3.timeOfDay = Date()

        XCTAssertEqual(medication.activeScheduleCount, 2)
    }

    func testSortedSchedules() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")

        let calendar = Calendar.current
        let now = Date()

        let schedule1 = Schedule(context: context)
        schedule1.medication = medication
        schedule1.timeOfDay = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now)!

        let schedule2 = Schedule(context: context)
        schedule2.medication = medication
        schedule2.timeOfDay = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)!

        let schedule3 = Schedule(context: context)
        schedule3.medication = medication
        schedule3.timeOfDay = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now)!

        let sorted = medication.sortedSchedules
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(calendar.component(.hour, from: sorted[0].timeOfDay), 8)
        XCTAssertEqual(calendar.component(.hour, from: sorted[1].timeOfDay), 14)
        XCTAssertEqual(calendar.component(.hour, from: sorted[2].timeOfDay), 20)
    }

    func testDurationInDays_NoEndDate() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        medication.startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        let duration = medication.durationInDays
        XCTAssertGreaterThanOrEqual(duration, 29)
        XCTAssertLessThanOrEqual(duration, 31)
    }

    func testDurationInDays_WithEndDate() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        medication.startDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        medication.endDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!

        let duration = medication.durationInDays
        XCTAssertEqual(duration, 7)
    }

    // MARK: - Helper Methods Tests

    func testDeactivate() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        medication.isActive = true
        medication.endDate = nil

        medication.deactivate()

        XCTAssertFalse(medication.isActive)
        XCTAssertNotNil(medication.endDate)
    }

    func testReactivate() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        medication.isActive = false
        medication.endDate = Date()

        medication.reactivate()

        XCTAssertTrue(medication.isActive)
        XCTAssertNil(medication.endDate)
    }

    func testShouldTakeOn_WithActiveSchedule() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        medication.isActive = true
        medication.startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let schedule = Schedule(context: context)
        schedule.medication = medication
        schedule.isEnabled = true
        schedule.timeOfDay = Date()
        schedule.daysOfWeek = 127 // All days

        XCTAssertTrue(medication.shouldTakeOn(date: Date()))
    }

    func testShouldTakeOn_WithInactiveMedication() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        medication.isActive = false

        XCTAssertFalse(medication.shouldTakeOn(date: Date()))
    }

    func testShouldTakeOn_WithDisabledSchedule() {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        medication.isActive = true
        medication.startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let schedule = Schedule(context: context)
        schedule.medication = medication
        schedule.isEnabled = false
        schedule.timeOfDay = Date()

        XCTAssertFalse(medication.shouldTakeOn(date: Date()))
    }

    // MARK: - Lifecycle Tests

    func testWillSave_UpdatesTimestamp() throws {
        let medication = createTestMedication(name: "Test Med", dosageAmount: 10, dosageUnit: "mg")
        try context.save()

        let originalUpdatedAt = medication.updatedAt

        // Wait a small amount to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        medication.name = "Updated Med"
        try context.save()

        XCTAssertNotEqual(medication.updatedAt, originalUpdatedAt)
        XCTAssertGreaterThan(medication.updatedAt, originalUpdatedAt)
    }

    // MARK: - Helper Methods

    private func createTestMedication(
        name: String,
        dosageAmount: Double,
        dosageUnit: String
    ) -> Medication {
        let medication = Medication(context: context)
        medication.name = name
        medication.dosageAmount = dosageAmount
        medication.dosageUnit = dosageUnit
        medication.startDate = Date()
        return medication
    }
}
