//
//  MedicationListViewModel.swift
//  OpenMedTracker
//
//  View model for managing a list of medications
//

import Foundation
import Combine
import CoreData

/// View model for displaying and managing a list of medications
@MainActor
public final class MedicationListViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of medications to display
    @Published public private(set) var medications: [Medication] = []

    /// Search text for filtering medications
    @Published public var searchText: String = ""

    /// Whether to show only active medications
    @Published public var showActiveOnly: Bool = true

    /// Current loading state
    @Published public private(set) var isLoading: Bool = false

    /// Current error, if any
    @Published public private(set) var error: ViewModelError?

    /// Filtered medications based on search and active filter
    @Published public private(set) var filteredMedications: [Medication] = []

    // MARK: - Private Properties

    private let medicationService: MedicationService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initialize with optional medication service
    /// - Parameter medicationService: Service for medication operations (defaults to shared instance)
    public init(medicationService: MedicationService = MedicationService()) {
        self.medicationService = medicationService
        setupPublishers()
    }

    // MARK: - Setup

    private func setupPublishers() {
        // Combine searchText and showActiveOnly to filter medications
        Publishers.CombineLatest3(
            $medications,
            $searchText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main),
            $showActiveOnly
        )
        .map { medications, searchText, showActiveOnly in
            var filtered = medications

            // Filter by active status
            if showActiveOnly {
                filtered = filtered.filter { $0.isActive }
            }

            // Filter by search text
            if !searchText.isEmpty {
                filtered = filtered.filter { medication in
                    medication.name.localizedCaseInsensitiveContains(searchText)
                }
            }

            return filtered
        }
        .assign(to: &$filteredMedications)
    }

    // MARK: - Public Methods

    /// Load all medications
    public func loadMedications() {
        isLoading = true
        error = nil

        do {
            medications = try medicationService.fetchAll(includeInactive: !showActiveOnly)
            isLoading = false
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
            medications = []
            isLoading = false
        }
    }

    /// Refresh the medication list
    public func refresh() {
        loadMedications()
    }

    /// Search medications by name
    /// - Parameter query: Search query
    public func search(_ query: String) {
        searchText = query
    }

    /// Clear search
    public func clearSearch() {
        searchText = ""
    }

    /// Toggle active filter
    public func toggleActiveFilter() {
        showActiveOnly.toggle()
        loadMedications()
    }

    /// Delete a medication
    /// - Parameter medication: Medication to delete
    public func delete(_ medication: Medication) {
        error = nil

        do {
            try medicationService.delete(medication)
            loadMedications()
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
        }
    }

    /// Delete medications at specific indices
    /// - Parameter offsets: Index set of medications to delete
    public func delete(at offsets: IndexSet) {
        error = nil

        for index in offsets {
            let medication = filteredMedications[index]
            do {
                try medicationService.delete(medication)
            } catch {
                self.error = ViewModelError.from(persistenceError: error)
                break
            }
        }

        loadMedications()
    }

    /// Deactivate a medication
    /// - Parameter medication: Medication to deactivate
    public func deactivate(_ medication: Medication) {
        error = nil

        do {
            try medicationService.deactivate(medication)
            loadMedications()
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
        }
    }

    /// Reactivate a medication
    /// - Parameter medication: Medication to reactivate
    public func reactivate(_ medication: Medication) {
        error = nil

        do {
            try medicationService.reactivate(medication)
            loadMedications()
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
        }
    }

    /// Get count of active medications
    public var activeMedicationCount: Int {
        medications.filter { $0.isActive }.count
    }

    /// Get count of inactive medications
    public var inactiveMedicationCount: Int {
        medications.filter { !$0.isActive }.count
    }

    /// Clear any current error
    public func clearError() {
        error = nil
    }
}

// MARK: - Preview Helper

extension MedicationListViewModel {
    /// Create a preview instance with mock data
    public static func preview() -> MedicationListViewModel {
        let viewModel = MedicationListViewModel(
            medicationService: MedicationService(persistenceController: .preview)
        )
        viewModel.loadMedications()
        return viewModel
    }
}
