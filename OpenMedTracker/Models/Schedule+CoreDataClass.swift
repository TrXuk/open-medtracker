//
//  Schedule+CoreDataClass.swift
//  OpenMedTracker
//
//  NSManagedObject subclass for Schedule entity
//

import Foundation
import CoreData

@objc(Schedule)
public class Schedule: NSManagedObject {

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdAt")
        setPrimitiveValue(Date(), forKey: "updatedAt")
        setPrimitiveValue(true, forKey: "isEnabled")
        setPrimitiveValue("daily", forKey: "frequency")
        setPrimitiveValue(Int16(127), forKey: "daysOfWeek") // All days
    }

    public override func willSave() {
        super.willSave()
        if !isDeleted && isUpdated {
            setPrimitiveValue(Date(), forKey: "updatedAt")
        }
    }

    // MARK: - Days of Week Helper

    public enum DayOfWeek: Int, CaseIterable {
        case sunday = 0
        case monday = 1
        case tuesday = 2
        case wednesday = 3
        case thursday = 4
        case friday = 5
        case saturday = 6

        var bit: Int16 {
            Int16(1 << rawValue)
        }

        var name: String {
            let formatter = DateFormatter()
            return formatter.weekdaySymbols[rawValue]
        }

        var shortName: String {
            let formatter = DateFormatter()
            return formatter.shortWeekdaySymbols[rawValue]
        }
    }

    // MARK: - Computed Properties

    /// Formatted time string (e.g., "9:00 AM")
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timeOfDay)
    }

    /// Array of enabled days
    public var enabledDays: [DayOfWeek] {
        DayOfWeek.allCases.filter { isDayEnabled($0) }
    }

    /// Human-readable description of the schedule
    public var scheduleDescription: String {
        let days = enabledDays.map { $0.shortName }.joined(separator: ", ")
        return "\(formattedTime) - \(days)"
    }

    /// Whether this schedule is for every day
    public var isEveryday: Bool {
        daysOfWeek == 127
    }

    /// Whether this schedule is for weekdays only
    public var isWeekdaysOnly: Bool {
        daysOfWeek == 62 // Monday-Friday
    }

    /// Whether this schedule is for weekends only
    public var isWeekendsOnly: Bool {
        daysOfWeek == 65 // Saturday-Sunday
    }

    // MARK: - Helper Methods

    /// Check if a specific day is enabled
    /// - Parameter day: The day to check
    /// - Returns: True if the day is enabled in the schedule
    public func isDayEnabled(_ day: DayOfWeek) -> Bool {
        (daysOfWeek & day.bit) != 0
    }

    /// Enable a specific day
    /// - Parameter day: The day to enable
    public func enableDay(_ day: DayOfWeek) {
        daysOfWeek |= day.bit
    }

    /// Disable a specific day
    /// - Parameter day: The day to disable
    public func disableDay(_ day: DayOfWeek) {
        daysOfWeek &= ~day.bit
    }

    /// Toggle a specific day
    /// - Parameter day: The day to toggle
    public func toggleDay(_ day: DayOfWeek) {
        daysOfWeek ^= day.bit
    }

    /// Check if this schedule should fire on a given date
    /// - Parameter date: The date to check
    /// - Returns: True if the schedule is active on this date
    public func isDueOn(date: Date) -> Bool {
        guard isEnabled else { return false }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let day = DayOfWeek(rawValue: weekday - 1) ?? .sunday

        return isDayEnabled(day)
    }

    /// Get the next scheduled time after a given date
    /// - Parameter afterDate: The reference date (defaults to now)
    /// - Returns: The next scheduled date/time, or nil if schedule is disabled
    public func nextScheduledTime(after afterDate: Date = Date()) -> Date? {
        guard isEnabled else { return nil }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOfDay)

        // Try each day in the next week
        for dayOffset in 0..<7 {
            guard let candidateDate = calendar.date(byAdding: .day, value: dayOffset, to: afterDate) else {
                continue
            }

            guard let candidateWithTime = calendar.date(
                bySettingHour: timeComponents.hour ?? 0,
                minute: timeComponents.minute ?? 0,
                second: 0,
                of: candidateDate
            ) else {
                continue
            }

            // Skip if this time has already passed today
            if dayOffset == 0 && candidateWithTime <= afterDate {
                continue
            }

            if isDueOn(date: candidateDate) {
                return candidateWithTime
            }
        }

        return nil
    }
}
