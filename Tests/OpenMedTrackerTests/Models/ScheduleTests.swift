//
//  ScheduleTests.swift
//  OpenMedTrackerTests
//
//  Unit tests for Schedule Core Data model
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class ScheduleTests: XCTestCase {

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
    }

    override func tearDown() {
        testMedication = nil
        context = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testScheduleInitialization() {
        let schedule = Schedule(context: context)

        XCTAssertNotNil(schedule.id)
        XCTAssertNotNil(schedule.createdAt)
        XCTAssertNotNil(schedule.updatedAt)
        XCTAssertTrue(schedule.isEnabled)
        XCTAssertEqual(schedule.frequency, "daily")
        XCTAssertEqual(schedule.daysOfWeek, 127) // All days
    }

    // MARK: - DayOfWeek Enum Tests

    func testDayOfWeekBitValues() {
        XCTAssertEqual(Schedule.DayOfWeek.sunday.bit, 1)
        XCTAssertEqual(Schedule.DayOfWeek.monday.bit, 2)
        XCTAssertEqual(Schedule.DayOfWeek.tuesday.bit, 4)
        XCTAssertEqual(Schedule.DayOfWeek.wednesday.bit, 8)
        XCTAssertEqual(Schedule.DayOfWeek.thursday.bit, 16)
        XCTAssertEqual(Schedule.DayOfWeek.friday.bit, 32)
        XCTAssertEqual(Schedule.DayOfWeek.saturday.bit, 64)
    }

    func testDayOfWeekNames() {
        XCTAssertFalse(Schedule.DayOfWeek.monday.name.isEmpty)
        XCTAssertFalse(Schedule.DayOfWeek.monday.shortName.isEmpty)
    }

    // MARK: - Computed Properties Tests

    func testFormattedTime() {
        let schedule = createTestSchedule(hour: 14, minute: 30)

        let formattedTime = schedule.formattedTime
        XCTAssertFalse(formattedTime.isEmpty)
        XCTAssertTrue(formattedTime.contains("2") || formattedTime.contains("14"))
    }

    func testEnabledDays_AllDays() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.daysOfWeek = 127

        XCTAssertEqual(schedule.enabledDays.count, 7)
    }

    func testEnabledDays_Weekdays() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.daysOfWeek = 62 // Monday-Friday

        let enabledDays = schedule.enabledDays
        XCTAssertEqual(enabledDays.count, 5)
        XCTAssertTrue(enabledDays.contains(.monday))
        XCTAssertTrue(enabledDays.contains(.friday))
        XCTAssertFalse(enabledDays.contains(.saturday))
        XCTAssertFalse(enabledDays.contains(.sunday))
    }

    func testScheduleDescription() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.daysOfWeek = 127

        let description = schedule.scheduleDescription
        XCTAssertFalse(description.isEmpty)
    }

    func testIsEveryday() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.daysOfWeek = 127

        XCTAssertTrue(schedule.isEveryday)

        schedule.daysOfWeek = 126
        XCTAssertFalse(schedule.isEveryday)
    }

    func testIsWeekdaysOnly() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.daysOfWeek = 62 // Monday-Friday

        XCTAssertTrue(schedule.isWeekdaysOnly)

        schedule.daysOfWeek = 127
        XCTAssertFalse(schedule.isWeekdaysOnly)
    }

    func testIsWeekendsOnly() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.daysOfWeek = 65 // Saturday-Sunday

        XCTAssertTrue(schedule.isWeekendsOnly)

        schedule.daysOfWeek = 127
        XCTAssertFalse(schedule.isWeekendsOnly)
    }

    // MARK: - Day Management Tests

    func testIsDayEnabled() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.daysOfWeek = 2 // Only Monday

        XCTAssertTrue(schedule.isDayEnabled(.monday))
        XCTAssertFalse(schedule.isDayEnabled(.tuesday))
    }

    func testEnableDay() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.daysOfWeek = 0

        schedule.enableDay(.monday)
        XCTAssertTrue(schedule.isDayEnabled(.monday))

        schedule.enableDay(.friday)
        XCTAssertTrue(schedule.isDayEnabled(.monday))
        XCTAssertTrue(schedule.isDayEnabled(.friday))
    }

    func testDisableDay() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.daysOfWeek = 127 // All days

        schedule.disableDay(.monday)
        XCTAssertFalse(schedule.isDayEnabled(.monday))
        XCTAssertTrue(schedule.isDayEnabled(.tuesday))
    }

    func testToggleDay() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.daysOfWeek = 0

        schedule.toggleDay(.monday)
        XCTAssertTrue(schedule.isDayEnabled(.monday))

        schedule.toggleDay(.monday)
        XCTAssertFalse(schedule.isDayEnabled(.monday))
    }

    // MARK: - Schedule Logic Tests

    func testIsDueOn_EnabledSchedule() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.isEnabled = true
        schedule.daysOfWeek = 127 // All days

        XCTAssertTrue(schedule.isDueOn(date: Date()))
    }

    func testIsDueOn_DisabledSchedule() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.isEnabled = false
        schedule.daysOfWeek = 127

        XCTAssertFalse(schedule.isDueOn(date: Date()))
    }

    func testIsDueOn_SpecificWeekday() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.isEnabled = true

        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let todayEnum = Schedule.DayOfWeek(rawValue: weekday - 1) ?? .sunday

        // Enable only today
        schedule.daysOfWeek = todayEnum.bit
        XCTAssertTrue(schedule.isDueOn(date: today))

        // Enable only a different day
        let otherDay: Schedule.DayOfWeek = todayEnum == .monday ? .tuesday : .monday
        schedule.daysOfWeek = otherDay.bit
        XCTAssertFalse(schedule.isDueOn(date: today))
    }

    func testNextScheduledTime_Today() {
        let calendar = Calendar.current
        let now = Date()
        let futureTime = calendar.date(byAdding: .hour, value: 2, to: now)!
        let futureHour = calendar.component(.hour, from: futureTime)
        let futureMinute = calendar.component(.minute, from: futureTime)

        let schedule = createTestSchedule(hour: futureHour, minute: futureMinute)
        schedule.isEnabled = true
        schedule.daysOfWeek = 127

        let nextTime = schedule.nextScheduledTime(after: now)
        XCTAssertNotNil(nextTime)

        if let nextTime = nextTime {
            let nextHour = calendar.component(.hour, from: nextTime)
            let nextMinute = calendar.component(.minute, from: nextTime)
            XCTAssertEqual(nextHour, futureHour)
            XCTAssertEqual(nextMinute, futureMinute)
        }
    }

    func testNextScheduledTime_Tomorrow() {
        let calendar = Calendar.current
        let now = Date()
        let pastTime = calendar.date(byAdding: .hour, value: -2, to: now)!
        let pastHour = calendar.component(.hour, from: pastTime)
        let pastMinute = calendar.component(.minute, from: pastTime)

        let schedule = createTestSchedule(hour: pastHour, minute: pastMinute)
        schedule.isEnabled = true
        schedule.daysOfWeek = 127

        let nextTime = schedule.nextScheduledTime(after: now)
        XCTAssertNotNil(nextTime)

        if let nextTime = nextTime {
            XCTAssertGreaterThan(nextTime, now)
        }
    }

    func testNextScheduledTime_DisabledSchedule() {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.isEnabled = false

        XCTAssertNil(schedule.nextScheduledTime())
    }

    func testNextScheduledTime_SpecificDays() {
        let calendar = Calendar.current
        let now = Date()

        let schedule = createTestSchedule(hour: 9, minute: 0)
        schedule.isEnabled = true
        schedule.daysOfWeek = 2 // Only Monday

        let nextTime = schedule.nextScheduledTime(after: now)

        if let nextTime = nextTime {
            let weekday = calendar.component(.weekday, from: nextTime)
            XCTAssertEqual(weekday, 2) // Monday
        }
    }

    // MARK: - Lifecycle Tests

    func testWillSave_UpdatesTimestamp() throws {
        let schedule = createTestSchedule(hour: 9, minute: 0)
        try context.save()

        let originalUpdatedAt = schedule.updatedAt

        Thread.sleep(forTimeInterval: 0.01)

        schedule.isEnabled = false
        try context.save()

        XCTAssertGreaterThan(schedule.updatedAt, originalUpdatedAt)
    }

    // MARK: - Helper Methods

    private func createTestSchedule(hour: Int, minute: Int) -> Schedule {
        let schedule = Schedule(context: context)
        schedule.medication = testMedication

        let calendar = Calendar.current
        let now = Date()
        schedule.timeOfDay = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)!

        return schedule
    }
}
