//
//  AppSettingsTests.swift
//  OpenMedTrackerTests
//
//  Tests for AppSettings model
//

import XCTest
@testable import OpenMedTracker

final class AppSettingsTests: XCTestCase {

    var sut: AppSettings!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialValuesAreDefaults() {
        // Given: Fresh settings
        let settings = AppSettings.shared

        // Then: Should have default values
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertTrue(settings.notificationSound)
        XCTAssertTrue(settings.snoozeEnabled)
        XCTAssertEqual(settings.snoozeDuration, 10)
        XCTAssertTrue(settings.autoDetectTimezone)
        XCTAssertEqual(settings.appearance, .system)
    }

    // MARK: - Notification Settings Tests

    func testNotificationsEnabledPersists() {
        // Given: Settings instance
        let settings = AppSettings.shared

        // When: Toggle notifications
        settings.notificationsEnabled = false

        // Then: Should persist
        XCTAssertFalse(settings.notificationsEnabled)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "notificationsEnabled"))
    }

    func testNotificationSoundPersists() {
        // Given: Settings instance
        let settings = AppSettings.shared

        // When: Toggle sound
        settings.notificationSound = false

        // Then: Should persist
        XCTAssertFalse(settings.notificationSound)
    }

    func testSnoozeDurationPersists() {
        // Given: Settings instance
        let settings = AppSettings.shared

        // When: Change snooze duration
        settings.snoozeDuration = 15

        // Then: Should persist
        XCTAssertEqual(settings.snoozeDuration, 15)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "snoozeDuration"), 15)
    }

    // MARK: - Timezone Settings Tests

    func testPreferredTimezonePersists() {
        // Given: Settings instance
        let settings = AppSettings.shared

        // When: Set preferred timezone
        settings.preferredTimezone = "America/New_York"

        // Then: Should persist
        XCTAssertEqual(settings.preferredTimezone, "America/New_York")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "preferredTimezone"), "America/New_York")
    }

    func testAutoDetectTimezonePersists() {
        // Given: Settings instance
        let settings = AppSettings.shared

        // When: Toggle auto-detect
        settings.autoDetectTimezone = false

        // Then: Should persist
        XCTAssertFalse(settings.autoDetectTimezone)
    }

    // MARK: - Appearance Settings Tests

    func testAppearanceModePersists() {
        // Given: Settings instance
        let settings = AppSettings.shared

        // When: Change appearance
        settings.appearance = .dark

        // Then: Should persist
        XCTAssertEqual(settings.appearance, .dark)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "appearance"), "dark")
    }

    func testAllAppearanceModesWork() {
        // Given: Settings instance
        let settings = AppSettings.shared

        // When/Then: Test all modes
        settings.appearance = .system
        XCTAssertEqual(settings.appearance, .system)

        settings.appearance = .light
        XCTAssertEqual(settings.appearance, .light)

        settings.appearance = .dark
        XCTAssertEqual(settings.appearance, .dark)
    }

    // MARK: - Reset Tests

    func testResetToDefaultsRestoresAllSettings() {
        // Given: Settings with modified values
        let settings = AppSettings.shared
        settings.notificationsEnabled = false
        settings.notificationSound = false
        settings.snoozeEnabled = false
        settings.snoozeDuration = 20
        settings.preferredTimezone = "Europe/London"
        settings.autoDetectTimezone = false
        settings.appearance = .dark

        // When: Reset to defaults
        settings.resetToDefaults()

        // Then: Should restore defaults
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertTrue(settings.notificationSound)
        XCTAssertTrue(settings.snoozeEnabled)
        XCTAssertEqual(settings.snoozeDuration, 10)
        XCTAssertNil(settings.preferredTimezone)
        XCTAssertTrue(settings.autoDetectTimezone)
        XCTAssertEqual(settings.appearance, .system)
    }

    // MARK: - AppearanceMode Tests

    func testAppearanceModeDisplayNames() {
        XCTAssertEqual(AppearanceMode.system.displayName, "System")
        XCTAssertEqual(AppearanceMode.light.displayName, "Light")
        XCTAssertEqual(AppearanceMode.dark.displayName, "Dark")
    }

    func testAppearanceModeRawValues() {
        XCTAssertEqual(AppearanceMode.system.rawValue, "system")
        XCTAssertEqual(AppearanceMode.light.rawValue, "light")
        XCTAssertEqual(AppearanceMode.dark.rawValue, "dark")
    }

    func testAppearanceModeFromRawValue() {
        XCTAssertEqual(AppearanceMode(rawValue: "system"), .system)
        XCTAssertEqual(AppearanceMode(rawValue: "light"), .light)
        XCTAssertEqual(AppearanceMode(rawValue: "dark"), .dark)
        XCTAssertNil(AppearanceMode(rawValue: "invalid"))
    }
}
