//
//  SettingsViewModelTests.swift
//  OpenMedTrackerTests
//
//  Tests for SettingsViewModel
//

import XCTest
@testable import OpenMedTracker

@MainActor
final class SettingsViewModelTests: XCTestCase {

    var sut: SettingsViewModel!
    var persistenceController: PersistenceController!

    override func setUp() async throws {
        try await super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        sut = SettingsViewModel(
            persistenceController: persistenceController,
            notificationService: NotificationService(persistenceController: persistenceController)
        )
    }

    override func tearDown() async throws {
        sut = nil
        persistenceController = nil
        try await super.tearDown()
    }

    // MARK: - Version Tests

    func testAppVersionIsNotEmpty() {
        XCTAssertFalse(sut.appVersion.isEmpty)
        XCTAssertNotEqual(sut.appVersion, "")
    }

    func testBuildNumberIsNotEmpty() {
        XCTAssertFalse(sut.buildNumber.isEmpty)
        XCTAssertNotEqual(sut.buildNumber, "")
    }

    func testFullVersionStringFormat() {
        let versionString = sut.fullVersionString
        XCTAssertTrue(versionString.contains("Version"))
        XCTAssertTrue(versionString.contains(sut.appVersion))
        XCTAssertTrue(versionString.contains(sut.buildNumber))
    }

    // MARK: - Timezone Tests

    func testCurrentTimezoneIsValid() {
        let timezone = sut.currentTimezone
        XCTAssertFalse(timezone.isEmpty)
        XCTAssertNotNil(TimeZone(identifier: timezone))
    }

    // MARK: - Data Export Tests

    func testExportDataCreatesFile() async {
        // Given: Some test data
        let context = persistenceController.container.viewContext
        let medication = Medication(context: context)
        medication.id = UUID()
        medication.name = "Test Med"
        medication.dosageAmount = 100
        medication.dosageUnit = "mg"
        medication.isActive = true
        medication.createdAt = Date()

        try? context.save()

        // When: Export data
        let exportURL = await sut.exportData()

        // Then: File should be created
        XCTAssertNotNil(exportURL)
        if let url = exportURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            XCTAssertEqual(url.pathExtension, "json")
        }
    }

    func testExportDataContainsCorrectStructure() async {
        // Given: Test data
        let context = persistenceController.container.viewContext
        let medication = Medication(context: context)
        medication.id = UUID()
        medication.name = "Test Med"
        medication.dosageAmount = 100
        medication.dosageUnit = "mg"
        medication.isActive = true
        medication.createdAt = Date()

        try? context.save()

        // When: Export data
        guard let exportURL = await sut.exportData() else {
            XCTFail("Export failed")
            return
        }

        // Then: Verify structure
        do {
            let data = try Data(contentsOf: exportURL)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            XCTAssertNotNil(json)
            XCTAssertNotNil(json?["version"])
            XCTAssertNotNil(json?["exportDate"])
            XCTAssertNotNil(json?["medications"])
            XCTAssertNotNil(json?["schedules"])
            XCTAssertNotNil(json?["doseHistory"])
            XCTAssertNotNil(json?["timezoneEvents"])
        } catch {
            XCTFail("Failed to parse exported JSON: \(error)")
        }
    }

    // MARK: - Clear Data Tests

    func testClearAllDataRemovesAllEntities() async {
        // Given: Some test data
        let context = persistenceController.container.viewContext

        let medication = Medication(context: context)
        medication.id = UUID()
        medication.name = "Test Med"
        medication.dosageAmount = 100
        medication.dosageUnit = "mg"
        medication.isActive = true
        medication.createdAt = Date()

        try? context.save()

        // Verify data exists
        let fetchRequest = Medication.fetchRequest()
        let initialCount = (try? context.fetch(fetchRequest).count) ?? 0
        XCTAssertGreaterThan(initialCount, 0)

        // When: Clear all data
        await sut.clearAllData()

        // Then: All data should be removed
        let finalCount = (try? context.fetch(fetchRequest).count) ?? 0
        XCTAssertEqual(finalCount, 0)
    }

    // MARK: - Message Tests

    func testClearMessagesRemovesErrorAndSuccess() {
        // Given: Messages set
        sut.errorMessage = "Test error"
        sut.successMessage = "Test success"

        // When: Clear messages
        sut.clearMessages()

        // Then: Messages should be nil
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
    }
}
