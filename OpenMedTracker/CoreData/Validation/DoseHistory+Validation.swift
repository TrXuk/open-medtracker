//
//  DoseHistory+Validation.swift
//  OpenMedTracker
//
//  Validation logic for DoseHistory entity
//

import Foundation
import CoreData

extension DoseHistory: Validatable {

    /// Validates the dose history entity
    /// - Throws: ValidationError if validation fails
    public func validate() throws {
        // Validate schedule relationship
        guard schedule != nil else {
            throw ValidationError.invalidRelationship(
                field: "schedule",
                reason: "DoseHistory must be associated with a schedule"
            )
        }

        // Validate status
        let validStatuses = Status.allCases.map { $0.rawValue }
        guard validStatuses.contains(status) else {
            throw ValidationError.invalidValue(
                field: "status",
                reason: "Status must be one of: \(validStatuses.joined(separator: ", "))"
            )
        }

        // Validate timezone identifier
        guard !timezoneIdentifier.isEmpty else {
            throw ValidationError.emptyField("timezoneIdentifier")
        }

        guard TimeZone(identifier: timezoneIdentifier) != nil else {
            throw ValidationError.invalidValue(
                field: "timezoneIdentifier",
                reason: "Invalid timezone identifier"
            )
        }

        // Business rule: actualTime should only be set for "taken" status
        if let actual = actualTime {
            guard statusEnum == .taken else {
                throw ValidationError.businessRuleViolation(
                    "Actual time should only be set when status is 'taken'"
                )
            }

            // Validate actualTime is not too far in the future
            let calendar = Calendar.current
            if let maxFutureDate = calendar.date(byAdding: .hour, value: 1, to: Date()) {
                guard actual <= maxFutureDate else {
                    throw ValidationError.businessRuleViolation(
                        "Actual time cannot be more than 1 hour in the future"
                    )
                }
            }

            // Validate actualTime is not too far before scheduledTime
            let timeDiff = scheduledTime.timeIntervalSince(actual)
            let oneWeekInSeconds: TimeInterval = 7 * 24 * 60 * 60

            guard timeDiff <= oneWeekInSeconds else {
                throw ValidationError.businessRuleViolation(
                    "Actual time cannot be more than 1 week before scheduled time"
                )
            }
        }

        // Business rule: Pending status should have no actualTime
        if statusEnum == .pending {
            guard actualTime == nil else {
                throw ValidationError.businessRuleViolation(
                    "Pending dose should not have an actual time"
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

        // Validate scheduled time is not too far in the past or future
        let calendar = Calendar.current
        if let minDate = calendar.date(byAdding: .year, value: -2, to: Date()),
           let maxDate = calendar.date(byAdding: .year, value: 2, to: Date()) {
            guard scheduledTime >= minDate && scheduledTime <= maxDate else {
                throw ValidationError.invalidDate(
                    field: "scheduledTime",
                    reason: "Scheduled time must be within 2 years of current date"
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
