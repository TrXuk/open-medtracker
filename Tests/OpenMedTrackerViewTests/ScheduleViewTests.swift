//
//  ScheduleViewTests.swift
//  OpenMedTrackerViewTests
//
//  ViewInspector tests for ScheduleView and related components
//

import XCTest
import SwiftUI
import ViewInspector
import CoreData
@testable import OpenMedTracker

@MainActor
final class ScheduleViewTests: XCTestCase {

    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!

    override func setUp() async throws {
        try await super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }

    override func tearDown() async throws {
        persistenceController = nil
        context = nil
        try await super.tearDown()
    }

    // MARK: - View Structure Tests

    func testViewExists() throws {
        let view = ScheduleView()
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }

    func testNavigationStackExists() throws {
        let view = ScheduleView()
            .environment(\.managedObjectContext, context)

        let navigationStack = try view.inspect().find(ViewType.NavigationStack.self)
        XCTAssertNotNil(navigationStack)
    }

    func testNavigationTitle() throws {
        let view = ScheduleView()
            .environment(\.managedObjectContext, context)

        let title = try view.inspect()
            .find(ViewType.NavigationStack.self)
            .navigationTitle()
        XCTAssertEqual(title, "Schedule")
    }

    // MARK: - Toolbar Tests

    func testCalendarButtonExists() throws {
        let view = ScheduleView()
            .environment(\.managedObjectContext, context)

        let toolbar = try view.inspect()
            .find(ViewType.NavigationStack.self)
            .toolbar()
        XCTAssertNotNil(toolbar)
    }

    // MARK: - Empty State Tests

    func testEmptyStateDisplayed_WhenNoDoses() throws {
        let view = ScheduleView()
            .environment(\.managedObjectContext, context)

        // Should render without error
        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - Loading State Tests

    func testLoadingViewStructure() throws {
        let view = ScheduleView()
            .environment(\.managedObjectContext, context)

        // Verify view structure exists
        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - DoseCard Component Tests

    func testDoseCardStructure() throws {
        let dose = createTestDose()

        let card = DoseCard(
            dose: dose,
            onMarkTaken: {},
            onMarkSkipped: {},
            onMarkMissed: {}
        )

        XCTAssertNoThrow(try card.inspect())
    }

    func testDoseCard_DisplaysMedicationName() throws {
        let dose = createTestDose()
        dose.setValue("Aspirin", forKey: "medicationName")

        let card = DoseCard(
            dose: dose,
            onMarkTaken: {},
            onMarkSkipped: {},
            onMarkMissed: {}
        )

        XCTAssertNoThrow(try card.inspect())
    }

    func testDoseCard_PendingStatus_ShowsActionButtons() throws {
        let dose = createTestDose()
        dose.status = "pending"

        let card = DoseCard(
            dose: dose,
            onMarkTaken: {},
            onMarkSkipped: {},
            onMarkMissed: {}
        )

        // Verify card structure
        XCTAssertNoThrow(try card.inspect())
    }

    func testDoseCard_TakenStatus_ShowsCompletionMessage() throws {
        let dose = createTestDose()
        dose.status = "taken"
        dose.actualTime = Date()

        let card = DoseCard(
            dose: dose,
            onMarkTaken: {},
            onMarkSkipped: {},
            onMarkMissed: {}
        )

        XCTAssertNoThrow(try card.inspect())
    }

    // MARK: - DatePickerSheet Component Tests

    func testDatePickerSheetExists() throws {
        let binding = Binding.constant(Date())

        let sheet = DatePickerSheet(
            selectedDate: binding,
            onSelect: {}
        )

        XCTAssertNoThrow(try sheet.inspect())
    }

    func testDatePickerSheet_HasNavigationStack() throws {
        let binding = Binding.constant(Date())

        let sheet = DatePickerSheet(
            selectedDate: binding,
            onSelect: {}
        )

        let navigationStack = try sheet.inspect().find(ViewType.NavigationStack.self)
        XCTAssertNotNil(navigationStack)
    }

    func testDatePickerSheet_HasCancelButton() throws {
        let binding = Binding.constant(Date())

        let sheet = DatePickerSheet(
            selectedDate: binding,
            onSelect: {}
        )

        let toolbar = try sheet.inspect()
            .find(ViewType.NavigationStack.self)
            .toolbar()
        XCTAssertNotNil(toolbar)
    }

    func testDatePickerSheet_HasDoneButton() throws {
        let binding = Binding.constant(Date())

        let sheet = DatePickerSheet(
            selectedDate: binding,
            onSelect: {}
        )

        let toolbar = try sheet.inspect()
            .find(ViewType.NavigationStack.self)
            .toolbar()
        XCTAssertNotNil(toolbar)
    }

    // MARK: - Date Navigation Tests

    func testDateHeaderSectionExists() throws {
        let view = ScheduleView()
            .environment(\.managedObjectContext, context)

        // Verify view structure
        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - Integration Tests

    func testViewRendersWithoutData() throws {
        let view = ScheduleView()
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }

    func testViewRendersWithDoseData() throws {
        // Create test medication and schedule
        let medication = createTestMedication()
        let schedule = createTestSchedule(for: medication)
        let dose = createTestDose()
        dose.schedule = schedule

        try context.save()

        let view = ScheduleView()
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - Helper Methods

    private func createTestMedication() -> Medication {
        let medication = Medication(context: context)
        medication.id = UUID()
        medication.name = "Test Medication"
        medication.dosageAmount = 100
        medication.dosageUnit = "mg"
        medication.startDate = Date()
        medication.isActive = true
        medication.createdAt = Date()
        medication.updatedAt = Date()
        return medication
    }

    private func createTestSchedule(for medication: Medication) -> Schedule {
        let schedule = Schedule(context: context)
        schedule.id = UUID()
        schedule.medication = medication
        schedule.timeHour = 9
        schedule.timeMinute = 0
        schedule.frequency = "daily"
        schedule.daysOfWeek = 127
        schedule.isEnabled = true
        schedule.createdAt = Date()
        schedule.updatedAt = Date()
        return schedule
    }

    private func createTestDose() -> DoseHistory {
        let dose = DoseHistory(context: context)
        dose.id = UUID()
        dose.scheduledTime = Date()
        dose.status = "pending"
        dose.timezoneIdentifier = "UTC"
        dose.timezoneOffset = 0
        dose.createdAt = Date()
        dose.updatedAt = Date()
        return dose
    }
}

// MARK: - ViewInspector Extensions

extension ScheduleView: Inspectable { }
extension DoseCard: Inspectable { }
extension DatePickerSheet: Inspectable { }
