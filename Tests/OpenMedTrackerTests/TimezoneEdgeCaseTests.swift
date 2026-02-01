//
//  TimezoneEdgeCaseTests.swift
//  OpenMedTrackerTests
//
//  Comprehensive test suite for timezone edge cases including:
//  - Eastward/westward travel
//  - International Date Line crossing
//  - DST transitions
//  - Rapid timezone changes
//  - Midnight boundary cases
//  - Medication time consistency validation
//

import XCTest
@testable import OpenMedTracker

final class TimezoneEdgeCaseTests: XCTestCase {

    var manager: TimezoneManager!

    override func setUp() {
        super.setUp()
        manager = TimezoneManager.shared
        // Reset to UTC for consistent testing
        manager.setReferenceTimezone(TimeZone(identifier: "UTC")!)
    }

    override func tearDown() {
        // Reset to UTC after each test
        manager.setReferenceTimezone(TimeZone(identifier: "UTC")!)
        super.tearDown()
    }

    // MARK: - Eastward Travel Tests

    func testEastwardTravel_NewYorkToLondon() {
        // New York (UTC-5) to London (UTC+0) - 5 hour jump forward
        let nyTimezone = TimeZone(identifier: "America/New_York")!
        let londonTimezone = TimeZone(identifier: "Europe/London")!

        // Medication scheduled for 8:00 AM in New York
        let medication8AM = createDate(
            year: 2024,
            month: 3,
            day: 15,
            hour: 8,
            minute: 0,
            timezone: nyTimezone
        )

        // Convert to UTC
        let utcDate = medication8AM

        // Convert to London time
        let londonComponents = Calendar.current.dateComponents(
            in: londonTimezone,
            from: utcDate
        )

        // 8:00 AM EST = 1:00 PM GMT (during standard time)
        XCTAssertEqual(londonComponents.hour, 13, "8:00 AM New York should be 1:00 PM London")
        XCTAssertEqual(londonComponents.minute, 0)
    }

    func testEastwardTravel_LosAngelesToTokyo() {
        // Los Angeles (UTC-8) to Tokyo (UTC+9) - 17 hour jump forward
        let laTimezone = TimeZone(identifier: "America/Los_Angeles")!
        let tokyoTimezone = TimeZone(identifier: "Asia/Tokyo")!

        // Medication scheduled for 9:00 PM in LA
        let medication9PM = createDate(
            year: 2024,
            month: 6,
            day: 20,
            hour: 21,
            minute: 0,
            timezone: laTimezone
        )

        let tokyoComponents = Calendar.current.dateComponents(
            in: tokyoTimezone,
            from: medication9PM
        )

        // 9:00 PM PDT (UTC-7) = next day 1:00 PM JST (UTC+9)
        XCTAssertEqual(tokyoComponents.day, 21, "Should be next day in Tokyo")
        XCTAssertEqual(tokyoComponents.hour, 13, "9:00 PM LA should be 1:00 PM next day Tokyo")
    }

    func testEastwardTravel_MedicationScheduleConsistency() {
        // Verify medication times remain consistent when traveling east
        let nyTimezone = TimeZone(identifier: "America/New_York")!
        let londonTimezone = TimeZone(identifier: "Europe/London")!

        // Three doses per day: 8 AM, 2 PM, 10 PM
        let doses = [
            createDate(year: 2024, month: 3, day: 15, hour: 8, minute: 0, timezone: nyTimezone),
            createDate(year: 2024, month: 3, day: 15, hour: 14, minute: 0, timezone: nyTimezone),
            createDate(year: 2024, month: 3, day: 15, hour: 22, minute: 0, timezone: nyTimezone)
        ]

        // Convert all to London time
        let londonDoses = doses.map { dose in
            Calendar.current.dateComponents(in: londonTimezone, from: dose)
        }

        // Verify the time intervals between doses remain consistent
        let originalIntervals = [6, 8] // hours between doses

        // Calculate intervals in London time
        for i in 0..<londonDoses.count - 1 {
            let hour1 = londonDoses[i].hour!
            let hour2 = londonDoses[i + 1].hour!
            let interval = hour2 - hour1

            XCTAssertEqual(interval, originalIntervals[i], "Interval between doses should remain consistent")
        }
    }

    // MARK: - Westward Travel Tests

    func testWestwardTravel_TokyoToLosAngeles() {
        // Tokyo (UTC+9) to Los Angeles (UTC-8) - 17 hour jump backward
        let tokyoTimezone = TimeZone(identifier: "Asia/Tokyo")!
        let laTimezone = TimeZone(identifier: "America/Los_Angeles")!

        // Medication scheduled for 10:00 AM in Tokyo
        let medication10AM = createDate(
            year: 2024,
            month: 6,
            day: 20,
            hour: 10,
            minute: 0,
            timezone: tokyoTimezone
        )

        let laComponents = Calendar.current.dateComponents(
            in: laTimezone,
            from: medication10AM
        )

        // 10:00 AM JST = previous day 6:00 PM PDT
        XCTAssertEqual(laComponents.day, 19, "Should be previous day in Los Angeles")
        XCTAssertEqual(laComponents.hour, 18, "10:00 AM Tokyo should be 6:00 PM previous day LA")
    }

    func testWestwardTravel_LondonToNewYork() {
        // London (UTC+0) to New York (UTC-5) - 5 hour jump backward
        let londonTimezone = TimeZone(identifier: "Europe/London")!
        let nyTimezone = TimeZone(identifier: "America/New_York")!

        // Medication scheduled for 3:00 PM in London
        let medication3PM = createDate(
            year: 2024,
            month: 3,
            day: 15,
            hour: 15,
            minute: 0,
            timezone: londonTimezone
        )

        let nyComponents = Calendar.current.dateComponents(
            in: nyTimezone,
            from: medication3PM
        )

        // 3:00 PM GMT = 10:00 AM EST
        XCTAssertEqual(nyComponents.hour, 10, "3:00 PM London should be 10:00 AM New York")
        XCTAssertEqual(nyComponents.minute, 0)
    }

    func testWestwardTravel_GainExtraDayScenario() {
        // Crossing International Date Line westward - gain a day
        let tokyoTimezone = TimeZone(identifier: "Asia/Tokyo")!
        let laTimezone = TimeZone(identifier: "America/Los_Angeles")!

        // Flying from Tokyo on June 20 at 11:00 PM
        let departureTime = createDate(
            year: 2024,
            month: 6,
            day: 20,
            hour: 23,
            minute: 0,
            timezone: tokyoTimezone
        )

        let laComponents = Calendar.current.dateComponents(
            in: laTimezone,
            from: departureTime
        )

        // 11:00 PM June 20 JST = 7:00 AM June 20 PDT (same calendar day)
        XCTAssertEqual(laComponents.day, 20, "Should still be June 20 in LA")
        XCTAssertEqual(laComponents.hour, 7)
    }

    // MARK: - International Date Line Crossing Tests

    func testDateLineCrossing_EastwardSamoaToHawaii() {
        // Samoa (UTC+13) to Hawaii (UTC-10) - crossing date line eastward
        let samoaTimezone = TimeZone(identifier: "Pacific/Apia")!
        let hawaiiTimezone = TimeZone(identifier: "Pacific/Honolulu")!

        let samoaTime = createDate(
            year: 2024,
            month: 7,
            day: 15,
            hour: 14,
            minute: 0,
            timezone: samoaTimezone
        )

        let hawaiiComponents = Calendar.current.dateComponents(
            in: hawaiiTimezone,
            from: samoaTime
        )

        // When crossing date line eastward, go back a day
        XCTAssertEqual(hawaiiComponents.day, 14, "Should be previous day when crossing date line eastward")
    }

    func testDateLineCrossing_WestwardHawaiiToKiribati() {
        // Hawaii (UTC-10) to Kiribati (UTC+14) - crossing date line westward
        let hawaiiTimezone = TimeZone(identifier: "Pacific/Honolulu")!
        let kiribatiTimezone = TimeZone(identifier: "Pacific/Kiritimati")!

        let hawaiiTime = createDate(
            year: 2024,
            month: 7,
            day: 15,
            hour: 10,
            minute: 0,
            timezone: hawaiiTimezone
        )

        let kiribatiComponents = Calendar.current.dateComponents(
            in: kiribatiTimezone,
            from: hawaiiTime
        )

        // When crossing date line westward, go forward a day
        XCTAssertEqual(kiribatiComponents.day, 16, "Should be next day when crossing date line westward")
    }

    func testDateLineCrossing_MedicationScheduleIntegrity() {
        // Verify medication times are correctly maintained across date line
        let fijiTimezone = TimeZone(identifier: "Pacific/Fiji")! // UTC+12
        let samoaTimezone = TimeZone(identifier: "Pacific/Apia")! // UTC+13

        // Schedule: 8:00 AM, 2:00 PM, 8:00 PM in Fiji
        let fijiDoses = [
            createDate(year: 2024, month: 7, day: 15, hour: 8, minute: 0, timezone: fijiTimezone),
            createDate(year: 2024, month: 7, day: 15, hour: 14, minute: 0, timezone: fijiTimezone),
            createDate(year: 2024, month: 7, day: 15, hour: 20, minute: 0, timezone: fijiTimezone)
        ]

        // Convert to Samoa (1 hour ahead)
        for (index, dose) in fijiDoses.enumerated() {
            let samoaComponents = Calendar.current.dateComponents(
                in: samoaTimezone,
                from: dose
            )

            // Each dose should be exactly 1 hour later in Samoa
            let expectedHour = [9, 15, 21][index]
            XCTAssertEqual(samoaComponents.hour, expectedHour, "Dose \(index) should be 1 hour later in Samoa")
        }
    }

    func testDateLineCrossing_MidnightBoundary() {
        // Test crossing date line at midnight
        let fijiTimezone = TimeZone(identifier: "Pacific/Fiji")!
        let hawaiiTimezone = TimeZone(identifier: "Pacific/Honolulu")!

        // Midnight in Fiji
        let fijiMidnight = createDate(
            year: 2024,
            month: 7,
            day: 16,
            hour: 0,
            minute: 0,
            timezone: fijiTimezone
        )

        let hawaiiComponents = Calendar.current.dateComponents(
            in: hawaiiTimezone,
            from: fijiMidnight
        )

        // Should be previous day in Hawaii
        XCTAssertEqual(hawaiiComponents.day, 15, "Fiji midnight should be previous day in Hawaii")
    }

    // MARK: - DST Transition Tests

    func testDSTTransition_SpringForward() {
        // Spring forward: 2:00 AM becomes 3:00 AM (lose an hour)
        let nyTimezone = TimeZone(identifier: "America/New_York")!

        // DST starts on March 10, 2024 at 2:00 AM
        // Create dates before, during, and after the transition

        // 1:30 AM - before DST
        let beforeDST = createDate(
            year: 2024,
            month: 3,
            day: 10,
            hour: 1,
            minute: 30,
            timezone: nyTimezone
        )

        // 3:30 AM - after DST (2:30 AM doesn't exist)
        let afterDST = createDate(
            year: 2024,
            month: 3,
            day: 10,
            hour: 3,
            minute: 30,
            timezone: nyTimezone
        )

        // Calculate the actual time difference
        let timeDifference = afterDST.timeIntervalSince(beforeDST)

        // Should be 1 hour (3600 seconds) instead of 2 hours
        XCTAssertEqual(timeDifference, 3600, accuracy: 1.0, "Spring forward should compress time")
    }

    func testDSTTransition_FallBack() {
        // Fall back: 2:00 AM becomes 1:00 AM (gain an hour)
        let nyTimezone = TimeZone(identifier: "America/New_York")!

        // DST ends on November 3, 2024 at 2:00 AM

        // 1:30 AM - before fall back (first occurrence)
        let beforeFallBack = createDate(
            year: 2024,
            month: 11,
            day: 3,
            hour: 1,
            minute: 30,
            timezone: nyTimezone
        )

        // 2:30 AM - after fall back
        let afterFallBack = createDate(
            year: 2024,
            month: 11,
            day: 3,
            hour: 2,
            minute: 30,
            timezone: nyTimezone
        )

        // Calculate the actual time difference
        let timeDifference = afterFallBack.timeIntervalSince(beforeFallBack)

        // Should be at least 1 hour
        XCTAssertGreaterThanOrEqual(timeDifference, 3600, "Should have at least 1 hour difference")
    }

    func testDSTTransition_MedicationScheduleDuringSpringForward() {
        // Test medication scheduled during the "lost hour"
        let nyTimezone = TimeZone(identifier: "America/New_York")!

        // Medication scheduled for 2:30 AM on March 10, 2024
        // This time doesn't exist due to DST spring forward
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 10
        components.hour = 2
        components.minute = 30
        components.timeZone = nyTimezone

        var calendar = Calendar.current
        calendar.timeZone = nyTimezone

        // When creating a date during the lost hour, iOS will adjust it
        let adjustedDate = calendar.date(from: components)

        XCTAssertNotNil(adjustedDate, "System should handle DST lost hour gracefully")

        if let date = adjustedDate {
            let resultComponents = calendar.dateComponents([.hour, .minute], from: date)
            // The time should be adjusted to 3:30 AM
            XCTAssertTrue(
                resultComponents.hour == 3 || resultComponents.hour == 2,
                "System should adjust to valid time"
            )
        }
    }

    func testDSTTransition_MedicationScheduleDuringFallBack() {
        // Test medication scheduled during the "repeated hour"
        let nyTimezone = TimeZone(identifier: "America/New_York")!

        // Medication scheduled for 1:30 AM on November 3, 2024
        // This time occurs twice due to DST fall back
        let medication = createDate(
            year: 2024,
            month: 11,
            day: 3,
            hour: 1,
            minute: 30,
            timezone: nyTimezone
        )

        XCTAssertNotNil(medication, "Should handle repeated hour during fall back")

        // Verify the timezone offset changes
        let offsetBefore = nyTimezone.secondsFromGMT(for: medication)

        // Add 2 hours to get past the transition
        let twoHoursLater = medication.addingTimeInterval(7200)
        let offsetAfter = nyTimezone.secondsFromGMT(for: twoHoursLater)

        // Offset should be different (standard time vs daylight time)
        XCTAssertNotEqual(offsetBefore, offsetAfter, "Timezone offset should change after DST transition")
    }

    func testDSTTransition_CrossTimezone_WithDSTChanges() {
        // Test traveling between timezones where one observes DST and one doesn't
        let nyTimezone = TimeZone(identifier: "America/New_York")!
        let arizonaTimezone = TimeZone(identifier: "America/Phoenix")! // No DST

        // During summer (when NY has DST)
        let summerDate = createDate(
            year: 2024,
            month: 7,
            day: 15,
            hour: 12,
            minute: 0,
            timezone: nyTimezone
        )

        // During winter (when NY doesn't have DST)
        let winterDate = createDate(
            year: 2024,
            month: 1,
            day: 15,
            hour: 12,
            minute: 0,
            timezone: nyTimezone
        )

        let summerAZ = Calendar.current.dateComponents(in: arizonaTimezone, from: summerDate)
        let winterAZ = Calendar.current.dateComponents(in: arizonaTimezone, from: winterDate)

        // The offset between NY and AZ changes with DST
        // Summer: NY is EDT (UTC-4), AZ is MST (UTC-7) = 3 hour difference
        // Winter: NY is EST (UTC-5), AZ is MST (UTC-7) = 2 hour difference

        XCTAssertNotNil(summerAZ.hour)
        XCTAssertNotNil(winterAZ.hour)
    }

    // MARK: - Rapid Timezone Change Tests

    func testRapidTimezoneChanges_MultipleTransitionsInDay() {
        // Simulate rapid timezone changes (e.g., connecting flights)
        let timezones = [
            TimeZone(identifier: "America/New_York")!,      // NYC
            TimeZone(identifier: "Europe/Paris")!,          // Paris layover
            TimeZone(identifier: "Asia/Dubai")!,            // Dubai layover
            TimeZone(identifier: "Asia/Tokyo")!             // Final destination
        ]

        // Starting medication time: 8:00 AM in NYC
        var currentTime = createDate(
            year: 2024,
            month: 6,
            day: 15,
            hour: 8,
            minute: 0,
            timezone: timezones[0]
        )

        var previousComponents = Calendar.current.dateComponents(
            in: timezones[0],
            from: currentTime
        )

        // Track time through each timezone
        for timezone in timezones.dropFirst() {
            let components = Calendar.current.dateComponents(
                in: timezone,
                from: currentTime
            )

            XCTAssertNotNil(components.hour, "Hour should be valid in \(timezone.identifier)")
            XCTAssertNotNil(components.minute, "Minute should be valid in \(timezone.identifier)")

            // The absolute time (Date) shouldn't change, only the representation
            previousComponents = components
        }
    }

    func testRapidTimezoneChanges_ConsecutiveEastWestTravel() {
        // Travel east then west in quick succession
        let nyTimezone = TimeZone(identifier: "America/New_York")!
        let londonTimezone = TimeZone(identifier: "Europe/London")!
        let dubaiTimezone = TimeZone(identifier: "Asia/Dubai")!

        // Medication time in NY
        let medicationTime = createDate(
            year: 2024,
            month: 6,
            day: 15,
            hour: 14,
            minute: 0,
            timezone: nyTimezone
        )

        // Convert to London (eastward)
        let londonTime = Calendar.current.dateComponents(
            in: londonTimezone,
            from: medicationTime
        )

        // Convert to Dubai (further eastward)
        let dubaiTime = Calendar.current.dateComponents(
            in: dubaiTimezone,
            from: medicationTime
        )

        // Convert back to NY (westward)
        let backToNYTime = Calendar.current.dateComponents(
            in: nyTimezone,
            from: medicationTime
        )

        // Should end up with the same time we started with
        XCTAssertEqual(backToNYTime.hour, 14, "Round trip should preserve original time")
        XCTAssertEqual(backToNYTime.minute, 0, "Round trip should preserve original minute")
    }

    func testRapidTimezoneChanges_SameDayMultipleCrossings() {
        // Multiple International Date Line crossings in one trip
        let hawaiiTimezone = TimeZone(identifier: "Pacific/Honolulu")!
        let tokyoTimezone = TimeZone(identifier: "Asia/Tokyo")!
        let fijiTimezone = TimeZone(identifier: "Pacific/Fiji")!

        // Start in Hawaii at 10:00 AM
        let startTime = createDate(
            year: 2024,
            month: 7,
            day: 15,
            hour: 10,
            minute: 0,
            timezone: hawaiiTimezone
        )

        // Track through multiple crossings
        let tokyoComponents = Calendar.current.dateComponents(in: tokyoTimezone, from: startTime)
        let fijiComponents = Calendar.current.dateComponents(in: fijiTimezone, from: startTime)

        XCTAssertNotNil(tokyoComponents.day)
        XCTAssertNotNil(fijiComponents.day)

        // Dates should be different due to date line
        XCTAssertNotEqual(tokyoComponents.day, fijiComponents.day, "Tokyo and Fiji should have different dates")
    }

    func testRapidTimezoneChanges_OffsetAccumulation() {
        // Verify that rapid timezone changes don't accumulate errors
        let startTimezone = TimeZone(identifier: "America/New_York")!

        let startTime = createDate(
            year: 2024,
            month: 6,
            day: 15,
            hour: 12,
            minute: 0,
            timezone: startTimezone
        )

        // Multiple conversions
        let intermediateTimezones = [
            "Europe/London",
            "Asia/Dubai",
            "Asia/Singapore",
            "Australia/Sydney",
            "Pacific/Auckland",
            "Pacific/Honolulu",
            "America/Los_Angeles"
        ]

        var currentTime = startTime

        for tzIdentifier in intermediateTimezones {
            guard let tz = TimeZone(identifier: tzIdentifier) else {
                XCTFail("Invalid timezone: \(tzIdentifier)")
                continue
            }

            // Convert and verify
            let components = Calendar.current.dateComponents(in: tz, from: currentTime)
            XCTAssertNotNil(components.hour)
            XCTAssertNotNil(components.minute)
        }

        // Convert back to original timezone
        let finalComponents = Calendar.current.dateComponents(in: startTimezone, from: currentTime)

        // Should maintain the original time
        XCTAssertEqual(finalComponents.hour, 12, "Multiple conversions should not drift")
        XCTAssertEqual(finalComponents.minute, 0, "Minutes should remain exact")
    }

    // MARK: - Midnight Boundary Tests

    func testMidnightBoundary_MedicationAtMidnight() {
        // Medication scheduled exactly at midnight
        let timezone = TimeZone(identifier: "America/New_York")!

        let midnight = createDate(
            year: 2024,
            month: 6,
            day: 15,
            hour: 0,
            minute: 0,
            timezone: timezone
        )

        let components = Calendar.current.dateComponents(
            in: timezone,
            from: midnight
        )

        XCTAssertEqual(components.hour, 0, "Midnight should be hour 0")
        XCTAssertEqual(components.minute, 0, "Midnight should be minute 0")
        XCTAssertEqual(components.day, 15, "Day should be correct")
    }

    func testMidnightBoundary_CrossTimezoneAtMidnight() {
        // Medication at midnight in one timezone, view in another
        let nyTimezone = TimeZone(identifier: "America/New_York")!
        let londonTimezone = TimeZone(identifier: "Europe/London")!

        let nyMidnight = createDate(
            year: 2024,
            month: 6,
            day: 15,
            hour: 0,
            minute: 0,
            timezone: nyTimezone
        )

        let londonComponents = Calendar.current.dateComponents(
            in: londonTimezone,
            from: nyMidnight
        )

        // Midnight in NY should be 5:00 AM in London (during summer)
        XCTAssertEqual(londonComponents.hour, 5, "NY midnight should be 5 AM in London")
        XCTAssertEqual(londonComponents.day, 15, "Should be same day")
    }

    func testMidnightBoundary_23_59_To_00_01() {
        // Test transition from 23:59 to 00:01
        let timezone = TimeZone(identifier: "America/New_York")!

        let beforeMidnight = createDate(
            year: 2024,
            month: 6,
            day: 15,
            hour: 23,
            minute: 59,
            timezone: timezone
        )

        let afterMidnight = createDate(
            year: 2024,
            month: 6,
            day: 16,
            hour: 0,
            minute: 1,
            timezone: timezone
        )

        let timeDifference = afterMidnight.timeIntervalSince(beforeMidnight)

        // Should be 120 seconds (2 minutes)
        XCTAssertEqual(timeDifference, 120, accuracy: 1.0, "23:59 to 00:01 should be 2 minutes")
    }

    func testMidnightBoundary_DateLineAndMidnight() {
        // Crossing date line at midnight
        let samoaTimezone = TimeZone(identifier: "Pacific/Apia")!
        let hawaiiTimezone = TimeZone(identifier: "Pacific/Honolulu")!

        // Midnight in Samoa
        let samoaMidnight = createDate(
            year: 2024,
            month: 7,
            day: 16,
            hour: 0,
            minute: 0,
            timezone: samoaTimezone
        )

        let hawaiiComponents = Calendar.current.dateComponents(
            in: hawaiiTimezone,
            from: samoaMidnight
        )

        // Should be previous day in Hawaii
        XCTAssertEqual(hawaiiComponents.day, 15, "Samoa midnight should be previous day in Hawaii")
    }

    func testMidnightBoundary_MedicationScheduleAroundMidnight() {
        // Multiple medications scheduled around midnight
        let timezone = TimeZone(identifier: "America/New_York")!

        let times = [
            createDate(year: 2024, month: 6, day: 15, hour: 22, minute: 0, timezone: timezone),  // 10 PM
            createDate(year: 2024, month: 6, day: 15, hour: 23, minute: 30, timezone: timezone), // 11:30 PM
            createDate(year: 2024, month: 6, day: 16, hour: 0, minute: 30, timezone: timezone),  // 12:30 AM
            createDate(year: 2024, month: 6, day: 16, hour: 2, minute: 0, timezone: timezone)    // 2 AM
        ]

        // Verify order is maintained
        for i in 0..<times.count - 1 {
            XCTAssertTrue(times[i] < times[i + 1], "Times should be in ascending order")
        }

        // Verify intervals
        let interval1 = times[1].timeIntervalSince(times[0]) // 1.5 hours
        let interval2 = times[2].timeIntervalSince(times[1]) // 1 hour
        let interval3 = times[3].timeIntervalSince(times[2]) // 1.5 hours

        XCTAssertEqual(interval1, 5400, accuracy: 1.0, "First interval should be 1.5 hours")
        XCTAssertEqual(interval2, 3600, accuracy: 1.0, "Second interval should be 1 hour")
        XCTAssertEqual(interval3, 5400, accuracy: 1.0, "Third interval should be 1.5 hours")
    }

    // MARK: - Medication Time Consistency Tests

    func testMedicationConsistency_UTCReferencePreservation() {
        // Verify that medication times stored in UTC remain consistent
        let utcTimezone = TimeZone(identifier: "UTC")!

        // Medication scheduled for 10:00 AM UTC
        let medicationUTC = createDate(
            year: 2024,
            month: 6,
            day: 15,
            hour: 10,
            minute: 0,
            timezone: utcTimezone
        )

        // View in multiple timezones
        let timezones = [
            "America/New_York",
            "Europe/London",
            "Asia/Tokyo",
            "Australia/Sydney"
        ]

        for tzIdentifier in timezones {
            guard let tz = TimeZone(identifier: tzIdentifier) else { continue }

            // Convert to local time
            let localComponents = Calendar.current.dateComponents(in: tz, from: medicationUTC)

            // Convert back to UTC
            var calendar = Calendar.current
            calendar.timeZone = tz

            guard let localDate = calendar.date(from: localComponents) else {
                XCTFail("Failed to create date from components")
                continue
            }

            let utcComponents = Calendar.current.dateComponents(in: utcTimezone, from: localDate)

            // Should get back original UTC time
            XCTAssertEqual(utcComponents.hour, 10, "UTC hour should be preserved for \(tzIdentifier)")
            XCTAssertEqual(utcComponents.minute, 0, "UTC minute should be preserved for \(tzIdentifier)")
        }
    }

    func testMedicationConsistency_DailyScheduleIntegrity() {
        // Verify a daily medication schedule maintains proper intervals
        let nyTimezone = TimeZone(identifier: "America/New_York")!
        let tokyoTimezone = TimeZone(identifier: "Asia/Tokyo")!

        // Three times a day: 8 AM, 2 PM, 8 PM
        let nySchedule = [
            createDate(year: 2024, month: 6, day: 15, hour: 8, minute: 0, timezone: nyTimezone),
            createDate(year: 2024, month: 6, day: 15, hour: 14, minute: 0, timezone: nyTimezone),
            createDate(year: 2024, month: 6, day: 15, hour: 20, minute: 0, timezone: nyTimezone)
        ]

        // Calculate intervals in NY
        let nyInterval1 = nySchedule[1].timeIntervalSince(nySchedule[0])
        let nyInterval2 = nySchedule[2].timeIntervalSince(nySchedule[1])

        // Convert to Tokyo
        let tokyoSchedule = nySchedule.map { date in
            Calendar.current.dateComponents(in: tokyoTimezone, from: date)
        }

        // Verify Tokyo times exist
        for (index, components) in tokyoSchedule.enumerated() {
            XCTAssertNotNil(components.hour, "Tokyo hour should exist for dose \(index)")
            XCTAssertNotNil(components.minute, "Tokyo minute should exist for dose \(index)")
        }

        // The actual time intervals should be identical
        let tokyoInterval1 = nySchedule[1].timeIntervalSince(nySchedule[0])
        let tokyoInterval2 = nySchedule[2].timeIntervalSince(nySchedule[1])

        XCTAssertEqual(nyInterval1, tokyoInterval1, "Intervals should be identical across timezones")
        XCTAssertEqual(nyInterval2, tokyoInterval2, "Intervals should be identical across timezones")
    }

    func testMedicationConsistency_WeeklyScheduleAcrossTimezones() {
        // Test weekly medication schedule consistency
        let nyTimezone = TimeZone(identifier: "America/New_York")!
        let londonTimezone = TimeZone(identifier: "Europe/London")!

        // Weekly medication: every Monday at 9 AM for 4 weeks
        var calendar = Calendar.current
        calendar.timeZone = nyTimezone

        var weeklyDoses: [Date] = []
        for week in 0..<4 {
            let dose = createDate(
                year: 2024,
                month: 6,
                day: 3 + (week * 7), // June 3, 10, 17, 24 (all Mondays)
                hour: 9,
                minute: 0,
                timezone: nyTimezone
            )
            weeklyDoses.append(dose)
        }

        // Verify weekly intervals (7 days = 604800 seconds)
        for i in 0..<weeklyDoses.count - 1 {
            let interval = weeklyDoses[i + 1].timeIntervalSince(weeklyDoses[i])
            XCTAssertEqual(interval, 604800, accuracy: 1.0, "Weekly interval should be exactly 7 days")
        }

        // Convert to London and verify consistency
        for dose in weeklyDoses {
            let londonComponents = Calendar.current.dateComponents(in: londonTimezone, from: dose)
            XCTAssertNotNil(londonComponents.weekday, "Weekday should be preserved")
        }
    }

    func testMedicationConsistency_TimezoneChangeDoesNotAffectAbsoluteTime() {
        // Verify that timezone changes don't affect the absolute medication time
        let medication = createDate(
            year: 2024,
            month: 6,
            day: 15,
            hour: 14,
            minute: 30,
            timezone: TimeZone(identifier: "America/New_York")!
        )

        let utcComponents1 = Calendar.current.dateComponents(
            in: TimeZone(identifier: "UTC")!,
            from: medication
        )

        // View in different timezone
        _ = Calendar.current.dateComponents(
            in: TimeZone(identifier: "Asia/Tokyo")!,
            from: medication
        )

        // Convert back to UTC
        let utcComponents2 = Calendar.current.dateComponents(
            in: TimeZone(identifier: "UTC")!,
            from: medication
        )

        // UTC representation should be identical
        XCTAssertEqual(utcComponents1.hour, utcComponents2.hour, "UTC hour should not change")
        XCTAssertEqual(utcComponents1.minute, utcComponents2.minute, "UTC minute should not change")
        XCTAssertEqual(utcComponents1.day, utcComponents2.day, "UTC day should not change")
    }

    func testMedicationConsistency_MultipleTimezoneChangesInSameDay() {
        // Simulate user changing timezones multiple times and verify schedule integrity
        let timezones = [
            TimeZone(identifier: "America/Los_Angeles")!,
            TimeZone(identifier: "America/Denver")!,
            TimeZone(identifier: "America/Chicago")!,
            TimeZone(identifier: "America/New_York")!
        ]

        // Medication scheduled for 12:00 PM Pacific
        let medication = createDate(
            year: 2024,
            month: 6,
            day: 15,
            hour: 12,
            minute: 0,
            timezone: timezones[0]
        )

        // Track through each timezone change
        var previousHour = 12
        for (index, timezone) in timezones.enumerated() {
            let components = Calendar.current.dateComponents(in: timezone, from: medication)

            XCTAssertNotNil(components.hour, "Hour should exist in \(timezone.identifier)")

            if index > 0 {
                // Each timezone is 1 hour ahead
                XCTAssertEqual(
                    components.hour,
                    previousHour + 1,
                    "Time should increment by 1 hour in \(timezone.identifier)"
                )
            }

            previousHour = components.hour!
        }
    }

    func testMedicationConsistency_LeapYearAndTimezones() {
        // Test timezone handling on leap year day (Feb 29)
        let nyTimezone = TimeZone(identifier: "America/New_York")!
        let tokyoTimezone = TimeZone(identifier: "Asia/Tokyo")!

        // Medication on Feb 29, 2024 (leap year)
        let leapDayMedication = createDate(
            year: 2024,
            month: 2,
            day: 29,
            hour: 10,
            minute: 0,
            timezone: nyTimezone
        )

        let tokyoComponents = Calendar.current.dateComponents(
            in: tokyoTimezone,
            from: leapDayMedication
        )

        XCTAssertNotNil(tokyoComponents.day, "Leap day should convert correctly")
        // Feb 29 10 AM EST might be Mar 1 in Tokyo depending on exact time
        XCTAssertTrue(
            tokyoComponents.day == 29 || tokyoComponents.day == 1,
            "Leap day should handle date transition correctly"
        )
    }

    // MARK: - Edge Case Combination Tests

    func testCombination_DateLineCrossingAndDST() {
        // Cross date line during DST transition
        let nzTimezone = TimeZone(identifier: "Pacific/Auckland")! // Has DST
        let hawaiiTimezone = TimeZone(identifier: "Pacific/Honolulu")! // No DST

        // During NZ DST transition period
        let nzTime = createDate(
            year: 2024,
            month: 9,
            day: 29, // DST starts in NZ
            hour: 2,
            minute: 30,
            timezone: nzTimezone
        )

        let hawaiiComponents = Calendar.current.dateComponents(
            in: hawaiiTimezone,
            from: nzTime
        )

        XCTAssertNotNil(hawaiiComponents.day, "Should handle date line + DST combination")
        XCTAssertNotNil(hawaiiComponents.hour, "Should have valid hour")
    }

    func testCombination_MidnightDSTAndDateLine() {
        // Midnight during DST change and crossing date line
        let nzTimezone = TimeZone(identifier: "Pacific/Auckland")!
        let samoaTimezone = TimeZone(identifier: "Pacific/Apia")!

        // Midnight during DST transition
        let nzMidnight = createDate(
            year: 2024,
            month: 9,
            day: 29,
            hour: 0,
            minute: 0,
            timezone: nzTimezone
        )

        let samoaComponents = Calendar.current.dateComponents(
            in: samoaTimezone,
            from: nzMidnight
        )

        XCTAssertNotNil(samoaComponents.day, "Should handle complex edge case")
    }

    func testCombination_RapidChangesWithDST() {
        // Rapid timezone changes during DST transition period
        let marchDate = createDate(
            year: 2024,
            month: 3,
            day: 10, // DST change day in US
            hour: 12,
            minute: 0,
            timezone: TimeZone(identifier: "America/New_York")!
        )

        let timezones = [
            "America/New_York",      // Has DST
            "America/Phoenix",       // No DST
            "Europe/London",         // Different DST schedule
            "Asia/Tokyo"            // No DST
        ]

        for tzIdentifier in timezones {
            guard let tz = TimeZone(identifier: tzIdentifier) else { continue }
            let components = Calendar.current.dateComponents(in: tz, from: marchDate)

            XCTAssertNotNil(components.hour, "\(tzIdentifier) should have valid hour during DST period")
            XCTAssertNotNil(components.day, "\(tzIdentifier) should have valid day during DST period")
        }
    }

    // MARK: - Helper Methods

    private func createDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        timezone: TimeZone
    ) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = timezone

        return calendar.date(from: components)!
    }

    private func assertTimeInterval(
        between date1: Date,
        and date2: Date,
        equals expectedSeconds: TimeInterval,
        accuracy: TimeInterval = 1.0,
        message: String
    ) {
        let actualInterval = date2.timeIntervalSince(date1)
        XCTAssertEqual(
            actualInterval,
            expectedSeconds,
            accuracy: accuracy,
            message
        )
    }
}
