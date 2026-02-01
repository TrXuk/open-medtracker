//
//  SettingsViewModel.swift
//  OpenMedTracker
//
//  ViewModel for managing settings screen logic
//

import Foundation
import CoreData
import UniformTypeIdentifiers
import os.log

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Properties

    @Published var settings = AppSettings.shared
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let persistenceController: PersistenceController
    private let notificationService: NotificationService
    private let logger = Logger(subsystem: "com.openmedtracker.app", category: "SettingsViewModel")

    // MARK: - Computed Properties

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var fullVersionString: String {
        "Version \(appVersion) (\(buildNumber))"
    }

    var currentTimezone: String {
        TimeZone.current.identifier
    }

    // MARK: - Initialization

    init(
        persistenceController: PersistenceController = .shared,
        notificationService: NotificationService = NotificationService()
    ) {
        self.persistenceController = persistenceController
        self.notificationService = notificationService
    }

    // MARK: - Notification Actions

    func requestNotificationPermission() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let granted = try await notificationService.requestAuthorization()
            if granted {
                settings.notificationsEnabled = true
                successMessage = "Notification permission granted"
                logger.info("Notification permission granted")

                // Schedule notifications for active schedules
                try await notificationService.scheduleAllNotifications()
            } else {
                settings.notificationsEnabled = false
                errorMessage = "Notification permission denied. Please enable in Settings."
                logger.warning("Notification permission denied")
            }
        } catch {
            errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
            logger.error("Failed to request notification permission: \(error.localizedDescription)")
        }
    }

    func toggleNotifications(_ enabled: Bool) async {
        if enabled {
            await requestNotificationPermission()
        } else {
            notificationService.cancelAllNotifications()
            settings.notificationsEnabled = false
            logger.info("Notifications disabled")
        }
    }

    // MARK: - Data Management

    func exportData() async -> URL? {
        isLoading = true
        defer { isLoading = false }

        do {
            let context = persistenceController.container.viewContext

            // Create export data structure
            let medications = try context.fetch(Medication.fetchRequest()) as [Medication]
            let schedules = try context.fetch(Schedule.fetchRequest()) as [Schedule]
            let doseHistory = try context.fetch(DoseHistory.fetchRequest()) as [DoseHistory]
            let timezoneEvents = try context.fetch(TimezoneEvent.fetchRequest()) as [TimezoneEvent]

            // Convert to exportable format
            let exportData: [String: Any] = [
                "version": appVersion,
                "exportDate": ISO8601DateFormatter().string(from: Date()),
                "medications": medications.map { medicationToDict($0) },
                "schedules": schedules.map { scheduleToDict($0) },
                "doseHistory": doseHistory.map { doseHistoryToDict($0) },
                "timezoneEvents": timezoneEvents.map { timezoneEventToDict($0) }
            ]

            // Convert to JSON
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)

            // Save to temporary file
            let temporaryDirectory = FileManager.default.temporaryDirectory
            let fileName = "OpenMedTracker_Export_\(Date().timeIntervalSince1970).json"
            let fileURL = temporaryDirectory.appendingPathComponent(fileName)

            try jsonData.write(to: fileURL)

            settings.lastExportDate = Date()
            successMessage = "Data exported successfully"
            logger.info("Data exported to \(fileURL.path)")

            return fileURL
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
            logger.error("Failed to export data: \(error.localizedDescription)")
            return nil
        }
    }

    func importData(from url: URL) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Read file
            let jsonData = try Data(contentsOf: url)
            guard let exportData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw NSError(domain: "com.openmedtracker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid export file format"])
            }

            // TODO: Implement full import logic
            // This is a placeholder - full implementation would:
            // 1. Validate data structure
            // 2. Create confirmation dialog
            // 3. Import medications, schedules, history
            // 4. Handle conflicts

            successMessage = "Import functionality coming soon"
            logger.info("Import initiated from \(url.path)")

        } catch {
            errorMessage = "Failed to import data: \(error.localizedDescription)"
            logger.error("Failed to import data: \(error.localizedDescription)")
        }
    }

    func clearAllData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let context = persistenceController.container.viewContext

            // Fetch and delete all entities
            let medications = try context.fetch(Medication.fetchRequest()) as [Medication]
            let schedules = try context.fetch(Schedule.fetchRequest()) as [Schedule]
            let doseHistory = try context.fetch(DoseHistory.fetchRequest()) as [DoseHistory]
            let timezoneEvents = try context.fetch(TimezoneEvent.fetchRequest()) as [TimezoneEvent]

            medications.forEach { context.delete($0) }
            schedules.forEach { context.delete($0) }
            doseHistory.forEach { context.delete($0) }
            timezoneEvents.forEach { context.delete($0) }

            try context.save()

            // Cancel all notifications
            notificationService.cancelAllNotifications()

            successMessage = "All data cleared successfully"
            logger.warning("All data cleared")

        } catch {
            errorMessage = "Failed to clear data: \(error.localizedDescription)"
            logger.error("Failed to clear data: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    private func medicationToDict(_ medication: Medication) -> [String: Any] {
        [
            "id": medication.id.uuidString,
            "name": medication.name,
            "dosageAmount": medication.dosageAmount,
            "dosageUnit": medication.dosageUnit,
            "instructions": medication.instructions ?? "",
            "isActive": medication.isActive,
            "createdAt": ISO8601DateFormatter().string(from: medication.createdAt)
        ]
    }

    private func scheduleToDict(_ schedule: Schedule) -> [String: Any] {
        [
            "id": schedule.id.uuidString,
            "medicationId": schedule.medication?.id.uuidString ?? "",
            "timeOfDay": ISO8601DateFormatter().string(from: schedule.timeOfDay),
            "frequency": schedule.frequency,
            "isEnabled": schedule.isEnabled,
            "createdAt": ISO8601DateFormatter().string(from: schedule.createdAt)
        ]
    }

    private func doseHistoryToDict(_ history: DoseHistory) -> [String: Any] {
        [
            "id": history.id.uuidString,
            "scheduleId": history.schedule?.id.uuidString ?? "",
            "scheduledTime": ISO8601DateFormatter().string(from: history.scheduledTime),
            "actualTime": history.actualTime.map { ISO8601DateFormatter().string(from: $0) } ?? "",
            "status": history.status,
            "notes": history.notes ?? ""
        ]
    }

    private func timezoneEventToDict(_ event: TimezoneEvent) -> [String: Any] {
        [
            "id": event.id.uuidString,
            "eventDate": ISO8601DateFormatter().string(from: event.eventDate),
            "fromTimezone": event.fromTimezone,
            "toTimezone": event.toTimezone,
            "offsetMinutes": event.offsetMinutes
        ]
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
