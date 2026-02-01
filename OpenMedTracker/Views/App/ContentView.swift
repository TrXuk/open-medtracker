import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MedicationListView()
                .tabItem {
                    Label("Medications", systemImage: "pill.fill")
                }
                .tag(0)
                .accessibilityLabel("Medications")
                .accessibilityHint("View and manage your medications")

            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(1)
                .accessibilityLabel("Schedule")
                .accessibilityHint("View daily dose schedule")

            DoseHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(2)
                .accessibilityLabel("History")
                .accessibilityHint("View dose history and adherence statistics")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
                .accessibilityLabel("Settings")
                .accessibilityHint("Configure app preferences and notification settings")
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
