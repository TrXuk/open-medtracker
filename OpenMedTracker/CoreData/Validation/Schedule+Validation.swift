//
//  Schedule+Validation.swift
//  OpenMedTracker
//
//  Validation logic for Schedule entity
//

import Foundation
import CoreData

extension Schedule: Validatable {

    /// Validates the schedule entity
    /// - Throws: ValidationError if validation fails
    public func validate() throws {
        // Validate medication relationship
        guard medication != nil else {
            throw ValidationError.invalidRelationship(
                field: "medication",
                reason: "Schedule must be associated with a medication"
            )
        }

        // Validate frequency
        let validFrequencies = ["daily", "weekly", "as-needed", "custom"]
        guard validFrequencies.contains(frequency.lowercased()) else {
            throw ValidationError.invalidValue(
                field: "frequency",
                reason: "Frequency must be one of: \(validFrequencies.joined(separator: ", "))"
            )
        }

        // Validate daysOfWeek bitmask
        guard daysOfWeek >= 0 && daysOfWeek <= 127 else {
            throw ValidationError.invalidRange(
                field: "daysOfWeek",
                min: 0,
                max: 127
            )
        }

        // Business rule: At least one day must be selected
        guard daysOfWeek > 0 else {
            throw ValidationError.businessRuleViolation(
                "At least one day of the week must be selected"
            )
        }

        // Validate timeOfDay is a valid date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: timeOfDay)

        guard let hour = components.hour, let minute = components.minute else {
            throw ValidationError.invalidDate(
                field: "timeOfDay",
                reason: "Time must have valid hour and minute components"
            )
        }

        guard hour >= 0 && hour < 24 else {
            throw ValidationError.invalidRange(field: "hour", min: 0, max: 23)
        }

        guard minute >= 0 && minute < 60 else {
            throw ValidationError.invalidRange(field: "minute", min: 0, max: 59)
        }

        // Business rule: Medication must be active for schedule to be enabled
        if isEnabled {
            guard let med = medication, med.isActive else {
                throw ValidationError.businessRuleViolation(
                    "Cannot enable schedule for inactive medication"
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
