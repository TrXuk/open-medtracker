import SwiftUI

/// Welcome page for onboarding flow
struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App icon/logo
            Image(systemName: "cross.case.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)

            VStack(spacing: 12) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text("Open MedTracker")
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Your personal medication companion")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    WelcomePageView()
}
