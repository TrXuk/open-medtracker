//
//  ScheduleServiceTests.swift
//  OpenMedTrackerTests
//
//  Integration tests for ScheduleService CRUD operations
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class ScheduleServiceTests: XCTestCase {

    var persistenceController: PersistenceController!
    var service: ScheduleService!
    var medicationService: MedicationService!
    var testMedication: Medication!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        service = ScheduleService(persistenceController: persistenceController)
        medicationService = MedicationService(persistenceController: persistenceController)

        testMedication = try! medicationService.create(
            name: "Test Med",
            dosageAmount: 10,
            dosageUnit: "mg"
        )
    }

    override func tearDown() {
        testMedication = nil
        medicationService = nil
        service = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Create Tests

    func testCreate_WithDate() throws {
        let timeOfDay = Date()

        let schedule = try service.create(
            for: testMedication,
            timeOfDay: timeOfDay,
            frequency: "daily",
            daysOfWeek: 127
        )

        XCTAssertEqual(schedule.medication, testMedication)
        XCTAssertEqual(schedule.timeOfDay, timeOfDay)
        XCTAssertEqual(schedule.frequency, "daily")
        XCTAssertEqual(schedule.daysOfWeek, 127)
        XCTAssertTrue(schedule.isEnabled)
    }

    func testCreate_WithTimeComponents() throws {
        let schedule = try service.create(
            for: testMedication,
            hour: 14,
            minute: 30,
            frequency: "daily",
            daysOfWeek: 62 // Weekdays
        )

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: schedule.timeOfDay)
        let minute = calendar.component(.minute, from: schedule.timeOfDay)

        XCTAssertEqual(hour, 14)
        XCTAssertEqual(minute, 30)
        XCTAssertEqual(schedule.daysOfWeek, 62)
    }

    func testCreate_InvalidTimeComponents() {
        XCTAssertThrowsError(try service.create(
            for: testMedication,
            hour: 25,  // Invalid hour
            minute: 30
        ))
    }

    func testCreate_ValidationFailure() {
        XCTAssertThrowsError(try service.create(
            for: testMedication,
            timeOfDay: Date(),
            frequency: "invalid"
        ))
    }

    // MARK: - Read Tests

    func testFetchAll_Empty() throws {
        let schedules = try service.fetchAll()

        XCTAssertEqual(schedules.count, 0)
    }

    func testFetchAll_Multiple() throws {
        try service.create(for: testMedication, hour: 8, minute: 0)
        try service.create(for: testMedication, hour: 14, minute: 0)
        try service.create(for: testMedication, hour: 20, minute: 0)

        let schedules = try service.fetchAll()

        XCTAssertEqual(schedules.count, 3)
    }

    func testFetchAll_SortedByTime() throws {
        try service.create(for: testMedication, hour: 20, minute: 0)
        try service.create(for: testMedication, hour: 8, minute: 0)
        try service.create(for: testMedication, hour: 14, minute: 0)

        let schedules = try service.fetchAll()

        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: schedules[0].timeOfDay), 8)
        XCTAssertEqual(calendar.component(.hour, from: schedules[1].timeOfDay), 14)
        XCTAssertEqual(calendar.component(.hour, from: schedules[2].timeOfDay), 20)
    }

    func testFetchAll_ExcludesDisabled() throws {
        try service.create(for: testMedication, hour: 8, minute: 0)
        let disabled = try service.create(for: testMedication, hour: 14, minute: 0)
        try service.disable(disabled)

        let schedules = try service.fetchAll(includeDisabled: false)

        XCTAssertEqual(schedules.count, 1)
    }

    func testFetch_ByID() throws {
        let created = try service.create(for: testMedication, hour: 9, minute: 0)

        let fetched = try service.fetch(id: created.id)

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, created.id)
    }

    func testFetchSchedules_ForMedication() throws {
        let med2 = try! medicationService.create(name: "Med 2", dosageAmount: 20, dosageUnit: "mg")

        try service.create(for: testMedication, hour: 9, minute: 0)
        try service.create(for: testMedication, hour: 21, minute: 0)
        try service.create(for: med2, hour: 12, minute: 0)

        let schedules = try service.fetchSchedules(for: testMedication)

        XCTAssertEqual(schedules.count, 2)
        XCTAssertTrue(schedules.allSatisfy { $0.medication == testMedication })
    }

    func testFetchSchedulesDue_OnDate() throws {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let todayBit = Schedule.DayOfWeek(rawValue: weekday - 1)?.bit ?? 1

        // Schedule for today
        try service.create(
            for: testMedication,
            hour: 9,
            minute: 0,
            daysOfWeek: todayBit
        )

        // Schedule for different day
        let differentDay: Int16 = todayBit == 1 ? 2 : 1
        try service.create(
            for: testMedication,
            hour: 14,
            minute: 0,
            daysOfWeek: differentDay
        )

        let dueSchedules = try service.fetchSchedulesDue(on: today)

        XCTAssertEqual(dueSchedules.count, 1)
    }

    // MARK: - Update Tests

    func testUpdate_TimeOfDay() throws {
        let schedule = try service.create(for: testMedication, hour: 9, minute: 0)

        let calendar = Calendar.current
        let newTime = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: Date())!

        try service.update(schedule, timeOfDay: newTime)

        let hour = calendar.component(.hour, from: schedule.timeOfDay)
        let minute = calendar.component(.minute, from: schedule.timeOfDay)

        XCTAssertEqual(hour, 14)
        XCTAssertEqual(minute, 30)
    }

    func testUpdate_DaysOfWeek() throws {
        let schedule = try service.create(for: testMedication, hour: 9, minute: 0, daysOfWeek: 127)

        try service.update(schedule, daysOfWeek: 62) // Weekdays

        XCTAssertEqual(schedule.daysOfWeek, 62)
    }

    func testUpdate_Frequency() throws {
        let schedule = try service.create(for: testMedication, hour: 9, minute: 0, frequency: "daily")

        try service.update(schedule, frequency: "weekly")

        XCTAssertEqual(schedule.frequency, "weekly")
    }

    func testEnable_Success() throws {
        let schedule = try service.create(for: testMedication, hour: 9, minute: 0, isEnabled: false)

        try service.enable(schedule)

        XCTAssertTrue(schedule.isEnabled)
    }

    func testDisable_Success() throws {
        let schedule = try service.create(for: testMedication, hour: 9, minute: 0, isEnabled: true)

        try service.disable(schedule)

        XCTAssertFalse(schedule.isEnabled)
    }

    // MARK: - Delete Tests

    func testDelete_Success() throws {
        let schedule = try service.create(for: testMedication, hour: 9, minute: 0)
        let id = schedule.id

        try service.delete(schedule)

        let fetched = try service.fetch(id: id)
        XCTAssertNil(fetched)
    }

    func testDeleteSchedules_ForMedication() throws {
        try service.create(for: testMedication, hour: 9, minute: 0)
        try service.create(for: testMedication, hour: 21, minute: 0)

        try service.deleteSchedules(for: testMedication)

        let schedules = try service.fetchSchedules(for: testMedication, includeDisabled: true)
        XCTAssertEqual(schedules.count, 0)
    }

    // MARK: - Helper Methods Tests

    func testNextScheduledTime_FindsNextTime() throws {
        let calendar = Calendar.current
        let now = Date()

        // Create schedule 2 hours from now
        let futureHour = (calendar.component(.hour, from: now) + 2) % 24
        try service.create(for: testMedication, hour: futureHour, minute: 0, daysOfWeek: 127)

        let nextTime = try service.nextScheduledTime(after: now)

        XCTAssertNotNil(nextTime)
        XCTAssertGreaterThan(nextTime!, now)
    }

    func testNextScheduledTime_NoSchedules() throws {
        let nextTime = try service.nextScheduledTime()

        XCTAssertNil(nextTime)
    }

    func testNextScheduledTime_OnlyDisabledSchedules() throws {
        let schedule = try service.create(for: testMedication, hour: 14, minute: 0)
        try service.disable(schedule)

        let nextTime = try service.nextScheduledTime()

        XCTAssertNil(nextTime)
    }

    func testCount_All() throws {
        try service.create(for: testMedication, hour: 9, minute: 0)
        try service.create(for: testMedication, hour: 21, minute: 0)

        let count = try service.count(includeDisabled: true)

        XCTAssertEqual(count, 2)
    }

    func testCount_EnabledOnly() throws {
        try service.create(for: testMedication, hour: 9, minute: 0)
        let disabled = try service.create(for: testMedication, hour: 21, minute: 0)
        try service.disable(disabled)

        let count = try service.count(includeDisabled: false)

        XCTAssertEqual(count, 1)
    }

    // MARK: - Edge Cases

    func testCreate_MidnightSchedule() throws {
        let schedule = try service.create(for: testMedication, hour: 0, minute: 0)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: schedule.timeOfDay)

        XCTAssertEqual(hour, 0)
    }

    func testCreate_EndOfDaySchedule() throws {
        let schedule = try service.create(for: testMedication, hour: 23, minute: 59)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: schedule.timeOfDay)
        let minute = calendar.component(.minute, from: schedule.timeOfDay)

        XCTAssertEqual(hour, 23)
        XCTAssertEqual(minute, 59)
    }

    func testCreate_AllDaysOfWeek() throws {
        let schedule = try service.create(for: testMedication, hour: 9, minute: 0, daysOfWeek: 127)

        XCTAssertTrue(schedule.isEveryday)
    }

    func testCreate_SingleDayOfWeek() throws {
        let schedule = try service.create(for: testMedication, hour: 9, minute: 0, daysOfWeek: 1)

        XCTAssertEqual(schedule.enabledDays.count, 1)
        XCTAssertEqual(schedule.enabledDays.first, .sunday)
    }

    func testFetchSchedulesDue_WithDifferentFrequencies() throws {
        try service.create(
            for: testMedication,
            hour: 9,
            minute: 0,
            frequency: "daily",
            daysOfWeek: 127
        )

        try service.create(
            for: testMedication,
            hour: 14,
            minute: 0,
            frequency: "weekly",
            daysOfWeek: 127
        )

        let dueSchedules = try service.fetchSchedulesDue(on: Date())

        // Both should be due since they're set to all days
        XCTAssertEqual(dueSchedules.count, 2)
    }
}
