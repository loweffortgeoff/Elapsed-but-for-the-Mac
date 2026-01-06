//
//  SettingsView.swift
//  Elapse(D) but for the Mac
//
//  Settings panel adapted for macOS
//

import SwiftUI
import CoreLocation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKeys.useDynamicBackground) private var useDynamicBackground = true
    @AppStorage(SettingsKeys.selectedTheme) private var selectedTheme = ThemeOption.auto.rawValue
    @AppStorage(SettingsKeys.lastResolvedTheme) private var lastResolvedTheme = ThemeOption.daylightGradient.rawValue
    @AppStorage(SettingsKeys.showSunriseSunset) private var showSunriseSunset = true
    @AppStorage(SettingsKeys.showPercentComplete) private var showPercentComplete = true
    @AppStorage(SettingsKeys.showSeconds) private var showSeconds = true
    @AppStorage(SettingsKeys.showTimeElapsed) private var showTimeElapsed = false

    @ObservedObject var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding()

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Appearance Section
                    appearanceSection

                    Divider()

                    // Display Section
                    displaySection

                    Divider()

                    // Location Section
                    locationSection

                    Divider()

                    // About Section
                    AboutSectionView(currentAppName: "Elapse(D) but for the Mac")
                }
                .padding()
            }
        }
        .frame(width: 420, height: 560)
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Appearance", systemImage: "paintpalette")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Dynamic Background Toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dynamic Background")
                        .font(.body)
                    Text("Background changes based on time of day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $useDynamicBackground)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .onChange(of: useDynamicBackground) { _, newValue in
                if !newValue && selectedTheme == ThemeOption.auto.rawValue {
                    lastResolvedTheme = resolvedAutoTheme(for: Date()).rawValue
                }
            }

            // Theme Selection (only when dynamic background is off)
            if !useDynamicBackground {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(ThemeOption.allCases) { theme in
                            ThemeButton(
                                theme: theme,
                                isSelected: selectedTheme == theme.rawValue,
                                colors: gradientColors(for: theme)
                            ) {
                                selectedTheme = theme.rawValue
                            }
                        }
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Theme is managed automatically when Dynamic Background is on.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Display Section

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Display", systemImage: "display")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Time Elapsed/Remaining toggle
            SettingsToggleRow(
                icon: showTimeElapsed ? "hourglass.bottomhalf.filled" : "hourglass.tophalf.filled",
                title: "Time Display",
                subtitle: showTimeElapsed ? "Time Elapsed" : "Time Remaining",
                isOn: $showTimeElapsed
            )

            // Sunrise/Sunset option
            SettingsToggleRow(
                icon: "sun.max",
                title: "Sunrise & Sunset",
                subtitle: showSunriseSunset ? "Shown" : "Hidden",
                isOn: $showSunriseSunset
            )

            // Percent Complete option
            SettingsToggleRow(
                icon: "percent",
                title: "Percent Complete",
                subtitle: showPercentComplete ? "Shown" : "Hidden",
                isOn: $showPercentComplete
            )

            // Seconds option
            SettingsToggleRow(
                icon: "timer",
                title: "Seconds",
                subtitle: showSeconds ? "Shown" : "Hidden",
                isOn: $showSeconds
            )
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Location", systemImage: "location")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Location Access")
                    Text(locationStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                locationStatusBadge
            }

            if locationManager.authorizationStatus == .notDetermined {
                Button("Request Location Access") {
                    locationManager.requestLocation()
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Open System Preferences...") {
                openSystemPreferences()
            }
            .buttonStyle(.link)
        }
    }

    // MARK: - Helpers

    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorized:
            return "Allowed"
        case .denied, .restricted:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        @unknown default:
            return "Unknown"
        }
    }

    private var locationStatusBadge: some View {
        Group {
            switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorized:
                Label("Allowed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
            case .denied, .restricted:
                Label("Denied", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.subheadline)
            case .notDetermined:
                Label("Not Set", systemImage: "questionmark.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline)
            @unknown default:
                Label("Unknown", systemImage: "questionmark.circle.fill")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
        }
    }

    private func resolvedAutoTheme(for date: Date) -> ThemeOption {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<18:
            return .daylightGradient
        default:
            return .minimalDark
        }
    }

    private func gradientColors(for theme: ThemeOption) -> [Color] {
        switch theme {
        case .auto:
            return [.cyan, .blue, .indigo]
        case .daylightGradient:
            return [.orange, .yellow, .pink]
        case .minimalDark:
            return [.black, .gray.opacity(0.3), .black]
        case .minimalLight:
            return [.white, .gray.opacity(0.1), .white]
        case .highContrast:
            return [.black, .black, .black]
        case .nebula:
            return [
                Color(red: 0.15, green: 0.0, blue: 0.35),
                Color(red: 0.25, green: 0.1, blue: 0.55),
                Color(red: 0.1, green: 0.2, blue: 0.6)
            ]
        }
    }

    private func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Supporting Views

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

struct ThemeButton: View {
    let theme: ThemeOption
    let isSelected: Bool
    let colors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(isSelected ? Color.blue : Color.primary.opacity(0.1), lineWidth: isSelected ? 2 : 0.5)
                    )

                Text(theme.rawValue)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView(locationManager: LocationManager())
}
