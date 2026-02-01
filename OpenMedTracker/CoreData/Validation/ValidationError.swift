//
//  ValidationError.swift
//  OpenMedTracker
//
//  Data validation error types
//

import Foundation

/// Errors that can occur during entity validation
public enum ValidationError: LocalizedError {
    case emptyField(String)
    case invalidValue(field: String, reason: String)
    case invalidRange(field: String, min: Double?, max: Double?)
    case invalidDate(field: String, reason: String)
    case invalidRelationship(field: String, reason: String)
    case businessRuleViolation(String)
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "Field '\(field)' cannot be empty"

        case .invalidValue(let field, let reason):
            return "Invalid value for '\(field)': \(reason)"

        case .invalidRange(let field, let min, let max):
            var message = "Value for '\(field)' is out of range"
            if let min = min, let max = max {
                message += " (must be between \(min) and \(max))"
            } else if let min = min {
                message += " (must be at least \(min))"
            } else if let max = max {
                message += " (must be at most \(max))"
            }
            return message

        case .invalidDate(let field, let reason):
            return "Invalid date for '\(field)': \(reason)"

        case .invalidRelationship(let field, let reason):
            return "Invalid relationship '\(field)': \(reason)"

        case .businessRuleViolation(let message):
            return "Business rule violation: \(message)"

        case .custom(let message):
            return message
        }
    }
}

/// Protocol for validatable entities
public protocol Validatable {
    /// Validates the entity
    /// - Throws: ValidationError if validation fails
    func validate() throws
}
