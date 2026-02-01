import SwiftUI

/// A badge view displaying dose status
struct StatusBadgeView: View {
    let status: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
            Text(displayText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(8)
    }

    private var iconName: String {
        switch status.lowercased() {
        case "taken":
            return "checkmark.circle.fill"
        case "missed":
            return "xmark.circle.fill"
        case "skipped":
            return "minus.circle.fill"
        case "pending":
            return "clock.fill"
        default:
            return "questionmark.circle.fill"
        }
    }

    private var displayText: String {
        status.capitalized
    }

    private var backgroundColor: Color {
        switch status.lowercased() {
        case "taken":
            return Color.green.opacity(0.2)
        case "missed":
            return Color.red.opacity(0.2)
        case "skipped":
            return Color.orange.opacity(0.2)
        case "pending":
            return Color.blue.opacity(0.2)
        default:
            return Color.gray.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch status.lowercased() {
        case "taken":
            return Color.green
        case "missed":
            return Color.red
        case "skipped":
            return Color.orange
        case "pending":
            return Color.blue
        default:
            return Color.gray
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StatusBadgeView(status: "taken")
        StatusBadgeView(status: "missed")
        StatusBadgeView(status: "skipped")
        StatusBadgeView(status: "pending")
    }
    .padding()
}
