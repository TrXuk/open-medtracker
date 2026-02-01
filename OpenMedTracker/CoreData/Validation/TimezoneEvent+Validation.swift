//
//  TimezoneEvent+Validation.swift
//  OpenMedTracker
//
//  Validation logic for TimezoneEvent entity
//

import Foundation
import CoreData

extension TimezoneEvent: Validatable {

    /// Validates the timezone event entity
    /// - Throws: ValidationError if validation fails
    public func validate() throws {
        // Validate previousTimezone
        guard !previousTimezone.isEmpty else {
            throw ValidationError.emptyField("previousTimezone")
        }

        guard TimeZone(identifier: previousTimezone) != nil else {
            throw ValidationError.invalidValue(
                field: "previousTimezone",
                reason: "Invalid timezone identifier"
            )
        }

        // Validate newTimezone
        guard !newTimezone.isEmpty else {
            throw ValidationError.emptyField("newTimezone")
        }

        guard TimeZone(identifier: newTimezone) != nil else {
            throw ValidationError.invalidValue(
                field: "newTimezone",
                reason: "Invalid timezone identifier"
            )
        }

        // Business rule: previousTimezone and newTimezone should be different
        guard previousTimezone != newTimezone else {
            throw ValidationError.businessRuleViolation(
                "Previous and new timezone must be different"
            )
        }

        // Validate transition time is not too far in the past or future
        let calendar = Calendar.current
        if let minDate = calendar.date(byAdding: .year, value: -2, to: Date()),
           let maxDate = calendar.date(byAdding: .day, value: 1, to: Date()) {
            guard transitionTime >= minDate && transitionTime <= maxDate else {
                throw ValidationError.invalidDate(
                    field: "transitionTime",
                    reason: "Transition time must be within past 2 years and not in the future"
                )
            }
        }

        // Validate location length
        if let location = location {
            guard !location.isEmpty else {
                throw ValidationError.invalidValue(
                    field: "location",
                    reason: "Location cannot be empty string (use nil instead)"
                )
            }

            guard location.count <= 200 else {
                throw ValidationError.invalidValue(
                    field: "location",
                    reason: "Location must be 200 characters or less"
                )
            }
        }

        // Validate notes length
        if let notes = notes {
            guard notes.count <= 1000 else {
                throw ValidationError.invalidValue(
                    field: "notes",
                    reason: "Notes must be 1000 characters or less"
                )
            }
        }

        // Business rule: Warn about extreme timezone changes (>12 hours)
        let timeDiff = abs(timeDifferenceHours)
        if timeDiff > 12 {
            // This is just a warning, not a hard validation error
            // In a real app, you might want to log this or alert the user
            print("Warning: Large timezone change detected (\(timeDiff) hours)")
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
