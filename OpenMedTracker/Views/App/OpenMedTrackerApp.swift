import SwiftUI

@main
struct OpenMedTrackerApp: App {
    // Core Data persistence controller
    let persistenceController = PersistenceController.shared

    // Notification service for medication reminders
    let notificationService = NotificationService()

    // App settings for appearance mode
    @ObservedObject private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch settings.appearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
