//
//  AppSettings.swift
//  OpenMedTracker
//
//  Model for managing app settings using UserDefaults
//

import Foundation

/// Manages app-wide settings persisted to UserDefaults
final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let notificationsEnabled = "notificationsEnabled"
        static let notificationSound = "notificationSound"
        static let snoozeEnabled = "snoozeEnabled"
        static let snoozeDuration = "snoozeDuration"

        static let preferredTimezone = "preferredTimezone"
        static let autoDetectTimezone = "autoDetectTimezone"

        static let appearance = "appearance"

        static let hasSeenWelcome = "hasSeenWelcome"
        static let lastExportDate = "lastExportDate"
    }

    // MARK: - Notification Settings

    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        }
    }

    @Published var notificationSound: Bool {
        didSet {
            defaults.set(notificationSound, forKey: Keys.notificationSound)
        }
    }

    @Published var snoozeEnabled: Bool {
        didSet {
            defaults.set(snoozeEnabled, forKey: Keys.snoozeEnabled)
        }
    }

    @Published var snoozeDuration: Int {
        didSet {
            defaults.set(snoozeDuration, forKey: Keys.snoozeDuration)
        }
    }

    // MARK: - Timezone Settings

    @Published var preferredTimezone: String? {
        didSet {
            if let timezone = preferredTimezone {
                defaults.set(timezone, forKey: Keys.preferredTimezone)
            } else {
                defaults.removeObject(forKey: Keys.preferredTimezone)
            }
        }
    }

    @Published var autoDetectTimezone: Bool {
        didSet {
            defaults.set(autoDetectTimezone, forKey: Keys.autoDetectTimezone)
        }
    }

    // MARK: - Appearance Settings

    @Published var appearance: AppearanceMode {
        didSet {
            defaults.set(appearance.rawValue, forKey: Keys.appearance)
        }
    }

    // MARK: - Other

    var hasSeenWelcome: Bool {
        get { defaults.bool(forKey: Keys.hasSeenWelcome) }
        set { defaults.set(newValue, forKey: Keys.hasSeenWelcome) }
    }

    var lastExportDate: Date? {
        get { defaults.object(forKey: Keys.lastExportDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastExportDate) }
    }

    // MARK: - Initialization

    private init() {
        // Load settings from UserDefaults
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        self.notificationSound = defaults.object(forKey: Keys.notificationSound) as? Bool ?? true
        self.snoozeEnabled = defaults.object(forKey: Keys.snoozeEnabled) as? Bool ?? true
        self.snoozeDuration = defaults.object(forKey: Keys.snoozeDuration) as? Int ?? 10

        self.preferredTimezone = defaults.string(forKey: Keys.preferredTimezone)
        self.autoDetectTimezone = defaults.object(forKey: Keys.autoDetectTimezone) as? Bool ?? true

        let appearanceValue = defaults.string(forKey: Keys.appearance) ?? AppearanceMode.system.rawValue
        self.appearance = AppearanceMode(rawValue: appearanceValue) ?? .system
    }

    // MARK: - Reset

    /// Reset all settings to defaults
    func resetToDefaults() {
        notificationsEnabled = true
        notificationSound = true
        snoozeEnabled = true
        snoozeDuration = 10

        preferredTimezone = nil
        autoDetectTimezone = true

        appearance = .system
    }
}

// MARK: - AppearanceMode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
