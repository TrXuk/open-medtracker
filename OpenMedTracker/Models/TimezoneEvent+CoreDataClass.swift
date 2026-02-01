//
//  TimezoneEvent+CoreDataClass.swift
//  OpenMedTracker
//
//  NSManagedObject subclass for TimezoneEvent entity
//

import Foundation
import CoreData

@objc(TimezoneEvent)
public class TimezoneEvent: NSManagedObject {

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdAt")
        setPrimitiveValue(TimeZone.current.identifier, forKey: "newTimezone")
    }

    // MARK: - Computed Properties

    /// Previous timezone object
    public var previousTimezoneObject: TimeZone? {
        TimeZone(identifier: previousTimezone)
    }

    /// New timezone object
    public var newTimezoneObject: TimeZone? {
        TimeZone(identifier: newTimezone)
    }

    /// Time difference in hours between the two timezones
    public var timeDifferenceHours: Int {
        guard let prev = previousTimezoneObject,
              let new = newTimezoneObject else { return 0 }

        let prevOffset = prev.secondsFromGMT(for: transitionTime)
        let newOffset = new.secondsFromGMT(for: transitionTime)

        return (newOffset - prevOffset) / 3600
    }

    /// Formatted time difference string (e.g., "+5 hours", "-3 hours")
    public var formattedTimeDifference: String {
        let hours = timeDifferenceHours
        let sign = hours >= 0 ? "+" : ""
        return "\(sign)\(hours) hours"
    }

    /// Human-readable description of the timezone change
    public var changeDescription: String {
        let prevAbbr = previousTimezoneObject?.abbreviation(for: transitionTime) ?? previousTimezone
        let newAbbr = newTimezoneObject?.abbreviation(for: transitionTime) ?? newTimezone

        return "\(prevAbbr) → \(newAbbr) (\(formattedTimeDifference))"
    }

    /// Formatted transition time
    public var formattedTransitionTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = newTimezoneObject
        return formatter.string(from: transitionTime)
    }

    /// Number of doses affected by this timezone change
    public var affectedDoseCount: Int {
        affectedDoses?.count ?? 0
    }

    /// Array of affected doses sorted by scheduled time
    public var sortedAffectedDoses: [DoseHistory] {
        let doseArray = affectedDoses?.allObjects as? [DoseHistory] ?? []
        return doseArray.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    /// Whether this was a forward timezone change (traveling east)
    public var isForwardChange: Bool {
        timeDifferenceHours > 0
    }

    /// Whether this was a backward timezone change (traveling west)
    public var isBackwardChange: Bool {
        timeDifferenceHours < 0
    }

    /// Magnitude of timezone change (absolute hours)
    public var changeMangnitude: Int {
        abs(timeDifferenceHours)
    }

    // MARK: - Helper Methods

    /// Calculate adjusted time for a dose based on this timezone change
    /// - Parameter originalTime: The original scheduled time
    /// - Returns: The adjusted time in the new timezone
    public func adjustedTime(for originalTime: Date) -> Date {
        // Check if the dose time is after the transition
        guard originalTime >= transitionTime else {
            return originalTime
        }

        let calendar = Calendar.current
        let offset = timeDifferenceHours

        return calendar.date(byAdding: .hour, value: offset, to: originalTime) ?? originalTime
    }

    /// Get a list of timezone identifiers that are close to the new timezone
    /// Useful for suggesting corrections if the timezone seems incorrect
    public static func similarTimezones(to identifier: String) -> [String] {
        guard let targetTimezone = TimeZone(identifier: identifier) else {
            return []
        }

        let targetOffset = targetTimezone.secondsFromGMT()

        return TimeZone.knownTimeZoneIdentifiers.filter { tzId in
            guard let tz = TimeZone(identifier: tzId) else { return false }
            return abs(tz.secondsFromGMT() - targetOffset) <= 3600 // Within 1 hour
        }
    }

    /// Validate that the timezone identifiers are valid
    /// - Returns: True if both timezones are valid
    public func validateTimezones() -> Bool {
        previousTimezoneObject != nil && newTimezoneObject != nil
    }
}
