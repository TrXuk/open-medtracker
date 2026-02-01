//
//  TimezoneEventTests.swift
//  OpenMedTrackerTests
//
//  Unit tests for TimezoneEvent Core Data model
//

import XCTest
import CoreData
@testable import OpenMedTracker

final class TimezoneEventTests: XCTestCase {

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

    func testTimezoneEventInitialization() {
        let event = TimezoneEvent(context: context)

        XCTAssertNotNil(event.id)
        XCTAssertNotNil(event.createdAt)
        XCTAssertEqual(event.newTimezone, TimeZone.current.identifier)
    }

    // MARK: - Computed Properties Tests

    func testPreviousTimezoneObject() {
        let event = createTestEvent(
            from: "America/New_York",
            to: "Europe/London"
        )

        XCTAssertNotNil(event.previousTimezoneObject)
        XCTAssertEqual(event.previousTimezoneObject?.identifier, "America/New_York")
    }

    func testNewTimezoneObject() {
        let event = createTestEvent(
            from: "America/New_York",
            to: "Europe/London"
        )

        XCTAssertNotNil(event.newTimezoneObject)
        XCTAssertEqual(event.newTimezoneObject?.identifier, "Europe/London")
    }

    func testPreviousTimezoneObject_Invalid() {
        let event = TimezoneEvent(context: context)
        event.previousTimezone = "Invalid/Timezone"

        XCTAssertNil(event.previousTimezoneObject)
    }

    func testTimeDifferenceHours_EastToWest() {
        let event = createTestEvent(
            from: "America/New_York",  // UTC-5
            to: "America/Los_Angeles"  // UTC-8
        )

        XCTAssertEqual(event.timeDifferenceHours, -3)
    }

    func testTimeDifferenceHours_WestToEast() {
        let event = createTestEvent(
            from: "America/Los_Angeles",  // UTC-8
            to: "America/New_York"        // UTC-5
        )

        XCTAssertEqual(event.timeDifferenceHours, 3)
    }

    func testTimeDifferenceHours_AcrossDateline() {
        let event = createTestEvent(
            from: "Pacific/Auckland",     // UTC+12
            to: "America/Los_Angeles"     // UTC-8
        )

        // Should be -20 hours (going west across date line)
        XCTAssertLessThan(event.timeDifferenceHours, -15)
    }

    func testFormattedTimeDifference_Positive() {
        let event = createTestEvent(
            from: "America/Los_Angeles",
            to: "America/New_York"
        )

        let formatted = event.formattedTimeDifference
        XCTAssertTrue(formatted.contains("+"))
        XCTAssertTrue(formatted.contains("hours"))
    }

    func testFormattedTimeDifference_Negative() {
        let event = createTestEvent(
            from: "America/New_York",
            to: "America/Los_Angeles"
        )

        let formatted = event.formattedTimeDifference
        XCTAssertTrue(formatted.contains("-"))
        XCTAssertTrue(formatted.contains("hours"))
    }

    func testChangeDescription() {
        let event = createTestEvent(
            from: "America/New_York",
            to: "Europe/London"
        )

        let description = event.changeDescription
        XCTAssertFalse(description.isEmpty)
        XCTAssertTrue(description.contains("→"))
        XCTAssertTrue(description.contains("hours"))
    }

    func testFormattedTransitionTime() {
        let event = createTestEvent(
            from: "America/New_York",
            to: "Europe/London"
        )

        let formatted = event.formattedTransitionTime
        XCTAssertFalse(formatted.isEmpty)
    }

    func testAffectedDoseCount() {
        let event = createTestEvent(
            from: "America/New_York",
            to: "Europe/London"
        )

        XCTAssertEqual(event.affectedDoseCount, 0)

        // Add some doses
        let medication = Medication(context: context)
        medication.name = "Test Med"
        medication.dosageAmount = 10
        medication.dosageUnit = "mg"
        medication.startDate = Date()

        let schedule = Schedule(context: context)
        schedule.medication = medication
        schedule.timeOfDay = Date()

        let dose1 = DoseHistory(context: context)
        dose1.schedule = schedule
        dose1.scheduledTime = Date()
        dose1.timezoneEvent = event

        let dose2 = DoseHistory(context: context)
        dose2.schedule = schedule
        dose2.scheduledTime = Date()
        dose2.timezoneEvent = event

        XCTAssertEqual(event.affectedDoseCount, 2)
    }

    func testSortedAffectedDoses() {
        let event = createTestEvent(
            from: "America/New_York",
            to: "Europe/London"
        )

        let medication = Medication(context: context)
        medication.name = "Test Med"
        medication.dosageAmount = 10
        medication.dosageUnit = "mg"
        medication.startDate = Date()

        let schedule = Schedule(context: context)
        schedule.medication = medication
        schedule.timeOfDay = Date()

        let dose1 = DoseHistory(context: context)
        dose1.schedule = schedule
        dose1.scheduledTime = Date().addingTimeInterval(3600)
        dose1.timezoneEvent = event

        let dose2 = DoseHistory(context: context)
        dose2.schedule = schedule
        dose2.scheduledTime = Date()
        dose2.timezoneEvent = event

        let sorted = event.sortedAffectedDoses
        XCTAssertEqual(sorted.count, 2)
        XCTAssertLessThan(sorted[0].scheduledTime, sorted[1].scheduledTime)
    }

    func testIsForwardChange() {
        let forwardEvent = createTestEvent(
            from: "America/Los_Angeles",
            to: "America/New_York"
        )
        XCTAssertTrue(forwardEvent.isForwardChange)

        let backwardEvent = createTestEvent(
            from: "America/New_York",
            to: "America/Los_Angeles"
        )
        XCTAssertFalse(backwardEvent.isForwardChange)
    }

    func testIsBackwardChange() {
        let backwardEvent = createTestEvent(
            from: "America/New_York",
            to: "America/Los_Angeles"
        )
        XCTAssertTrue(backwardEvent.isBackwardChange)

        let forwardEvent = createTestEvent(
            from: "America/Los_Angeles",
            to: "America/New_York"
        )
        XCTAssertFalse(forwardEvent.isBackwardChange)
    }

    func testChangeMangnitude() {
        let event = createTestEvent(
            from: "America/New_York",
            to: "America/Los_Angeles"
        )

        XCTAssertEqual(event.changeMangnitude, 3)
    }

    // MARK: - Helper Methods Tests

    func testAdjustedTime_BeforeTransition() {
        let event = createTestEvent(
            from: "America/New_York",
            to: "Europe/London"
        )
        event.transitionTime = Date()

        let beforeTime = Date().addingTimeInterval(-3600) // 1 hour before
        let adjusted = event.adjustedTime(for: beforeTime)

        XCTAssertEqual(adjusted, beforeTime)
    }

    func testAdjustedTime_AfterTransition() {
        let event = createTestEvent(
            from: "America/Los_Angeles",
            to: "America/New_York"
        )
        event.transitionTime = Date()

        let afterTime = Date().addingTimeInterval(3600) // 1 hour after
        let adjusted = event.adjustedTime(for: afterTime)

        XCTAssertNotEqual(adjusted, afterTime)
        XCTAssertGreaterThan(adjusted, afterTime)
    }

    func testSimilarTimezones() {
        let similar = TimezoneEvent.similarTimezones(to: "America/New_York")

        XCTAssertFalse(similar.isEmpty)
        // Should include timezones in same offset range
        XCTAssertTrue(similar.contains("America/New_York"))
    }

    func testSimilarTimezones_Invalid() {
        let similar = TimezoneEvent.similarTimezones(to: "Invalid/Timezone")

        XCTAssertTrue(similar.isEmpty)
    }

    func testValidateTimezones_Valid() {
        let event = createTestEvent(
            from: "America/New_York",
            to: "Europe/London"
        )

        XCTAssertTrue(event.validateTimezones())
    }

    func testValidateTimezones_Invalid() {
        let event = TimezoneEvent(context: context)
        event.previousTimezone = "Invalid/Timezone"
        event.newTimezone = "Europe/London"

        XCTAssertFalse(event.validateTimezones())
    }

    // MARK: - DST Edge Cases

    func testTimeDifference_DuringDSTTransition() {
        // Test during DST transition
        let event = TimezoneEvent(context: context)
        event.previousTimezone = "America/New_York"
        event.newTimezone = "America/New_York"

        // March DST transition (spring forward)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 10
        components.hour = 2
        components.timeZone = TimeZone(identifier: "America/New_York")

        if let dstDate = calendar.date(from: components) {
            event.transitionTime = dstDate

            // In this case, same timezone so should be 0
            XCTAssertEqual(event.timeDifferenceHours, 0)
        }
    }

    func testTimeDifference_AcrossDSTBoundary() {
        let event = TimezoneEvent(context: context)
        event.previousTimezone = "America/New_York"
        event.newTimezone = "Europe/London"

        // Set transition during summer (both in DST)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 7
        components.day = 1
        components.hour = 12
        components.timeZone = TimeZone(identifier: "UTC")

        if let summerDate = calendar.date(from: components) {
            event.transitionTime = summerDate
            let summerDiff = event.timeDifferenceHours

            // Set transition during winter (neither in DST)
            components.month = 1
            if let winterDate = calendar.date(from: components) {
                event.transitionTime = winterDate
                let winterDiff = event.timeDifferenceHours

                // The difference should be the same as both zones change DST together
                XCTAssertEqual(summerDiff, winterDiff)
            }
        }
    }

    // MARK: - Date Line Crossing Tests

    func testDateLineCrossing_WestToEast() {
        let event = createTestEvent(
            from: "Pacific/Fiji",         // UTC+12
            to: "Pacific/Midway"          // UTC-11
        )

        // Crossing date line westward should show large negative offset
        XCTAssertLessThan(event.timeDifferenceHours, -20)
    }

    func testDateLineCrossing_EastToWest() {
        let event = createTestEvent(
            from: "Pacific/Midway",       // UTC-11
            to: "Pacific/Fiji"            // UTC+12
        )

        // Crossing date line eastward should show large positive offset
        XCTAssertGreaterThan(event.timeDifferenceHours, 20)
    }

    // MARK: - Helper Methods

    private func createTestEvent(from: String, to: String) -> TimezoneEvent {
        let event = TimezoneEvent(context: context)
        event.previousTimezone = from
        event.newTimezone = to
        event.transitionTime = Date()
        return event
    }
}
