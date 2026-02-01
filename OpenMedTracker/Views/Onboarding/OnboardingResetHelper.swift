import Foundation

/// Helper for resetting onboarding during development and testing
/// This is primarily for development convenience and testing
struct OnboardingResetHelper {

    /// The UserDefaults key for onboarding completion
    static let onboardingKey = "hasCompletedOnboarding"

    /// Reset onboarding to show it again on next launch
    /// - Note: This requires app restart to take effect
    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: onboardingKey)
        UserDefaults.standard.synchronize()
    }

    /// Check if user has completed onboarding
    static func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: onboardingKey)
    }

    /// Force set onboarding completion state
    /// - Parameter completed: The completion state to set
    static func setOnboardingComplete(_ completed: Bool) {
        UserDefaults.standard.set(completed, forKey: onboardingKey)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Development/Testing Extensions

#if DEBUG
extension OnboardingResetHelper {

    /// Print current onboarding state (DEBUG only)
    static func debugPrintStatus() {
        print("=== Onboarding Status ===")
        print("Completed: \(hasCompletedOnboarding())")
        print("========================")
    }

    /// Example usage in a SwiftUI view for testing:
    ///
    ///     Button("Reset Onboarding (Dev)") {
    ///         OnboardingResetHelper.resetOnboarding()
    ///         // Note: Requires app restart
    ///         // You can trigger with: exit(0) or fatalError("Restart to see onboarding")
    ///     }
    ///
}
#endif
