import SwiftUI

/// Individual feature page in onboarding flow
struct FeaturePageView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Feature icon
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)

            VStack(spacing: 16) {
                // Feature title
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Feature description
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    FeaturePageView(
        icon: "pills.circle.fill",
        title: "Track Your Medications",
        description: "Easily manage all your medications with customizable schedules and dose reminders."
    )
}
