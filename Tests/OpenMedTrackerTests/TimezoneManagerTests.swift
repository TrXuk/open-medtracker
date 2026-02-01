import XCTest
@testable import OpenMedTracker

final class TimezoneManagerTests: XCTestCase {

    var manager: TimezoneManager!

    override func setUp() {
        super.setUp()
        manager = TimezoneManager.shared
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceIsSingleton() {
        let instance1 = TimezoneManager.shared
        let instance2 = TimezoneManager.shared

        XCTAssertTrue(instance1 === instance2, "TimezoneManager should return the same singleton instance")
    }

    // MARK: - Initialization Tests

    func testInitialTimezoneSetup() {
        XCTAssertNotNil(manager.referenceTimezone, "Reference timezone should be initialized")
        XCTAssertEqual(manager.referenceTimezone.identifier, "UTC", "Reference timezone should default to UTC")
        XCTAssertNotNil(manager.localTimezone, "Local timezone should be initialized")
    }

    // MARK: - Timezone Change Notification Tests

    func testTimezoneChangeNotificationIsPosted() {
        let expectation = XCTestExpectation(description: "Timezone change notification should be posted")

        let observer = NotificationCenter.default.addObserver(
            forName: TimezoneManager.timezoneDidChangeNotification,
            object: manager,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification.userInfo?["oldTimezone"])
            XCTAssertNotNil(notification.userInfo?["newTimezone"])
            expectation.fulfill()
        }

        // Simulate system timezone change
        NotificationCenter.default.post(
            name: NSNotification.Name.NSSystemTimeZoneDidChange,
            object: nil
        )

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - UTC to Reference Conversion Tests

    func testConvertUTCToReference() {
        let utcDate = createDate(year: 2024, month: 1, day: 15, hour: 12, minute: 0, timezone: TimeZone(identifier: "UTC")!)
        let components = manager.convertUTCToReference(utcDate)

        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.timeZone?.identifier, "UTC")
    }

    func testConvertReferenceToUTC() {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.timeZone = manager.referenceTimezone

        let utcDate = manager.convertReferenceToUTC(components)

        XCTAssertNotNil(utcDate)

        let calendar = Calendar.current
        let utcComponents = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: utcDate!)

        XCTAssertEqual(utcComponents.year, 2024)
        XCTAssertEqual(utcComponents.month, 1)
        XCTAssertEqual(utcComponents.day, 15)
    }

    // MARK: - UTC to Local Conversion Tests

    func testConvertUTCToLocal() {
        let utcDate = createDate(year: 2024, month: 1, day: 15, hour: 12, minute: 0, timezone: TimeZone(identifier: "UTC")!)
        let components = manager.convertUTCToLocal(utcDate)

        XCTAssertNotNil(components.year)
        XCTAssertNotNil(components.month)
        XCTAssertNotNil(components.day)
        XCTAssertNotNil(components.hour)
        XCTAssertEqual(components.timeZone?.identifier, manager.localTimezone.identifier)
    }

    func testConvertLocalToUTC() {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.timeZone = manager.localTimezone

        let utcDate = manager.convertLocalToUTC(components)

        XCTAssertNotNil(utcDate)
    }

    // MARK: - Local to Reference Conversion Tests

    func testConvertLocalToReference() {
        let localDate = Date()
        let components = manager.convertLocalToReference(localDate)

        XCTAssertNotNil(components.year)
        XCTAssertNotNil(components.month)
        XCTAssertNotNil(components.day)
        XCTAssertNotNil(components.hour)
    }

    func testConvertReferenceToLocal() {
        let referenceDate = Date()
        let components = manager.convertReferenceToLocal(referenceDate)

        XCTAssertNotNil(components.year)
        XCTAssertNotNil(components.month)
        XCTAssertNotNil(components.day)
        XCTAssertNotNil(components.hour)
    }

    // MARK: - Offset Calculation Tests

    func testOffsetBetweenLocalAndReference() {
        let offset = manager.offsetBetweenLocalAndReference()

        // The offset should be a multiple of 60 (in most timezones)
        // This is a basic sanity check
        XCTAssertTrue(offset % 60 == 0 || offset % 900 == 0, "Offset should be in 15-minute or 1-hour increments")
    }

    func testOffsetCalculationForSpecificDate() {
        let date = Date()
        let offset = manager.offsetBetweenLocalAndReference(for: date)

        // Verify the offset is calculated correctly
        let localOffset = manager.localTimezone.secondsFromGMT(for: date)
        let referenceOffset = manager.referenceTimezone.secondsFromGMT(for: date)
        let expectedOffset = localOffset - referenceOffset

        XCTAssertEqual(offset, expectedOffset)
    }

    // MARK: - Date Formatting Tests

    func testFormatDateInTimezone() {
        let date = createDate(year: 2024, month: 1, day: 15, hour: 12, minute: 30, timezone: TimeZone(identifier: "UTC")!)
        let formatted = manager.formatDate(date, in: TimeZone(identifier: "UTC")!)

        XCTAssertFalse(formatted.isEmpty, "Formatted date should not be empty")
    }

    func testCurrentTimezoneDescription() {
        let description = manager.currentTimezoneDescription()

        XCTAssertFalse(description.isEmpty, "Timezone description should not be empty")
        XCTAssertTrue(description.contains(manager.localTimezone.identifier), "Description should contain timezone identifier")
    }

    // MARK: - Reference Timezone Configuration Tests

    func testSetReferenceTimezone() {
        let newReferenceTimezone = TimeZone(identifier: "America/New_York")!
        manager.setReferenceTimezone(newReferenceTimezone)

        XCTAssertEqual(manager.referenceTimezone.identifier, "America/New_York")

        // Reset to UTC for other tests
        manager.setReferenceTimezone(TimeZone(identifier: "UTC")!)
    }

    // MARK: - TimeZone Extension Tests

    func testTimezoneDetailedDescription() {
        let utcTimezone = TimeZone(identifier: "UTC")!
        let description = utcTimezone.detailedDescription

        XCTAssertFalse(description.isEmpty)
        XCTAssertTrue(description.contains("UTC"))
    }

    // MARK: - Date Extension Tests

    func testDateToUTCString() {
        let date = Date()
        let utcString = date.toUTCString()

        XCTAssertFalse(utcString.isEmpty, "UTC string should not be empty")
    }

    func testDateToLocalString() {
        let date = Date()
        let localString = date.toLocalString()

        XCTAssertFalse(localString.isEmpty, "Local string should not be empty")
    }

    // MARK: - Integration Tests

    func testRoundTripConversion_LocalToUTCToLocal() {
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 0
        components.timeZone = manager.localTimezone

        // Convert local to UTC
        guard let utcDate = manager.convertLocalToUTC(components) else {
            XCTFail("Failed to convert local to UTC")
            return
        }

        // Convert UTC back to local
        let reconvertedComponents = manager.convertUTCToLocal(utcDate)

        // Allow for small differences due to DST or timezone quirks
        XCTAssertEqual(reconvertedComponents.year, components.year)
        XCTAssertEqual(reconvertedComponents.month, components.month)
        XCTAssertEqual(reconvertedComponents.day, components.day)
        XCTAssertEqual(reconvertedComponents.hour, components.hour)
    }

    func testRoundTripConversion_ReferenceToUTCToReference() {
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 0
        components.timeZone = manager.referenceTimezone

        // Convert reference to UTC
        guard let utcDate = manager.convertReferenceToUTC(components) else {
            XCTFail("Failed to convert reference to UTC")
            return
        }

        // Convert UTC back to reference
        let reconvertedComponents = manager.convertUTCToReference(utcDate)

        XCTAssertEqual(reconvertedComponents.year, components.year)
        XCTAssertEqual(reconvertedComponents.month, components.month)
        XCTAssertEqual(reconvertedComponents.day, components.day)
        XCTAssertEqual(reconvertedComponents.hour, components.hour)
    }

    // MARK: - Helper Methods

    private func createDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, timezone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0

        return calendar.date(from: components)!
    }
}
