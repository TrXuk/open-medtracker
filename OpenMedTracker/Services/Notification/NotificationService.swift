//
//  NotificationService.swift
//  OpenMedTracker
//
//  Service for managing local notifications for medication reminders
//

import Foundation
import UserNotifications
import CoreData
import os.log

/// Service for scheduling and managing medication reminder notifications
public final class NotificationService: NSObject {

    // MARK: - Properties

    private let persistenceController: PersistenceController
    private let scheduleService: ScheduleService
    private let doseHistoryService: DoseHistoryService
    private let notificationCenter: UNUserNotificationCenter
    private let logger = Logger(subsystem: "com.openmedtracker.app", category: "NotificationService")

    /// Notification category identifier for medication reminders
    private static let medicationReminderCategory = "MEDICATION_REMINDER"

    /// Action identifiers
    private static let markAsTakenActionID = "MARK_AS_TAKEN"
    private static let skipActionID = "SKIP"
    private static let snoozeActionID = "SNOOZE"

    /// User info keys
    private static let scheduleIDKey = "scheduleID"
    private static let medicationNameKey = "medicationName"
    private static let scheduledTimeKey = "scheduledTime"

    // MARK: - Initialization

    public init(
        persistenceController: PersistenceController = .shared,
        notificationCenter: UNUserNotificationCenter = .current()
    ) {
        self.persistenceController = persistenceController
        self.scheduleService = ScheduleService(persistenceController: persistenceController)
        self.doseHistoryService = DoseHistoryService(persistenceController: persistenceController)
        self.notificationCenter = notificationCenter

        super.init()

        setupNotificationCategories()
        setupTimezoneObserver()
        notificationCenter.delegate = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupNotificationCategories() {
        let markAsTakenAction = UNNotificationAction(
            identifier: Self.markAsTakenActionID,
            title: "Mark as Taken",
            options: [.foreground]
        )

        let skipAction = UNNotificationAction(
            identifier: Self.skipActionID,
            title: "Skip",
            options: [.destructive]
        )

        let snoozeAction = UNNotificationAction(
            identifier: Self.snoozeActionID,
            title: "Snooze 10 min",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: Self.medicationReminderCategory,
            actions: [markAsTakenAction, snoozeAction, skipAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        notificationCenter.setNotificationCategories([category])
        logger.info("Notification categories configured")
    }

    private func setupTimezoneObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timezoneDidChange),
            name: TimezoneManager.timezoneDidChangeNotification,
            object: nil
        )
        logger.info("Timezone observer configured")
    }

    // MARK: - Permission

    /// Request notification permission from the user
    /// - Returns: True if permission granted, false otherwise
    public func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]

        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            logger.info("Notification permission: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Failed to request notification permission: \(error.localizedDescription)")
            throw NotificationError.authorizationFailed(error)
        }
    }

    /// Check current notification authorization status
    /// - Returns: Current authorization status
    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Scheduling

    /// Schedule notifications for a specific schedule
    /// - Parameters:
    ///   - schedule: The schedule to create notifications for
    ///   - daysAhead: Number of days to schedule ahead (default: 7)
    /// - Throws: NotificationError if scheduling fails
    public func scheduleNotifications(for schedule: Schedule, daysAhead: Int = 7) async throws {
        guard schedule.isEnabled else {
            logger.debug("Skipping disabled schedule: \(schedule.id)")
            return
        }

        guard let medication = schedule.medication else {
            logger.warning("Schedule \(schedule.id) has no medication, skipping")
            return
        }

        // Cancel existing notifications for this schedule
        await cancelNotifications(for: schedule)

        let calendar = Calendar.current
        let now = Date()
        var scheduledCount = 0

        // Schedule notifications for the next N days
        for dayOffset in 0..<daysAhead {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else {
                continue
            }

            // Check if schedule is due on this day
            guard schedule.isDueOn(date: targetDate) else {
                continue
            }

            // Get the scheduled time for this day
            let timeComponents = calendar.dateComponents([.hour, .minute], from: schedule.timeOfDay)

            guard let scheduledTime = calendar.date(
                bySettingHour: timeComponents.hour ?? 0,
                minute: timeComponents.minute ?? 0,
                second: 0,
                of: targetDate
            ) else {
                continue
            }

            // Skip if time has already passed
            guard scheduledTime > now else {
                continue
            }

            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Medication Reminder"
            content.body = "\(medication.name) (\(medication.dosageAmount) \(medication.dosageUnit))"
            content.sound = .default
            content.categoryIdentifier = Self.medicationReminderCategory
            content.userInfo = [
                Self.scheduleIDKey: schedule.id.uuidString,
                Self.medicationNameKey: medication.name,
                Self.scheduledTimeKey: scheduledTime.timeIntervalSince1970
            ]

            // Create trigger
            let triggerDateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: scheduledTime
            )
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: triggerDateComponents,
                repeats: false
            )

            // Create request
            let identifier = notificationIdentifier(for: schedule, at: scheduledTime)
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            // Add notification
            do {
                try await notificationCenter.add(request)
                scheduledCount += 1
            } catch {
                logger.error("Failed to schedule notification: \(error.localizedDescription)")
                throw NotificationError.schedulingFailed(error)
            }
        }

        logger.info("Scheduled \(scheduledCount) notifications for schedule \(schedule.id)")
    }

    /// Schedule notifications for all active schedules
    /// - Parameter daysAhead: Number of days to schedule ahead (default: 7)
    /// - Throws: NotificationError if scheduling fails
    public func scheduleAllNotifications(daysAhead: Int = 7) async throws {
        let schedules = try scheduleService.fetchAll(includeDisabled: false)

        logger.info("Scheduling notifications for \(schedules.count) active schedules")

        for schedule in schedules {
            try await scheduleNotifications(for: schedule, daysAhead: daysAhead)
        }

        logger.info("All notifications scheduled")
    }

    /// Cancel notifications for a specific schedule
    /// - Parameter schedule: The schedule to cancel notifications for
    public func cancelNotifications(for schedule: Schedule) async {
        let calendar = Calendar.current
        let now = Date()
        var identifiers: [String] = []

        // Generate identifiers for the next 30 days (to catch all possible notifications)
        for dayOffset in 0..<30 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else {
                continue
            }

            let timeComponents = calendar.dateComponents([.hour, .minute], from: schedule.timeOfDay)

            guard let scheduledTime = calendar.date(
                bySettingHour: timeComponents.hour ?? 0,
                minute: timeComponents.minute ?? 0,
                second: 0,
                of: targetDate
            ) else {
                continue
            }

            identifiers.append(notificationIdentifier(for: schedule, at: scheduledTime))
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        logger.info("Cancelled notifications for schedule \(schedule.id)")
    }

    /// Cancel all pending notifications
    public func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        logger.info("Cancelled all pending notifications")
    }

    // MARK: - Timezone Change Handling

    @objc private func timezoneDidChange(_ notification: Notification) {
        logger.warning("Timezone change detected, rescheduling all notifications")

        Task {
            do {
                // Cancel all existing notifications
                cancelAllNotifications()

                // Reschedule all notifications with new timezone
                try await scheduleAllNotifications()

                logger.info("Successfully rescheduled notifications after timezone change")
            } catch {
                logger.error("Failed to reschedule notifications after timezone change: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helper Methods

    private func notificationIdentifier(for schedule: Schedule, at date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        let dateString = formatter.string(from: date)
        return "med-\(schedule.id.uuidString)-\(dateString)"
    }

    private func scheduleFromNotification(_ notification: UNNotification) throws -> Schedule? {
        guard let scheduleIDString = notification.request.content.userInfo[Self.scheduleIDKey] as? String,
              let scheduleID = UUID(uuidString: scheduleIDString) else {
            throw NotificationError.invalidNotificationData
        }

        return try scheduleService.fetch(id: scheduleID)
    }

    // MARK: - Errors

    public enum NotificationError: LocalizedError {
        case authorizationFailed(Error)
        case schedulingFailed(Error)
        case invalidNotificationData
        case scheduleNotFound

        public var errorDescription: String? {
            switch self {
            case .authorizationFailed(let error):
                return "Failed to authorize notifications: \(error.localizedDescription)"
            case .schedulingFailed(let error):
                return "Failed to schedule notification: \(error.localizedDescription)"
            case .invalidNotificationData:
                return "Notification contains invalid data"
            case .scheduleNotFound:
                return "Schedule not found for notification"
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {

    /// Handle notification when app is in foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification response (user tapped notification or action)
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task {
            do {
                try await handleNotificationResponse(response)
            } catch {
                logger.error("Failed to handle notification response: \(error.localizedDescription)")
            }
            completionHandler()
        }
    }

    private func handleNotificationResponse(_ response: UNNotificationResponse) async throws {
        let notification = response.notification

        guard let schedule = try scheduleFromNotification(notification) else {
            throw NotificationError.scheduleNotFound
        }

        guard let scheduledTimeInterval = notification.request.content.userInfo[Self.scheduledTimeKey] as? TimeInterval else {
            throw NotificationError.invalidNotificationData
        }

        let scheduledTime = Date(timeIntervalSince1970: scheduledTimeInterval)

        // Create or find dose history for this notification
        let doseHistory = try doseHistoryService.create(
            for: schedule,
            scheduledTime: scheduledTime
        )

        switch response.actionIdentifier {
        case Self.markAsTakenActionID:
            try doseHistoryService.markAsTaken(doseHistory, at: Date())
            logger.info("Dose marked as taken via notification action")

        case Self.skipActionID:
            try doseHistoryService.markAsSkipped(doseHistory, notes: "Skipped via notification")
            logger.info("Dose marked as skipped via notification action")

        case Self.snoozeActionID:
            // Reschedule notification for 10 minutes from now
            try await scheduleSnoozeNotification(for: schedule, doseHistory: doseHistory)
            logger.info("Dose snoozed for 10 minutes")

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself (not an action)
            // Could navigate to a detail view or recording screen
            logger.info("User tapped notification")

        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            logger.info("User dismissed notification")

        default:
            logger.warning("Unknown notification action: \(response.actionIdentifier)")
        }
    }

    private func scheduleSnoozeNotification(for schedule: Schedule, doseHistory: DoseHistory) async throws {
        guard let medication = schedule.medication else {
            throw NotificationError.scheduleNotFound
        }

        let snoozeTime = Date().addingTimeInterval(10 * 60) // 10 minutes

        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder (Snoozed)"
        content.body = "\(medication.name) (\(medication.dosageAmount) \(medication.dosageUnit))"
        content.sound = .default
        content.categoryIdentifier = Self.medicationReminderCategory
        content.userInfo = [
            Self.scheduleIDKey: schedule.id.uuidString,
            Self.medicationNameKey: medication.name,
            Self.scheduledTimeKey: doseHistory.scheduledTime.timeIntervalSince1970
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10 * 60, repeats: false)

        let identifier = "snooze-\(doseHistory.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)
    }
}
