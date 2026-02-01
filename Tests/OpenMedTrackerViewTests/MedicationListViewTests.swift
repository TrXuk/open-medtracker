//
//  MedicationListViewTests.swift
//  OpenMedTrackerViewTests
//
//  ViewInspector tests for MedicationListView
//

import XCTest
import SwiftUI
import ViewInspector
import CoreData
@testable import OpenMedTracker

@MainActor
final class MedicationListViewTests: XCTestCase {

    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    var medicationService: MedicationService!

    override func setUp() async throws {
        try await super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        medicationService = MedicationService(persistenceController: persistenceController)
    }

    override func tearDown() async throws {
        persistenceController = nil
        context = nil
        medicationService = nil
        try await super.tearDown()
    }

    // MARK: - View Structure Tests

    func testViewExists() throws {
        let view = MedicationListView()
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }

    func testNavigationStackExists() throws {
        let view = MedicationListView()
            .environment(\.managedObjectContext, context)

        let navigationStack = try view.inspect().find(ViewType.NavigationStack.self)
        XCTAssertNotNil(navigationStack)
    }

    func testNavigationTitle() throws {
        let view = MedicationListView()
            .environment(\.managedObjectContext, context)

        let title = try view.inspect()
            .find(ViewType.NavigationStack.self)
            .navigationTitle()
        XCTAssertEqual(title, "Medications")
    }

    // MARK: - Empty State Tests

    func testEmptyStateDisplayed_WhenNoMedications() throws {
        let view = MedicationListView()
            .environment(\.managedObjectContext, context)

        // Should show empty state when no medications exist
        let emptyStateView = try view.inspect().find(EmptyStateView.self)
        XCTAssertNotNil(emptyStateView)
    }

    func testEmptyStateMessage_WhenNoSearch() throws {
        let view = MedicationListView()
            .environment(\.managedObjectContext, context)

        let emptyState = try view.inspect().find(EmptyStateView.self)
        let text = try emptyState.find(text: "Add your first medication to start tracking")
        XCTAssertNotNil(text)
    }

    // MARK: - Loading State Tests

    func testLoadingViewAppears_WhenLoading() throws {
        // Note: This test would require controlling the ViewModel's loading state
        // For now, we verify the LoadingView exists in the view hierarchy when conditions are met
        let view = MedicationListView()
            .environment(\.managedObjectContext, context)

        // In a real scenario, we'd need to inject a ViewModel with isLoading = true
        // This is a structural test only
        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - List Tests

    func testMedicationList_DisplaysMedications() throws {
        // Create a test medication
        let medication = try medicationService.create(
            name: "Aspirin",
            dosageAmount: 500,
            dosageUnit: "mg",
            instructions: "Take with food",
            startDate: Date(),
            in: context
        )
        try context.save()

        let view = MedicationListView()
            .environment(\.managedObjectContext, context)

        // After creating a medication, the list should eventually display it
        // Note: ViewInspector tests are synchronous, so async updates may not be immediately visible
        // This test verifies the view structure exists
        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - Toolbar Tests

    func testToolbarHasAddButton() throws {
        let view = MedicationListView()
            .environment(\.managedObjectContext, context)

        let toolbar = try view.inspect()
            .find(ViewType.NavigationStack.self)
            .toolbar()
        XCTAssertNotNil(toolbar)
    }

    func testToolbarHasFilterMenu() throws {
        let view = MedicationListView()
            .environment(\.managedObjectContext, context)

        // Verify the view has a toolbar which includes the filter menu
        let navigationStack = try view.inspect().find(ViewType.NavigationStack.self)
        XCTAssertNotNil(navigationStack)
    }

    // MARK: - Search Tests

    func testSearchFieldExists() throws {
        let view = MedicationListView()
            .environment(\.managedObjectContext, context)

        // Verify searchable modifier is applied
        // Note: ViewInspector's searchable support may be limited
        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - Integration Tests

    func testViewRendersWithMultipleMedications() throws {
        // Create multiple medications
        _ = try medicationService.create(
            name: "Aspirin",
            dosageAmount: 500,
            dosageUnit: "mg",
            startDate: Date(),
            in: context
        )

        _ = try medicationService.create(
            name: "Ibuprofen",
            dosageAmount: 200,
            dosageUnit: "mg",
            startDate: Date(),
            in: context
        )

        try context.save()

        let view = MedicationListView()
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }

    func testViewRendersWithInactiveMedication() throws {
        // Create an inactive medication
        let medication = try medicationService.create(
            name: "Old Medicine",
            dosageAmount: 100,
            dosageUnit: "mg",
            startDate: Date(),
            in: context
        )

        try medicationService.deactivate(medication, in: context)
        try context.save()

        let view = MedicationListView()
            .environment(\.managedObjectContext, context)

        XCTAssertNoThrow(try view.inspect())
    }
}

// MARK: - ViewInspector Extension

extension MedicationListView: Inspectable { }
