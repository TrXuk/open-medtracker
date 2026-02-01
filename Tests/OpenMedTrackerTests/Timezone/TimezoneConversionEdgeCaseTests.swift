//
//  TimezoneConversionEdgeCaseTests.swift
//  OpenMedTrackerTests
//
//  Advanced timezone conversion tests including DST and date line crossing
//

import XCTest
@testable import OpenMedTracker

final class TimezoneConversionEdgeCaseTests: XCTestCase {

    var manager: TimezoneManager!

    override func setUp() {
        super.setUp()
        manager = TimezoneManager.shared
    }

    override func tearDown() {
        // Reset to UTC for other tests
        manager.setReferenceTimezone(TimeZone(identifier: "UTC")!)
        super.tearDown()
    }

    // MARK: - DST Transition Tests

    func testDST_SpringForward_NewYork() {
        // Test DST transition in New York (spring forward - 2:00 AM becomes 3:00 AM)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 3  // March
        components.day = 10   // Second Sunday in March 2024
        components.hour = 1   // 1 AM - before DST
        components.minute = 30
        components.timeZone = TimeZone(identifier: "America/New_York")

        guard let beforeDST = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        // Convert to UTC and back
        manager.setReferenceTimezone(TimeZone(identifier: "America/New_York")!)
        let utcComponents = manager.convertReferenceToUTC(calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .timeZone],
            from: beforeDST
        ))

        XCTAssertNotNil(utcComponents)

        // After DST (3:30 AM)
        components.hour = 3
        components.minute = 30
        guard let afterDST = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        let afterComponents = manager.convertReferenceToUTC(calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .timeZone],
            from: afterDST
        ))

        XCTAssertNotNil(afterComponents)
    }

    func testDST_FallBack_NewYork() {
        // Test DST transition in New York (fall back - 2:00 AM becomes 1:00 AM)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 11  // November
        components.day = 3     // First Sunday in November 2024
        components.hour = 0    // Midnight
        components.minute = 30
        components.timeZone = TimeZone(identifier: "America/New_York")

        guard let beforeDST = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        manager.setReferenceTimezone(TimeZone(identifier: "America/New_York")!)
        let beforeUTC = manager.convertReferenceToUTC(calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .timeZone],
            from: beforeDST
        ))

        XCTAssertNotNil(beforeUTC)

        // After fall back
        components.hour = 3
        guard let afterDST = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        let afterUTC = manager.convertReferenceToUTC(calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .timeZone],
            from: afterDST
        ))

        XCTAssertNotNil(afterUTC)
    }

    func testDST_London_SpringForward() {
        // London: Last Sunday in March, 1:00 AM becomes 2:00 AM
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 3   // March
        components.day = 31    // Last Sunday in March 2024
        components.hour = 0    // Before DST
        components.minute = 30
        components.timeZone = TimeZone(identifier: "Europe/London")

        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        manager.setReferenceTimezone(TimeZone(identifier: "Europe/London")!)
        let utcDate = manager.convertReferenceToUTC(calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .timeZone],
            from: date
        ))

        XCTAssertNotNil(utcDate)
    }

    func testDST_SydneyAustralia() {
        // Southern hemisphere - DST in opposite direction
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 10  // October (spring in southern hemisphere)
        components.day = 6     // First Sunday in October 2024
        components.hour = 1
        components.minute = 30
        components.timeZone = TimeZone(identifier: "Australia/Sydney")

        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        manager.setReferenceTimezone(TimeZone(identifier: "Australia/Sydney")!)
        let utcDate = manager.convertReferenceToUTC(calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .timeZone],
            from: date
        ))

        XCTAssertNotNil(utcDate)
    }

    func testDST_NonObservingTimezone() {
        // Test timezone that doesn't observe DST (Arizona)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 10  // When most of US springs forward
        components.hour = 2
        components.minute = 0
        components.timeZone = TimeZone(identifier: "America/Phoenix")

        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        manager.setReferenceTimezone(TimeZone(identifier: "America/Phoenix")!)
        let utcDate = manager.convertReferenceToUTC(calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .timeZone],
            from: date
        ))

        XCTAssertNotNil(utcDate)

        // Offset should remain consistent throughout the year
        let summerOffset = TimeZone(identifier: "America/Phoenix")!.secondsFromGMT(for: date)

        components.month = 11
        guard let winterDate = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        let winterOffset = TimeZone(identifier: "America/Phoenix")!.secondsFromGMT(for: winterDate)

        XCTAssertEqual(summerOffset, winterOffset, "Arizona should have consistent offset year-round")
    }

    // MARK: - Date Line Crossing Tests

    func testDateLineCrossing_WestToEast_TokyoToLosAngeles() {
        manager.setReferenceTimezone(TimeZone(identifier: "Asia/Tokyo")!)

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 14
        components.minute = 0
        components.timeZone = TimeZone(identifier: "Asia/Tokyo")

        guard let tokyoTime = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        // Convert to LA time
        var laCalendar = calendar
        laCalendar.timeZone = TimeZone(identifier: "America/Los_Angeles")

        let laComponents = laCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: tokyoTime
        )

        // LA should be previous day
        XCTAssertEqual(laComponents.day, 14)
    }

    func testDateLineCrossing_EastToWest_LosAngelesToTokyo() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 22  // 10 PM
        components.minute = 0
        components.timeZone = TimeZone(identifier: "America/Los_Angeles")

        guard let laTime = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        var tokyoCalendar = calendar
        tokyoCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo")

        let tokyoComponents = tokyoCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: laTime
        )

        // Tokyo should be next day
        XCTAssertEqual(tokyoComponents.day, 16)
    }

    func testDateLineCrossing_FijiToSamoa() {
        // Fiji (UTC+12) to Samoa (UTC-11) - crosses date line
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 12
        components.minute = 0
        components.timeZone = TimeZone(identifier: "Pacific/Fiji")

        guard let fijiTime = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        var samoaCalendar = calendar
        samoaCalendar.timeZone = TimeZone(identifier: "Pacific/Apia")  // Samoa

        let samoaComponents = samoaCalendar.dateComponents(
            [.year, .month, .day, .hour],
            from: fijiTime
        )

        // Should be previous day in Samoa
        XCTAssertLessThan(samoaComponents.day!, 15)
    }

    func testDateLineCrossing_NewZealandToHawaii() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 8
        components.minute = 0
        components.timeZone = TimeZone(identifier: "Pacific/Auckland")

        guard let nzTime = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        var hawaiiCalendar = calendar
        hawaiiCalendar.timeZone = TimeZone(identifier: "Pacific/Honolulu")

        let hawaiiComponents = hawaiiCalendar.dateComponents(
            [.year, .month, .day, .hour],
            from: nzTime
        )

        // Hawaii should be previous day
        XCTAssertEqual(hawaiiComponents.day, 14)
    }

    // MARK: - Complex Scenarios

    func testRoundTrip_AcrossDateLine_MaintainsAccuracy() {
        manager.setReferenceTimezone(TimeZone(identifier: "Pacific/Auckland")!)

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 45
        components.timeZone = TimeZone(identifier: "Pacific/Auckland")

        guard let originalDate = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        // Convert to UTC
        guard let utcDate = manager.convertReferenceToUTC(components) else {
            XCTFail("Failed to convert to UTC")
            return
        }

        // Convert back to reference
        let roundTripComponents = manager.convertUTCToReference(utcDate)

        XCTAssertEqual(roundTripComponents.year, components.year)
        XCTAssertEqual(roundTripComponents.month, components.month)
        XCTAssertEqual(roundTripComponents.day, components.day)
        XCTAssertEqual(roundTripComponents.hour, components.hour)
        XCTAssertEqual(roundTripComponents.minute, components.minute)
    }

    func testMultipleTimezoneJourney() {
        // Simulate a journey: NYC → London → Tokyo → Sydney
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 9  // 9 AM
        components.minute = 0
        components.timeZone = TimeZone(identifier: "America/New_York")

        guard let nycTime = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        // Convert to each timezone
        let timezones = [
            "Europe/London",
            "Asia/Tokyo",
            "Australia/Sydney"
        ]

        var previousTime = nycTime

        for tzIdentifier in timezones {
            var tzCalendar = calendar
            tzCalendar.timeZone = TimeZone(identifier: tzIdentifier)

            let tzComponents = tzCalendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: previousTime
            )

            XCTAssertNotNil(tzComponents.year)
            XCTAssertNotNil(tzComponents.hour)

            previousTime = tzCalendar.date(from: tzComponents) ?? previousTime
        }
    }

    func testDST_DuringFlight_CrossingMultipleTimezones() {
        // Test a flight that crosses timezones during DST transition
        let calendar = Calendar.current

        // Departure: NYC on DST transition day
        var departureComponents = DateComponents()
        departureComponents.year = 2024
        departureComponents.month = 3
        departureComponents.day = 10
        departureComponents.hour = 1  // Before DST
        departureComponents.minute = 30
        departureComponents.timeZone = TimeZone(identifier: "America/New_York")

        guard let departureTime = calendar.date(from: departureComponents) else {
            XCTFail("Failed to create date")
            return
        }

        // Arrival: 8 hours later in London
        let arrivalTime = departureTime.addingTimeInterval(8 * 3600)

        var londonCalendar = calendar
        londonCalendar.timeZone = TimeZone(identifier: "Europe/London")

        let arrivalComponents = londonCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: arrivalTime
        )

        XCTAssertNotNil(arrivalComponents.hour)
    }

    // MARK: - Edge Cases

    func testLeapYear_February29() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024  // Leap year
        components.month = 2
        components.day = 29
        components.hour = 12
        components.minute = 0
        components.timeZone = TimeZone(identifier: "UTC")

        guard let leapDayDate = calendar.date(from: components) else {
            XCTFail("Failed to create leap day date")
            return
        }

        manager.setReferenceTimezone(TimeZone(identifier: "America/New_York")!)
        let convertedComponents = manager.convertUTCToReference(leapDayDate)

        XCTAssertEqual(convertedComponents.year, 2024)
        XCTAssertEqual(convertedComponents.month, 2)
        XCTAssertEqual(convertedComponents.day, 29)
    }

    func testYearBoundary_NewYearsEve() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 31
        components.hour = 23
        components.minute = 59
        components.timeZone = TimeZone(identifier: "Pacific/Auckland")

        guard let nzTime = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        // Convert to Hawaii time
        var hawaiiCalendar = calendar
        hawaiiCalendar.timeZone = TimeZone(identifier: "Pacific/Honolulu")

        let hawaiiComponents = hawaiiCalendar.dateComponents(
            [.year, .month, .day, .hour],
            from: nzTime
        )

        // Should still be in 2024 in Hawaii
        XCTAssertEqual(hawaiiComponents.year, 2024)
    }

    func testExtremeLongitudeTimezones() {
        // Test extreme east and west timezones
        let extremeEast = TimeZone(identifier: "Pacific/Kiritimati")!  // UTC+14
        let extremeWest = TimeZone(identifier: "Pacific/Niue")!         // UTC-11

        let offsetDifference = extremeEast.secondsFromGMT() - extremeWest.secondsFromGMT()
        let hourDifference = offsetDifference / 3600

        // Should be 25 hours apart
        XCTAssertEqual(hourDifference, 25)
    }

    func testTimezone_WithFractionalOffset() {
        // Test timezones with fractional offsets (e.g., India UTC+5:30)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 12
        components.minute = 0
        components.timeZone = TimeZone(identifier: "Asia/Kolkata")

        guard let indiaTime = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(identifier: "UTC")

        let utcComponents = utcCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: indiaTime
        )

        // UTC should be 5.5 hours behind
        XCTAssertEqual(utcComponents.hour, 6)
        XCTAssertEqual(utcComponents.minute, 30)
    }

    func testTimezone_Nepal_UnusualOffset() {
        // Nepal is UTC+5:45
        let nepalTZ = TimeZone(identifier: "Asia/Kathmandu")!
        let offset = nepalTZ.secondsFromGMT()
        let hours = offset / 3600
        let minutes = (offset % 3600) / 60

        XCTAssertEqual(hours, 5)
        XCTAssertEqual(minutes, 45)
    }

    // MARK: - Medication Scheduling Edge Cases

    func testMedicationSchedule_DuringDSTTransition() {
        // Test medication scheduled at 2:30 AM on DST spring forward day
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 10
        components.hour = 2   // This hour doesn't exist due to DST
        components.minute = 30
        components.timeZone = TimeZone(identifier: "America/New_York")

        // The system should handle this gracefully
        let date = calendar.date(from: components)

        // Date might be nil or adjusted to 3:30 AM
        if let date = date {
            let adjustedComponents = calendar.dateComponents(
                [.hour, .minute],
                from: date
            )
            // Hour should be adjusted to 3
            XCTAssertEqual(adjustedComponents.hour, 3)
        }
    }

    func testMedicationSchedule_DuringFallBackDST() {
        // Test medication scheduled at 1:30 AM on DST fall back day
        // This time occurs twice!
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 11
        components.day = 3
        components.hour = 1
        components.minute = 30
        components.timeZone = TimeZone(identifier: "America/New_York")

        let date = calendar.date(from: components)

        XCTAssertNotNil(date)
    }
}
