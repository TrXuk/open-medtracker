//
//  DoseHistory+CoreDataClass.swift
//  OpenMedTracker
//
//  NSManagedObject subclass for DoseHistory entity
//

import Foundation
import CoreData

@objc(DoseHistory)
public class DoseHistory: NSManagedObject {

    // MARK: - Status Types

    public enum Status: String, CaseIterable {
        case pending = "pending"
        case taken = "taken"
        case missed = "missed"
        case skipped = "skipped"

        var displayName: String {
            rawValue.capitalized
        }

        var emoji: String {
            switch self {
            case .pending: return "⏳"
            case .taken: return "✅"
            case .missed: return "❌"
            case .skipped: return "⏭️"
            }
        }
    }

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdAt")
        setPrimitiveValue("pending", forKey: "status")
        setPrimitiveValue(TimeZone.current.identifier, forKey: "timezoneIdentifier")
    }

    // MARK: - Computed Properties

    /// Typed status enum value
    public var statusEnum: Status {
        get { Status(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }

    /// Whether the dose was taken
    public var wasTaken: Bool {
        statusEnum == .taken
    }

    /// Whether the dose was missed
    public var wasMissed: Bool {
        statusEnum == .missed
    }

    /// Whether the dose is still pending
    public var isPending: Bool {
        statusEnum == .pending
    }

    /// Whether the dose is overdue
    public var isOverdue: Bool {
        isPending && scheduledTime < Date()
    }

    /// Time difference between scheduled and actual time (in seconds)
    public var timeDifference: TimeInterval? {
        guard let actual = actualTime else { return nil }
        return actual.timeIntervalSince(scheduledTime)
    }

    /// Time difference in minutes (positive = late, negative = early)
    public var timeDifferenceMinutes: Double? {
        guard let diff = timeDifference else { return nil }
        return diff / 60.0
    }

    /// Human-readable time difference
    public var timeDifferenceDescription: String? {
        guard let diff = timeDifference else { return nil }

        let absValue = abs(diff)
        let hours = Int(absValue / 3600)
        let minutes = Int((absValue.truncatingRemainder(dividingBy: 3600)) / 60)

        let prefix = diff < 0 ? "early" : "late"

        if hours > 0 {
            return "\(hours)h \(minutes)m \(prefix)"
        } else {
            return "\(minutes)m \(prefix)"
        }
    }

    /// Formatted scheduled time
    public var formattedScheduledTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: timezoneIdentifier)
        return formatter.string(from: scheduledTime)
    }

    /// Formatted actual time (if taken)
    public var formattedActualTime: String? {
        guard let actual = actualTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: timezoneIdentifier)
        return formatter.string(from: actual)
    }

    /// Medication name (convenience accessor)
    public var medicationName: String {
        schedule?.medication?.name ?? "Unknown"
    }

    // MARK: - Helper Methods

    /// Mark the dose as taken
    /// - Parameters:
    ///   - time: The time it was taken (defaults to now)
    ///   - notes: Optional notes about taking the dose
    public func markAsTaken(at time: Date = Date(), notes: String? = nil) {
        statusEnum = .taken
        actualTime = time
        if let notes = notes {
            self.notes = notes
        }
    }

    /// Mark the dose as missed
    /// - Parameter notes: Optional notes about why it was missed
    public func markAsMissed(notes: String? = nil) {
        statusEnum = .missed
        if let notes = notes {
            self.notes = notes
        }
    }

    /// Mark the dose as skipped
    /// - Parameter notes: Optional notes about why it was skipped
    public func markAsSkipped(notes: String? = nil) {
        statusEnum = .skipped
        if let notes = notes {
            self.notes = notes
        }
    }

    /// Reset the dose to pending status
    public func resetToPending() {
        statusEnum = .pending
        actualTime = nil
        notes = nil
    }

    /// Check if the dose is affected by a timezone change
    public var isAffectedByTimezoneChange: Bool {
        timezoneEvent != nil
    }

    /// Get the timezone offset in hours
    public var timezoneOffsetHours: Int {
        guard let tz = TimeZone(identifier: timezoneIdentifier) else { return 0 }
        return tz.secondsFromGMT() / 3600
    }
}
