//
//  TimezoneEventServiceTests.swift
//  OpenMedTrackerTests
//
//  Integration tests for TimezoneEventService CRUD operations
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class TimezoneEventServiceTests: XCTestCase {

    var persistenceController: PersistenceController!
    var service: TimezoneEventService!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        service = TimezoneEventService(persistenceController: persistenceController)
    }

    override func tearDown() {
        service = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Create Tests

    func testCreate_WithStrings() throws {
        let event = try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London"
        )

        XCTAssertEqual(event.previousTimezone, "America/New_York")
        XCTAssertEqual(event.newTimezone, "Europe/London")
        XCTAssertNotNil(event.transitionTime)
        XCTAssertNotNil(event.id)
    }

    func testCreate_WithTimeZoneObjects() throws {
        let previous = TimeZone(identifier: "America/Los_Angeles")!
        let new = TimeZone(identifier: "Asia/Tokyo")!

        let event = try service.create(
            from: previous,
            to: new
        )

        XCTAssertEqual(event.previousTimezone, "America/Los_Angeles")
        XCTAssertEqual(event.newTimezone, "Asia/Tokyo")
    }

    func testCreate_WithAllParameters() throws {
        let transitionTime = Date()

        let event = try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London",
            transitionTime: transitionTime,
            location: "London, UK",
            notes: "Business trip"
        )

        XCTAssertEqual(event.transitionTime, transitionTime)
        XCTAssertEqual(event.location, "London, UK")
        XCTAssertEqual(event.notes, "Business trip")
    }

    func testRecordCurrentTimezoneChange() throws {
        let event = try service.recordCurrentTimezoneChange(
            from: "America/New_York",
            location: "Home",
            notes: "Returned from trip"
        )

        XCTAssertEqual(event.previousTimezone, "America/New_York")
        XCTAssertEqual(event.newTimezone, TimeZone.current.identifier)
        XCTAssertEqual(event.location, "Home")
    }

    func testCreate_ValidationFailure() {
        XCTAssertThrowsError(try service.create(
            previousTimezone: "Invalid/Timezone",
            newTimezone: "Europe/London"
        ))
    }

    // MARK: - Read Tests

    func testFetchAll_Empty() throws {
        let events = try service.fetchAll()

        XCTAssertEqual(events.count, 0)
    }

    func testFetchAll_Multiple() throws {
        try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London"
        )
        try service.create(
            previousTimezone: "Europe/London",
            newTimezone: "Asia/Tokyo"
        )

        let events = try service.fetchAll()

        XCTAssertEqual(events.count, 2)
    }

    func testFetchAll_SortedByTransitionTime() throws {
        let now = Date()

        try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London",
            transitionTime: now
        )

        try service.create(
            previousTimezone: "Europe/London",
            newTimezone: "Asia/Tokyo",
            transitionTime: now.addingTimeInterval(-3600)
        )

        let events = try service.fetchAll()

        // Should be sorted descending (most recent first)
        XCTAssertGreaterThan(events[0].transitionTime, events[1].transitionTime)
    }

    func testFetch_ByID() throws {
        let created = try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London"
        )

        let fetched = try service.fetch(id: created.id)

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, created.id)
    }

    func testFetchEvents_DateRange() throws {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let lastWeek = now.addingTimeInterval(-7 * 86400)
        let lastMonth = now.addingTimeInterval(-30 * 86400)

        try service.create(
            previousTimezone: "UTC",
            newTimezone: "America/New_York",
            transitionTime: lastMonth
        )

        try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London",
            transitionTime: lastWeek
        )

        try service.create(
            previousTimezone: "Europe/London",
            newTimezone: "Asia/Tokyo",
            transitionTime: yesterday
        )

        let events = try service.fetchEvents(from: lastWeek, to: now)

        XCTAssertEqual(events.count, 2)
    }

    func testFetchMostRecent() throws {
        let now = Date()

        try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London",
            transitionTime: now.addingTimeInterval(-3600)
        )

        try service.create(
            previousTimezone: "Europe/London",
            newTimezone: "Asia/Tokyo",
            transitionTime: now
        )

        let mostRecent = try service.fetchMostRecent()

        XCTAssertNotNil(mostRecent)
        XCTAssertEqual(mostRecent?.newTimezone, "Asia/Tokyo")
    }

    func testFetchMostRecent_NoEvents() throws {
        let mostRecent = try service.fetchMostRecent()

        XCTAssertNil(mostRecent)
    }

    // MARK: - Update Tests

    func testUpdate_PreviousTimezone() throws {
        let event = try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London"
        )

        try service.update(event, previousTimezone: "America/Los_Angeles")

        XCTAssertEqual(event.previousTimezone, "America/Los_Angeles")
    }

    func testUpdate_NewTimezone() throws {
        let event = try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London"
        )

        try service.update(event, newTimezone: "Asia/Tokyo")

        XCTAssertEqual(event.newTimezone, "Asia/Tokyo")
    }

    func testUpdate_Location() throws {
        let event = try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London"
        )

        try service.update(event, location: "Paris, France")

        XCTAssertEqual(event.location, "Paris, France")
    }

    func testUpdate_Notes() throws {
        let event = try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London"
        )

        try service.update(event, notes: "Updated notes")

        XCTAssertEqual(event.notes, "Updated notes")
    }

    func testUpdate_ValidationFailure() throws {
        let event = try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London"
        )

        XCTAssertThrowsError(try service.update(event, newTimezone: "Invalid/Timezone"))
    }

    // MARK: - Delete Tests

    func testDelete_Success() throws {
        let event = try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London"
        )
        let id = event.id

        try service.delete(event)

        let fetched = try service.fetch(id: id)
        XCTAssertNil(fetched)
    }

    func testDeleteEvents_OlderThan() throws {
        let now = Date()
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: now)!

        try service.create(
            previousTimezone: "UTC",
            newTimezone: "America/New_York",
            transitionTime: twoMonthsAgo
        )

        try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London",
            transitionTime: oneMonthAgo
        )

        try service.create(
            previousTimezone: "Europe/London",
            newTimezone: "Asia/Tokyo",
            transitionTime: now
        )

        try service.deleteEvents(olderThan: oneMonthAgo)

        let remaining = try service.fetchAll()
        XCTAssertEqual(remaining.count, 2)
    }

    // MARK: - Dose Association Tests

    func testAssociateDoses() throws {
        let event = try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London"
        )

        // Create test doses
        let medication = Medication(context: persistenceController.viewContext)
        medication.name = "Test Med"
        medication.dosageAmount = 10
        medication.dosageUnit = "mg"
        medication.startDate = Date()

        let schedule = Schedule(context: persistenceController.viewContext)
        schedule.medication = medication
        schedule.timeOfDay = Date()

        let dose1 = DoseHistory(context: persistenceController.viewContext)
        dose1.schedule = schedule
        dose1.scheduledTime = Date()

        let dose2 = DoseHistory(context: persistenceController.viewContext)
        dose2.schedule = schedule
        dose2.scheduledTime = Date()

        try service.associateDoses(with: event, doses: [dose1, dose2])

        XCTAssertEqual(dose1.timezoneEvent, event)
        XCTAssertEqual(dose2.timezoneEvent, event)
        XCTAssertEqual(event.affectedDoseCount, 2)
    }

    func testAutoAssociateDoses() throws {
        let now = Date()

        // Create event
        let event = try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "Europe/London",
            transitionTime: now
        )

        // Create doses around transition time
        let doseService = DoseHistoryService(persistenceController: persistenceController)

        let medication = Medication(context: persistenceController.viewContext)
        medication.name = "Test Med"
        medication.dosageAmount = 10
        medication.dosageUnit = "mg"
        medication.startDate = Date()

        let schedule = Schedule(context: persistenceController.viewContext)
        schedule.medication = medication
        schedule.timeOfDay = Date()
        try persistenceController.saveViewContext()

        // Dose within 24 hours before transition
        try doseService.create(
            for: schedule,
            scheduledTime: now.addingTimeInterval(-12 * 3600)
        )

        // Dose within 24 hours after transition
        try doseService.create(
            for: schedule,
            scheduledTime: now.addingTimeInterval(12 * 3600)
        )

        // Dose outside window
        try doseService.create(
            for: schedule,
            scheduledTime: now.addingTimeInterval(-48 * 3600)
        )

        try service.autoAssociateDoses(with: event)

        XCTAssertEqual(event.affectedDoseCount, 2)
    }

    // MARK: - Statistics Tests

    func testCount() throws {
        try service.create(previousTimezone: "UTC", newTimezone: "America/New_York")
        try service.create(previousTimezone: "America/New_York", newTimezone: "Europe/London")

        let count = try service.count()

        XCTAssertEqual(count, 2)
    }

    // MARK: - Edge Cases

    func testCreate_DateLineCrossing() throws {
        let event = try service.create(
            previousTimezone: "Pacific/Auckland",  // UTC+12
            newTimezone: "Pacific/Midway"          // UTC-11
        )

        XCTAssertLessThan(event.timeDifferenceHours, -20)
    }

    func testCreate_ReverseDirectionTimezone() throws {
        let event = try service.create(
            previousTimezone: "Pacific/Midway",    // UTC-11
            newTimezone: "Pacific/Auckland"        // UTC+12
        )

        XCTAssertGreaterThan(event.timeDifferenceHours, 20)
    }

    func testCreate_SmallTimezoneChange() throws {
        let event = try service.create(
            previousTimezone: "America/New_York",  // UTC-5
            newTimezone: "America/Chicago"         // UTC-6
        )

        XCTAssertEqual(event.timeDifferenceHours, -1)
    }

    func testCreate_SameOffsetDifferentZones() throws {
        let event = try service.create(
            previousTimezone: "America/New_York",
            newTimezone: "America/Detroit"  // Same offset as NYC
        )

        // Should be valid even though offsets are the same
        XCTAssertNotNil(event)
    }

    func testFetchEvents_LongTimeRange() throws {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -2, to: now)!

        // Create events throughout the time range
        for month in 0..<24 {
            let date = Calendar.current.date(byAdding: .month, value: -month, to: now)!
            try service.create(
                previousTimezone: "UTC",
                newTimezone: "America/New_York",
                transitionTime: date
            )
        }

        let events = try service.fetchEvents(from: startDate, to: now)

        XCTAssertEqual(events.count, 24)
    }

    func testCreate_WithUnicodeLocation() throws {
        let event = try service.create(
            previousTimezone: "Asia/Tokyo",
            newTimezone: "America/New_York",
            location: "东京 → NYC 🛫"
        )

        XCTAssertEqual(event.location, "东京 → NYC 🛫")
    }

    // MARK: - Concurrency Tests

    func testConcurrentCreates() throws {
        let expectation = self.expectation(description: "Concurrent creates")
        expectation.expectedFulfillmentCount = 5

        let backgroundContext = persistenceController.newBackgroundContext()

        let timezones = [
            ("UTC", "America/New_York"),
            ("America/New_York", "Europe/London"),
            ("Europe/London", "Asia/Tokyo"),
            ("Asia/Tokyo", "Australia/Sydney"),
            ("Australia/Sydney", "Pacific/Auckland")
        ]

        for (previous, new) in timezones {
            backgroundContext.perform {
                do {
                    _ = try self.service.create(
                        previousTimezone: previous,
                        newTimezone: new,
                        in: backgroundContext
                    )
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to create event: \(error)")
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)

        let events = try service.fetchAll()
        XCTAssertEqual(events.count, 5)
    }
}
