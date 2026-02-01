//
//  MedicationDetailViewModel.swift
//  OpenMedTracker
//
//  View model for viewing and editing a single medication
//

import Foundation
import Combine
import CoreData

/// View model for displaying and editing medication details
@MainActor
public final class MedicationDetailViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The medication being viewed/edited
    @Published public private(set) var medication: Medication?

    /// Name of the medication
    @Published public var name: String = ""

    /// Dosage amount
    @Published public var dosageAmount: String = ""

    /// Dosage unit (e.g., "mg", "ml")
    @Published public var dosageUnit: String = ""

    /// Instructions for taking the medication
    @Published public var instructions: String = ""

    /// Prescriber name
    @Published public var prescribedBy: String = ""

    /// Start date
    @Published public var startDate: Date = Date()

    /// End date (optional)
    @Published public var endDate: Date?

    /// Whether the medication has an end date
    @Published public var hasEndDate: Bool = false

    /// Whether the medication is active
    @Published public var isActive: Bool = true

    /// Current loading state
    @Published public private(set) var isLoading: Bool = false

    /// Current saving state
    @Published public private(set) var isSaving: Bool = false

    /// Current error, if any
    @Published public private(set) var error: ViewModelError?

    /// Validation errors
    @Published public private(set) var validationErrors: [String: String] = [:]

    /// Whether the form is valid
    @Published public private(set) var isValid: Bool = false

    /// Associated schedules for this medication
    @Published public private(set) var schedules: [Schedule] = []

    // MARK: - Private Properties

    private let medicationService: MedicationService
    private let scheduleService: ScheduleService
    private var cancellables = Set<AnyCancellable>()
    private let isNewMedication: Bool

    // MARK: - Initialization

    /// Initialize for creating a new medication
    /// - Parameters:
    ///   - medicationService: Service for medication operations
    ///   - scheduleService: Service for schedule operations
    public init(
        medicationService: MedicationService = MedicationService(),
        scheduleService: ScheduleService = ScheduleService()
    ) {
        self.medicationService = medicationService
        self.scheduleService = scheduleService
        self.isNewMedication = true
        setupValidation()
    }

    /// Initialize for editing an existing medication
    /// - Parameters:
    ///   - medication: The medication to edit
    ///   - medicationService: Service for medication operations
    ///   - scheduleService: Service for schedule operations
    public init(
        medication: Medication,
        medicationService: MedicationService = MedicationService(),
        scheduleService: ScheduleService = ScheduleService()
    ) {
        self.medicationService = medicationService
        self.scheduleService = scheduleService
        self.medication = medication
        self.isNewMedication = false

        // Populate fields from medication
        self.name = medication.name
        self.dosageAmount = String(medication.dosageAmount)
        self.dosageUnit = medication.dosageUnit
        self.instructions = medication.instructions ?? ""
        self.prescribedBy = medication.prescribedBy ?? ""
        self.startDate = medication.startDate
        self.endDate = medication.endDate
        self.hasEndDate = medication.endDate != nil
        self.isActive = medication.isActive

        setupValidation()
        loadSchedules()
    }

    // MARK: - Setup

    private func setupValidation() {
        // Validate whenever relevant fields change
        Publishers.CombineLatest4(
            $name,
            $dosageAmount,
            $dosageUnit,
            $hasEndDate
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.validate()
        }
        .store(in: &cancellables)

        // Also validate when endDate changes if hasEndDate is true
        $endDate
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, self.hasEndDate else { return }
                self.validate()
            }
            .store(in: &cancellables)
    }

    // MARK: - Validation

    private func validate() {
        validationErrors.removeAll()

        // Validate name
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors["name"] = "Medication name is required"
        } else if name.count > 100 {
            validationErrors["name"] = "Name must be 100 characters or less"
        }

        // Validate dosage amount
        if dosageAmount.isEmpty {
            validationErrors["dosageAmount"] = "Dosage amount is required"
        } else if let amount = Double(dosageAmount), amount <= 0 {
            validationErrors["dosageAmount"] = "Dosage amount must be greater than 0"
        } else if Double(dosageAmount) == nil {
            validationErrors["dosageAmount"] = "Please enter a valid number"
        }

        // Validate dosage unit
        if dosageUnit.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors["dosageUnit"] = "Dosage unit is required"
        } else if dosageUnit.count > 20 {
            validationErrors["dosageUnit"] = "Unit must be 20 characters or less"
        }

        // Validate dates
        if hasEndDate, let endDate = endDate, endDate <= startDate {
            validationErrors["endDate"] = "End date must be after start date"
        }

        isValid = validationErrors.isEmpty
    }

    // MARK: - Public Methods

    /// Load schedules for this medication
    public func loadSchedules() {
        guard let medication = medication else { return }

        do {
            schedules = try scheduleService.fetchSchedules(for: medication)
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
        }
    }

    /// Save the medication
    /// - Returns: The saved medication, or nil if save failed
    @discardableResult
    public func save() async -> Medication? {
        validate()

        guard isValid else {
            error = .validationFailed(message: "Please correct the errors before saving")
            return nil
        }

        isSaving = true
        error = nil

        do {
            guard let amount = Double(dosageAmount) else {
                throw ViewModelError.validationFailed(message: "Invalid dosage amount")
            }

            let savedMedication: Medication

            if isNewMedication {
                // Create new medication
                savedMedication = try medicationService.create(
                    name: name.trimmingCharacters(in: .whitespaces),
                    dosageAmount: amount,
                    dosageUnit: dosageUnit.trimmingCharacters(in: .whitespaces),
                    instructions: instructions.isEmpty ? nil : instructions,
                    prescribedBy: prescribedBy.isEmpty ? nil : prescribedBy,
                    startDate: startDate,
                    endDate: hasEndDate ? endDate : nil
                )
            } else {
                // Update existing medication
                guard let medication = medication else {
                    throw ViewModelError.invalidState("No medication to update")
                }

                try medicationService.update(
                    medication,
                    name: name.trimmingCharacters(in: .whitespaces),
                    dosageAmount: amount,
                    dosageUnit: dosageUnit.trimmingCharacters(in: .whitespaces),
                    instructions: instructions.isEmpty ? nil : instructions,
                    prescribedBy: prescribedBy.isEmpty ? nil : prescribedBy,
                    startDate: startDate,
                    endDate: hasEndDate ? endDate : nil,
                    isActive: isActive
                )

                savedMedication = medication
            }

            self.medication = savedMedication
            isSaving = false
            return savedMedication

        } catch {
            self.error = ViewModelError.from(persistenceError: error)
            isSaving = false
            return nil
        }
    }

    /// Delete the medication
    public func delete() async -> Bool {
        guard let medication = medication else {
            error = .invalidState("No medication to delete")
            return false
        }

        error = nil

        do {
            try medicationService.delete(medication)
            return true
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
            return false
        }
    }

    /// Deactivate the medication
    public func deactivate() {
        guard let medication = medication else {
            error = .invalidState("No medication to deactivate")
            return
        }

        error = nil

        do {
            try medicationService.deactivate(medication)
            isActive = false
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
        }
    }

    /// Reactivate the medication
    public func reactivate() {
        guard let medication = medication else {
            error = .invalidState("No medication to reactivate")
            return
        }

        error = nil

        do {
            try medicationService.reactivate(medication)
            isActive = true
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
        }
    }

    /// Clear any current error
    public func clearError() {
        error = nil
    }

    /// Get validation error for a specific field
    /// - Parameter field: The field name
    /// - Returns: Error message if exists
    public func validationError(for field: String) -> String? {
        validationErrors[field]
    }

    /// Whether a specific field has an error
    /// - Parameter field: The field name
    /// - Returns: True if field has validation error
    public func hasError(for field: String) -> Bool {
        validationErrors[field] != nil
    }
}

// MARK: - Preview Helper

extension MedicationDetailViewModel {
    /// Create a preview instance for new medication
    public static func previewNew() -> MedicationDetailViewModel {
        MedicationDetailViewModel(
            medicationService: MedicationService(persistenceController: .preview)
        )
    }

    /// Create a preview instance for existing medication
    public static func previewExisting() -> MedicationDetailViewModel? {
        let service = MedicationService(persistenceController: .preview)
        guard let medication = try? service.fetchAll().first else {
            return nil
        }
        return MedicationDetailViewModel(
            medication: medication,
            medicationService: service
        )
    }
}
