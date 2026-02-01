//
//  ViewModelError.swift
//  OpenMedTracker
//
//  Error types for view model layer with user-friendly messages
//

import Foundation

/// Errors that can occur in the view model layer
public enum ViewModelError: LocalizedError {
    case loadFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case validationFailed(message: String)
    case notFound(String)
    case invalidState(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .loadFailed(let error):
            return "Failed to load data: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save changes: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete: \(error.localizedDescription)"
        case .validationFailed(let message):
            return "Validation error: \(message)"
        case .notFound(let item):
            return "\(item) not found"
        case .invalidState(let message):
            return "Invalid state: \(message)"
        case .unknown(let message):
            return "An error occurred: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .loadFailed:
            return "Please try again. If the problem persists, restart the app."
        case .saveFailed:
            return "Please check your input and try again."
        case .deleteFailed:
            return "Please try again."
        case .validationFailed:
            return "Please correct the invalid fields and try again."
        case .notFound:
            return "The item may have been deleted. Please refresh and try again."
        case .invalidState:
            return "Please refresh and try the operation again."
        case .unknown:
            return "Please try again or contact support if the issue persists."
        }
    }

    /// Maps a PersistenceError to a ViewModelError
    static func from(persistenceError: Error) -> ViewModelError {
        if let persistenceError = persistenceError as? PersistenceError {
            switch persistenceError {
            case .saveFailed(let error):
                return .saveFailed(underlying: error)
            case .fetchFailed(let error):
                return .loadFailed(underlying: error)
            case .deleteFailed(let error):
                return .deleteFailed(underlying: error)
            case .validationFailed(let message):
                return .validationFailed(message: message)
            }
        }
        return .unknown(persistenceError.localizedDescription)
    }
}
