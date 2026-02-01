import Foundation
import os.log

/// Manages timezone-related functionality including change detection and conversion utilities
/// Designed to support medicine tracking across timezones for international travelers
final class TimezoneManager {

    // MARK: - Singleton

    static let shared = TimezoneManager()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.openmedtracker.app", category: "TimezoneManager")

    /// The reference timezone (typically UTC for medical tracking)
    private(set) var referenceTimezone: TimeZone = TimeZone(identifier: "UTC")!

    /// The current local timezone
    private(set) var localTimezone: TimeZone = TimeZone.current

    /// Notification name for timezone changes
    static let timezoneDidChangeNotification = Notification.Name("TimezoneManagerDidChangeNotification")

    // MARK: - Initialization

    private init() {
        setupTimezoneObserver()
        logCurrentTimezoneState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupTimezoneObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemTimezoneDidChange),
            name: NSNotification.Name.NSSystemTimeZoneDidChange,
            object: nil
        )

        logger.info("TimezoneManager initialized and observing timezone changes")
    }

    // MARK: - Timezone Change Detection

    @objc private func systemTimezoneDidChange(_ notification: Notification) {
        let oldTimezone = localTimezone
        localTimezone = TimeZone.current

        logger.warning("Timezone changed from \(oldTimezone.identifier) to \(self.localTimezone.identifier)")

        logTimezoneChangeEvent(from: oldTimezone, to: localTimezone)

        // Post custom notification for app components to respond
        NotificationCenter.default.post(
            name: TimezoneManager.timezoneDidChangeNotification,
            object: self,
            userInfo: [
                "oldTimezone": oldTimezone,
                "newTimezone": localTimezone
            ]
        )
    }

    // MARK: - Logging

    private func logCurrentTimezoneState() {
        logger.info("Current timezone state:")
        logger.info("  Reference timezone: \(self.referenceTimezone.identifier)")
        logger.info("  Local timezone: \(self.localTimezone.identifier)")
        logger.info("  Local offset from UTC: \(self.localTimezone.secondsFromGMT() / 3600) hours")
    }

    private func logTimezoneChangeEvent(from oldTimezone: TimeZone, to newTimezone: TimeZone) {
        let oldOffset = oldTimezone.secondsFromGMT() / 3600
        let newOffset = newTimezone.secondsFromGMT() / 3600
        let offsetChange = newOffset - oldOffset

        logger.info("Timezone change event:")
        logger.info("  Old: \(oldTimezone.identifier) (UTC\(oldOffset >= 0 ? "+" : "")\(oldOffset))")
        logger.info("  New: \(newTimezone.identifier) (UTC\(newOffset >= 0 ? "+" : "")\(newOffset))")
        logger.info("  Offset change: \(offsetChange) hours")
        logger.info("  Timestamp: \(Date())")
    }

    // MARK: - Timezone Conversion Utilities

    /// Converts a date from UTC to the reference timezone
    /// - Parameter date: Date in UTC
    /// - Returns: Date components adjusted for reference timezone
    func convertUTCToReference(_ date: Date) -> DateComponents {
        let calendar = Calendar.current
        var adjustedCalendar = calendar
        adjustedCalendar.timeZone = referenceTimezone

        return adjustedCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .timeZone],
            from: date
        )
    }

    /// Converts a date from the reference timezone to UTC
    /// - Parameter components: Date components in reference timezone
    /// - Returns: Date in UTC
    func convertReferenceToUTC(_ components: DateComponents) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = referenceTimezone
        return calendar.date(from: components)
    }

    /// Converts a date from UTC to local timezone
    /// - Parameter date: Date in UTC
    /// - Returns: Date components adjusted for local timezone
    func convertUTCToLocal(_ date: Date) -> DateComponents {
        let calendar = Calendar.current
        var adjustedCalendar = calendar
        adjustedCalendar.timeZone = localTimezone

        return adjustedCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .timeZone],
            from: date
        )
    }

    /// Converts a date from local timezone to UTC
    /// - Parameter components: Date components in local timezone
    /// - Returns: Date in UTC
    func convertLocalToUTC(_ components: DateComponents) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = localTimezone
        return calendar.date(from: components)
    }

    /// Converts a date from local timezone to reference timezone
    /// - Parameter date: Date in local timezone
    /// - Returns: Date components adjusted for reference timezone
    func convertLocalToReference(_ date: Date) -> DateComponents {
        // First get the UTC representation, then convert to reference
        let calendar = Calendar.current
        var localCalendar = calendar
        localCalendar.timeZone = localTimezone

        var referenceCalendar = calendar
        referenceCalendar.timeZone = referenceTimezone

        return referenceCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .timeZone],
            from: date
        )
    }

    /// Converts a date from reference timezone to local timezone
    /// - Parameter date: Date in reference timezone
    /// - Returns: Date components adjusted for local timezone
    func convertReferenceToLocal(_ date: Date) -> DateComponents {
        let calendar = Calendar.current
        var referenceCalendar = calendar
        referenceCalendar.timeZone = referenceTimezone

        var localCalendar = calendar
        localCalendar.timeZone = localTimezone

        return localCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .timeZone],
            from: date
        )
    }

    // MARK: - Utility Methods

    /// Gets the current offset between local timezone and reference timezone in seconds
    func offsetBetweenLocalAndReference(for date: Date = Date()) -> Int {
        let localOffset = localTimezone.secondsFromGMT(for: date)
        let referenceOffset = referenceTimezone.secondsFromGMT(for: date)
        return localOffset - referenceOffset
    }

    /// Formats a date for display in a specific timezone
    /// - Parameters:
    ///   - date: The date to format
    ///   - timezone: The timezone to use for formatting
    ///   - dateStyle: The date style
    ///   - timeStyle: The time style
    /// - Returns: Formatted date string
    func formatDate(
        _ date: Date,
        in timezone: TimeZone,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .medium
    ) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: date)
    }

    /// Returns a formatted string showing the current timezone offset
    func currentTimezoneDescription() -> String {
        let offset = localTimezone.secondsFromGMT() / 3600
        let abbreviation = localTimezone.abbreviation() ?? "Unknown"
        return "\(localTimezone.identifier) (\(abbreviation), UTC\(offset >= 0 ? "+" : "")\(offset))"
    }

    // MARK: - Configuration

    /// Updates the reference timezone (useful for testing or if medical standards change)
    /// - Parameter timezone: The new reference timezone
    func setReferenceTimezone(_ timezone: TimeZone) {
        let oldReference = referenceTimezone
        referenceTimezone = timezone

        logger.notice("Reference timezone changed from \(oldReference.identifier) to \(timezone.identifier)")
    }
}

// MARK: - Timezone Extension Utilities

extension TimeZone {
    /// Returns a human-readable description of the timezone
    var detailedDescription: String {
        let offset = secondsFromGMT() / 3600
        let abbreviation = self.abbreviation() ?? "Unknown"
        return "\(identifier) (\(abbreviation), UTC\(offset >= 0 ? "+" : "")\(offset))"
    }
}

// MARK: - Date Extension Utilities

extension Date {
    /// Returns the date formatted in UTC timezone
    func toUTCString(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .medium) -> String {
        return TimezoneManager.shared.formatDate(
            self,
            in: TimeZone(identifier: "UTC")!,
            dateStyle: dateStyle,
            timeStyle: timeStyle
        )
    }

    /// Returns the date formatted in local timezone
    func toLocalString(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .medium) -> String {
        return TimezoneManager.shared.formatDate(
            self,
            in: TimezoneManager.shared.localTimezone,
            dateStyle: dateStyle,
            timeStyle: timeStyle
        )
    }
}
