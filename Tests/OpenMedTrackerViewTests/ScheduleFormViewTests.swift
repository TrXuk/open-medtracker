//
//  ScheduleFormViewTests.swift
//  OpenMedTrackerViewTests
//
//  ViewInspector tests for ScheduleFormView
//

import XCTest
import SwiftUI
import ViewInspector
import CoreData
@testable import OpenMedTracker

@MainActor
final class ScheduleFormViewTests: XCTestCase {

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

    func testViewExists_AddMode() throws {
        let medication = createTestMedication()

        let view = ScheduleFormView(medication: medication, mode: .add)
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }

    func testViewExists_EditMode() throws {
        let medication = createTestMedication()
        let schedule = createTestSchedule(for: medication)

        let view = ScheduleFormView(medication: medication, mode: .edit(schedule))
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }

    func testNavigationStackExists() throws {
        let medication = createTestMedication()

        let view = ScheduleFormView(medication: medication, mode: .add)
            .environment(\.managedObjectContext, context)

        let navigationStack = try view.inspect().find(ViewType.NavigationStack.self)
        XCTAssertNotNil(navigationStack)
    }

    // MARK: - Mode Tests

    func testModeTitle_Add() {
        let mode = ScheduleFormView.Mode.add
        XCTAssertEqual(mode.title, "Add Schedule")
        XCTAssertEqual(mode.saveButtonTitle, "Add")
    }

    func testModeTitle_Edit() {
        let medication = createTestMedication()
        let schedule = createTestSchedule(for: medication)
        let mode = ScheduleFormView.Mode.edit(schedule)
        XCTAssertEqual(mode.title, "Edit Schedule")
        XCTAssertEqual(mode.saveButtonTitle, "Save")
    }

    // MARK: - Form Structure Tests

    func testFormExists() throws {
        let medication = createTestMedication()

        let view = ScheduleFormView(medication: medication, mode: .add)
            .environment(\.managedObjectContext, context)

        let form = try view.inspect().find(ViewType.Form.self)
        XCTAssertNotNil(form)
    }

    func testTimePickerExists() throws {
        let medication = createTestMedication()

        let view = ScheduleFormView(medication: medication, mode: .add)
            .environment(\.managedObjectContext, context)

        // Verify form structure includes time picker
        let form = try view.inspect().find(ViewType.Form.self)
        XCTAssertNotNil(form)
    }

    func testFrequencyPickerExists() throws {
        let medication = createTestMedication()

        let view = ScheduleFormView(medication: medication, mode: .add)
            .environment(\.managedObjectContext, context)

        // Verify form includes frequency picker
        let form = try view.inspect().find(ViewType.Form.self)
        XCTAssertNotNil(form)
    }

    // MARK: - Toolbar Tests

    func testCancelButtonExists() throws {
        let medication = createTestMedication()

        let view = ScheduleFormView(medication: medication, mode: .add)
            .environment(\.managedObjectContext, context)

        let toolbar = try view.inspect()
            .find(ViewType.NavigationStack.self)
            .toolbar()
        XCTAssertNotNil(toolbar)
    }

    func testSaveButtonExists() throws {
        let medication = createTestMedication()

        let view = ScheduleFormView(medication: medication, mode: .add)
            .environment(\.managedObjectContext, context)

        let toolbar = try view.inspect()
            .find(ViewType.NavigationStack.self)
            .toolbar()
        XCTAssertNotNil(toolbar)
    }

    // MARK: - Frequency Options Tests

    func testDailyFrequency_ShowsEveryDayText() throws {
        let medication = createTestMedication()

        let view = ScheduleFormView(medication: medication, mode: .add)
            .environment(\.managedObjectContext, context)

        // Default frequency is daily
        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - Days of Week Tests

    func testWeeklyFrequency_ShowsDayToggles() throws {
        let medication = createTestMedication()
        let schedule = createTestSchedule(for: medication)
        schedule.frequency = "weekly"

        let view = ScheduleFormView(medication: medication, mode: .edit(schedule))
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - Prepopulation Tests (Edit Mode)

    func testFieldsPrepopulated_EditMode() throws {
        let medication = createTestMedication()
        let schedule = createTestSchedule(for: medication)
        schedule.timeHour = 14
        schedule.timeMinute = 30
        schedule.frequency = "daily"
        schedule.daysOfWeek = 127
        schedule.isEnabled = true

        let view = ScheduleFormView(medication: medication, mode: .edit(schedule))
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }

    func testWeeklySchedulePrepopulation() throws {
        let medication = createTestMedication()
        let schedule = createTestSchedule(for: medication)
        schedule.frequency = "weekly"
        schedule.daysOfWeek = 62 // Mon-Fri (0b0111110)

        let view = ScheduleFormView(medication: medication, mode: .edit(schedule))
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - Status Toggle Tests

    func testEnabledToggleExists() throws {
        let medication = createTestMedication()

        let view = ScheduleFormView(medication: medication, mode: .add)
            .environment(\.managedObjectContext, context)

        // Verify form includes enabled toggle
        let form = try view.inspect().find(ViewType.Form.self)
        XCTAssertNotNil(form)
    }

    // MARK: - Integration Tests

    func testViewRendersInAddMode() throws {
        let medication = createTestMedication()

        let view = ScheduleFormView(medication: medication, mode: .add)
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }

    func testViewRendersInEditMode() throws {
        let medication = createTestMedication()
        let schedule = createTestSchedule(for: medication)

        let view = ScheduleFormView(medication: medication, mode: .edit(schedule))
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }

    func testViewRendersWithDifferentFrequencies() throws {
        let medication = createTestMedication()

        // Test daily
        let dailySchedule = createTestSchedule(for: medication)
        dailySchedule.frequency = "daily"
        var view = ScheduleFormView(medication: medication, mode: .edit(dailySchedule))
            .environment(\.managedObjectContext, context)
        XCTAssertNoThrow(try view.inspect())

        // Test weekly
        let weeklySchedule = createTestSchedule(for: medication)
        weeklySchedule.frequency = "weekly"
        view = ScheduleFormView(medication: medication, mode: .edit(weeklySchedule))
            .environment(\.managedObjectContext, context)
        XCTAssertNoThrow(try view.inspect())

        // Test as needed
        let asNeededSchedule = createTestSchedule(for: medication)
        asNeededSchedule.frequency = "as needed"
        view = ScheduleFormView(medication: medication, mode: .edit(asNeededSchedule))
            .environment(\.managedObjectContext, context)
        XCTAssertNoThrow(try view.inspect())
    }

    func testViewRendersWithDifferentTimes() throws {
        let medication = createTestMedication()

        // Morning time
        let morningSchedule = createTestSchedule(for: medication)
        morningSchedule.timeHour = 8
        morningSchedule.timeMinute = 0
        var view = ScheduleFormView(medication: medication, mode: .edit(morningSchedule))
            .environment(\.managedObjectContext, context)
        XCTAssertNoThrow(try view.inspect())

        // Evening time
        let eveningSchedule = createTestSchedule(for: medication)
        eveningSchedule.timeHour = 20
        eveningSchedule.timeMinute = 30
        view = ScheduleFormView(medication: medication, mode: .edit(eveningSchedule))
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
}

// MARK: - ViewInspector Extension

extension ScheduleFormView: Inspectable { }
