//
//  DateFormatter+Extensions.swift
//  MedTracker
//
//  Date formatting utilities
//

import Foundation

extension DateFormatter {
    static let medTrackerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let medTrackerShortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}
