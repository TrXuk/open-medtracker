import SwiftUI

@main
struct OpenMedTrackerApp: App {
    // Core Data persistence controller
    let persistenceController = PersistenceController.shared

    // Notification service for medication reminders
    let notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
