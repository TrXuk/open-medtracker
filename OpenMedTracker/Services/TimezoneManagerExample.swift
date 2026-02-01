import Foundation

/// Example usage of TimezoneManager for medication tracking scenarios
class TimezoneManagerExample {

    static func demonstrateBasicUsage() {
        print("=== TimezoneManager Basic Usage ===\n")

        let manager = TimezoneManager.shared

        // Display current timezone state
        print("Current Timezone: \(manager.currentTimezoneDescription())")
        print("Reference Timezone: \(manager.referenceTimezone.detailedDescription)")
        print()
    }

    static func demonstrateMedicationScheduling() {
        print("=== Medication Scheduling Example ===\n")

        let manager = TimezoneManager.shared

        // Scenario: User sets medication for 8:00 AM and 8:00 PM local time
        print("Setting up medication schedule...")

        // Morning dose - 8:00 AM local time
        var morningLocal = DateComponents()
        morningLocal.year = 2024
        morningLocal.month = 6
        morningLocal.day = 15
        morningLocal.hour = 8
        morningLocal.minute = 0

        if let morningUTC = manager.convertLocalToUTC(morningLocal) {
            print("Morning dose (8:00 AM local) stored as: \(morningUTC.toUTCString())")
        }

        // Evening dose - 8:00 PM local time
        var eveningLocal = DateComponents()
        eveningLocal.year = 2024
        eveningLocal.month = 6
        eveningLocal.day = 15
        eveningLocal.hour = 20
        eveningLocal.minute = 0

        if let eveningUTC = manager.convertLocalToUTC(eveningLocal) {
            print("Evening dose (8:00 PM local) stored as: \(eveningUTC.toUTCString())")
        }

        print()
    }

    static func demonstrateTravelScenario() {
        print("=== International Travel Scenario ===\n")

        let manager = TimezoneManager.shared

        // User is in New York (UTC-5) and scheduled medication for 9:00 AM
        print("Scenario: User in New York schedules 9:00 AM medication")

        var nyComponents = DateComponents()
        nyComponents.year = 2024
        nyComponents.month = 6
        nyComponents.day = 15
        nyComponents.hour = 9
        nyComponents.minute = 0
        nyComponents.timeZone = TimeZone(identifier: "America/New_York")!

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "America/New_York")!

        guard let nyDate = calendar.date(from: nyComponents) else {
            print("Failed to create date")
            return
        }

        print("New York time: \(manager.formatDate(nyDate, in: TimeZone(identifier: "America/New_York")!))")
        print("UTC time: \(nyDate.toUTCString())")

        // User travels to Tokyo (UTC+9)
        print("\nUser travels to Tokyo...")
        let tokyoComponents = manager.convertUTCToLocal(nyDate)
        print("Tokyo time (if local timezone is Tokyo): \(tokyoComponents.hour ?? 0):\(String(format: "%02d", tokyoComponents.minute ?? 0))")
        print("This ensures medication is taken at the correct biological time!")

        print()
    }

    static func demonstrateTimezoneChangeHandling() {
        print("=== Timezone Change Handling ===\n")

        // Register for timezone change notifications
        let observer = NotificationCenter.default.addObserver(
            forName: TimezoneManager.timezoneDidChangeNotification,
            object: nil,
            queue: .main
        ) { notification in
            print("⚠️  Timezone changed!")

            if let oldTimezone = notification.userInfo?["oldTimezone"] as? TimeZone,
               let newTimezone = notification.userInfo?["newTimezone"] as? TimeZone {
                print("   Old: \(oldTimezone.identifier)")
                print("   New: \(newTimezone.identifier)")

                // In a real app, you would:
                // 1. Update local notification times
                // 2. Recalculate next medication times
                // 3. Update UI
                // 4. Log event for travel tracking
            }
        }

        print("Observer registered for timezone changes")
        print("The app will automatically respond when the system timezone changes")
        print()

        // Clean up (in real app, this would be in deinit)
        NotificationCenter.default.removeObserver(observer)
    }

    static func demonstrateOffsetCalculations() {
        print("=== Timezone Offset Calculations ===\n")

        let manager = TimezoneManager.shared

        let offset = manager.offsetBetweenLocalAndReference()
        let hours = offset / 3600
        let minutes = abs(offset % 3600) / 60

        print("Current offset from reference timezone:")
        if hours >= 0 {
            print("  +\(hours) hours \(minutes) minutes")
        } else {
            print("  \(hours) hours \(minutes) minutes")
        }

        // Check if DST might affect future schedules
        let futureDate = Date().addingTimeInterval(86400 * 180) // 6 months from now
        let futureOffset = manager.offsetBetweenLocalAndReference(for: futureDate)

        if offset != futureOffset {
            print("\n⚠️  Note: Offset changes in 6 months (likely DST)")
            print("  Current: \(offset / 3600) hours")
            print("  Future: \(futureOffset / 3600) hours")
            print("  Medication times may need adjustment!")
        }

        print()
    }

    static func runAllExamples() {
        print("\n" + String(repeating: "=", count: 60))
        print("OpenMedTracker - TimezoneManager Examples")
        print(String(repeating: "=", count: 60) + "\n")

        demonstrateBasicUsage()
        demonstrateMedicationScheduling()
        demonstrateTravelScenario()
        demonstrateTimezoneChangeHandling()
        demonstrateOffsetCalculations()

        print(String(repeating: "=", count: 60))
        print("Examples completed!")
        print(String(repeating: "=", count: 60) + "\n")
    }
}

// Uncomment to run examples:
// TimezoneManagerExample.runAllExamples()
