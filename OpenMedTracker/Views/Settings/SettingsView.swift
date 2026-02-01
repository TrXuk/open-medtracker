//
//  SettingsView.swift
//  OpenMedTracker
//
//  Comprehensive settings view with notification preferences, timezone settings,
//  data management, privacy policy, about section, and appearance options
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.openURL) private var openURL

    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingClearDataAlert = false
    @State private var exportURL: URL?

    init(viewModel: SettingsViewModel = SettingsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                settingsForm

                if viewModel.isLoading {
                    LoadingView(message: "Processing...")
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    Task {
                        await viewModel.clearAllData()
                    }
                }
            } message: {
                Text("This will permanently delete all medications, schedules, and history. This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task {
                            await viewModel.importData(from: url)
                        }
                    }
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                }
            }
            .overlay(alignment: .bottom) {
                if let errorMessage = viewModel.errorMessage {
                    MessageBanner(message: errorMessage, type: .error) {
                        viewModel.clearMessages()
                    }
                    .transition(.move(edge: .bottom))
                } else if let successMessage = viewModel.successMessage {
                    MessageBanner(message: successMessage, type: .success) {
                        viewModel.clearMessages()
                    }
                    .transition(.move(edge: .bottom))
                }
            }
        }
    }

    private var settingsForm: some View {
        Form {
            notificationSection
            timezoneSection
            appearanceSection
            dataManagementSection
            aboutSection
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        Section {
            Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                .onChange(of: settings.notificationsEnabled) { newValue in
                    Task {
                        await viewModel.toggleNotifications(newValue)
                    }
                }

            if settings.notificationsEnabled {
                Toggle("Notification Sound", isOn: $settings.notificationSound)

                Toggle("Enable Snooze", isOn: $settings.snoozeEnabled)

                if settings.snoozeEnabled {
                    Stepper(
                        "Snooze Duration: \(settings.snoozeDuration) min",
                        value: $settings.snoozeDuration,
                        in: 5...30,
                        step: 5
                    )
                }
            }
        } header: {
            Label("Notifications", systemImage: "bell.fill")
        } footer: {
            Text("Receive reminders when it's time to take your medications.")
        }
    }

    // MARK: - Timezone Section

    private var timezoneSection: some View {
        Section {
            Toggle("Auto-Detect Timezone", isOn: $settings.autoDetectTimezone)

            HStack {
                Text("Current Timezone")
                Spacer()
                Text(viewModel.currentTimezone)
                    .foregroundColor(.secondary)
                    .font(.footnote)
            }

            if !settings.autoDetectTimezone {
                NavigationLink {
                    TimezonePickerView(selectedTimezone: $settings.preferredTimezone)
                } label: {
                    HStack {
                        Text("Preferred Timezone")
                        Spacer()
                        Text(settings.preferredTimezone ?? "None")
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label("Timezone", systemImage: "globe")
        } footer: {
            Text("Automatically detect timezone changes when traveling, or manually set a preferred timezone.")
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section {
            Picker("Theme", selection: $settings.appearance) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Label("Appearance", systemImage: "paintbrush.fill")
        } footer: {
            Text("Choose how the app looks. System matches your device settings.")
        }
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        Section {
            Button {
                Task {
                    if let url = await viewModel.exportData() {
                        exportURL = url
                        showingExportSheet = true
                    }
                }
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }

            if let lastExport = settings.lastExportDate {
                HStack {
                    Text("Last Export")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(lastExport, style: .date)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Button {
                showingImportPicker = true
            } label: {
                Label("Import Data", systemImage: "square.and.arrow.down")
            }

            Button(role: .destructive) {
                showingClearDataAlert = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
        } header: {
            Label("Data Management", systemImage: "externaldrive")
        } footer: {
            Text("Export your data for backup or transfer to another device. Clear all data to start fresh.")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(viewModel.fullVersionString)
                    .foregroundColor(.secondary)
            }

            Button {
                if let url = URL(string: "https://github.com/your-org/open-medtracker") {
                    openURL(url)
                }
            } label: {
                Label("GitHub Repository", systemImage: "link")
            }

            Button {
                if let url = URL(string: "https://github.com/your-org/open-medtracker/blob/main/PRIVACY.md") {
                    openURL(url)
                }
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            Button {
                if let url = URL(string: "https://github.com/your-org/open-medtracker/blob/main/LICENSE") {
                    openURL(url)
                }
            } label: {
                Label("License", systemImage: "doc.text")
            }

            Button {
                if let url = URL(string: "https://github.com/your-org/open-medtracker/issues") {
                    openURL(url)
                }
            } label: {
                Label("Report an Issue", systemImage: "exclamationmark.bubble")
            }
        } header: {
            Label("About", systemImage: "info.circle")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Open MedTracker")
                    .font(.headline)
                Text("Open source medication tracker with international travel support.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
    }
}

// MARK: - Message Banner

private struct MessageBanner: View {
    enum MessageType {
        case success
        case error

        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }

    let message: String
    let type: MessageType
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(type.color)
        .cornerRadius(12)
        .padding()
        .shadow(radius: 4)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onDismiss()
            }
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Timezone Picker View

private struct TimezonePickerView: View {
    @Binding var selectedTimezone: String?
    @Environment(\.dismiss) private var dismiss

    private let timezones = TimeZone.knownTimeZoneIdentifiers.sorted()
    @State private var searchText = ""

    private var filteredTimezones: [String] {
        if searchText.isEmpty {
            return timezones
        } else {
            return timezones.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        List {
            ForEach(filteredTimezones, id: \.self) { timezone in
                Button {
                    selectedTimezone = timezone
                    dismiss()
                } label: {
                    HStack {
                        Text(timezone)
                        Spacer()
                        if selectedTimezone == timezone {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Select Timezone")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search timezones")
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
