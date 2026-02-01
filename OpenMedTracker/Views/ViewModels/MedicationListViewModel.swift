import Foundation
import CoreData
import Combine

/// ViewModel for the medication list view
@MainActor
class MedicationListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var medications: [Medication] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var searchText: String = ""
    @Published var showActiveOnly: Bool = true

    // MARK: - Private Properties

    private let medicationService: MedicationService
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        medicationService: MedicationService = MedicationService(),
        context: NSManagedObjectContext
    ) {
        self.medicationService = medicationService
        self.context = context
        setupSearchDebounce()
    }

    // MARK: - Public Methods

    /// Loads all medications
    func loadMedications() {
        isLoading = true
        error = nil

        do {
            medications = try medicationService.fetchAll(
                activeOnly: showActiveOnly,
                in: context
            )
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    /// Searches medications by name
    func searchMedications() {
        guard !searchText.isEmpty else {
            loadMedications()
            return
        }

        isLoading = true
        error = nil

        do {
            medications = try medicationService.search(
                byName: searchText,
                in: context
            )
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    /// Deletes a medication
    func deleteMedication(_ medication: Medication) {
        do {
            try medicationService.delete(medication, in: context)
            loadMedications()
        } catch {
            self.error = error
        }
    }

    /// Toggles active status of a medication
    func toggleActive(_ medication: Medication) {
        do {
            if medication.isActive {
                try medicationService.deactivate(medication, in: context)
            } else {
                try medicationService.reactivate(medication, in: context)
            }
            loadMedications()
        } catch {
            self.error = error
        }
    }

    // MARK: - Private Methods

    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.searchMedications()
            }
            .store(in: &cancellables)
    }
}
