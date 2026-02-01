//
//  Medication+Validation.swift
//  OpenMedTracker
//
//  Validation logic for Medication entity
//

import Foundation
import CoreData

extension Medication: Validatable {

    /// Validates the medication entity
    /// - Throws: ValidationError if validation fails
    public func validate() throws {
        // Validate name
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyField("name")
        }

        guard name.count <= 200 else {
            throw ValidationError.invalidValue(
                field: "name",
                reason: "Name must be 200 characters or less"
            )
        }

        // Validate dosage amount
        guard dosageAmount > 0 else {
            throw ValidationError.invalidRange(field: "dosageAmount", min: 0, max: nil)
        }

        guard dosageAmount <= 100000 else {
            throw ValidationError.invalidRange(field: "dosageAmount", min: 0, max: 100000)
        }

        // Validate dosage unit
        guard !dosageUnit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyField("dosageUnit")
        }

        guard dosageUnit.count <= 50 else {
            throw ValidationError.invalidValue(
                field: "dosageUnit",
                reason: "Dosage unit must be 50 characters or less"
            )
        }

        // Validate dates
        if let end = endDate {
            guard end >= startDate else {
                throw ValidationError.invalidDate(
                    field: "endDate",
                    reason: "End date must be after or equal to start date"
                )
            }
        }

        // Validate future start dates aren't too far in the future (business rule)
        let calendar = Calendar.current
        if let maxFutureDate = calendar.date(byAdding: .year, value: 5, to: Date()) {
            guard startDate <= maxFutureDate else {
                throw ValidationError.businessRuleViolation(
                    "Start date cannot be more than 5 years in the future"
                )
            }
        }

        // Validate instructions length
        if let instructions = instructions {
            guard instructions.count <= 1000 else {
                throw ValidationError.invalidValue(
                    field: "instructions",
                    reason: "Instructions must be 1000 characters or less"
                )
            }
        }

        // Validate prescribedBy length
        if let prescribedBy = prescribedBy {
            guard prescribedBy.count <= 200 else {
                throw ValidationError.invalidValue(
                    field: "prescribedBy",
                    reason: "Prescriber name must be 200 characters or less"
                )
            }
        }
    }

    /// Core Data validation hook
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validate()
    }

    /// Core Data validation hook
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validate()
    }
}
