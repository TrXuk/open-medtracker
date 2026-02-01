import SwiftUI

/// Main onboarding flow container with page navigation
struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0

    private let totalPages = 4

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .foregroundColor(.blue)
                        .padding()
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    WelcomePageView()
                        .tag(0)

                    FeaturePageView(
                        icon: "pills.circle.fill",
                        title: "Track Your Medications",
                        description: "Easily manage all your medications with customizable schedules and dose reminders."
                    )
                    .tag(1)

                    FeaturePageView(
                        icon: "globe.americas.fill",
                        title: "Travel with Confidence",
                        description: "Automatic timezone detection keeps your medication schedule on track, no matter where you go."
                    )
                    .tag(2)

                    FeaturePageView(
                        icon: "lock.shield.fill",
                        title: "Your Privacy Matters",
                        description: "All your data stays on your device. No cloud sync, no internet required, complete privacy."
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // Navigation buttons
                VStack(spacing: 16) {
                    if currentPage == totalPages - 1 {
                        // Get Started button on last page
                        Button(action: {
                            requestNotificationPermission()
                            completeOnboarding()
                        }) {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    } else {
                        // Next button for other pages
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func completeOnboarding() {
        isOnboardingComplete = true
    }

    private func requestNotificationPermission() {
        Task {
            do {
                let granted = try await NotificationService().requestAuthorization()
                if granted {
                    print("Notification permission granted")
                } else {
                    print("Notification permission denied")
                }
            } catch {
                print("Failed to request notification permission: \(error)")
            }
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
