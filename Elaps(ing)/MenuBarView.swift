//
//  MenuBarView.swift
//  Elapse(D) but for the Mac
//
//  Menu bar popover showing the countdown
//

import SwiftUI
import CoreLocation
import Combine

struct MenuBarView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var currentTime = Date()

    @AppStorage(SettingsKeys.useDynamicBackground) private var useDynamicBackground = true
    @AppStorage(SettingsKeys.selectedTheme) private var selectedTheme = ThemeOption.auto.rawValue
    @AppStorage(SettingsKeys.lastResolvedTheme) private var lastResolvedTheme = ThemeOption.daylightGradient.rawValue
    @AppStorage(SettingsKeys.showSunriseSunset) private var showSunriseSunset = true
    @AppStorage(SettingsKeys.showPercentComplete) private var showPercentComplete = true
    @AppStorage(SettingsKeys.showSeconds) private var showSeconds = true
    @AppStorage(SettingsKeys.showTimeElapsed) private var showTimeElapsed = false

    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text(showTimeElapsed ? "Time Elapsed" : "Time Remaining")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Time display
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%02d", displayHours))
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                Text(":")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .opacity(0.5)

                Text(String(format: "%02d", displayMinutes))
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                if showSeconds {
                    Text(":")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .opacity(0.5)

                    Text(String(format: "%02d", displaySeconds))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }
            }
            .monospacedDigit()

            // Progress bar
            if showPercentComplete {
                VStack(spacing: 6) {
                    ProgressView(value: progressThroughDay)
                        .tint(.accentColor)
                        .frame(width: 180)

                    Text("\(Int(progressThroughDay * 100))% complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Sunrise/Sunset (compact)
            if showSunriseSunset {
                HStack(spacing: 16) {
                    Label(sunriseTime, systemImage: "sunrise.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)

                    Label(sunsetTime, systemImage: "sunset.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Divider()

            // Quick actions
            HStack(spacing: 12) {
                Button {
                    showTimeElapsed.toggle()
                } label: {
                    Image(systemName: showTimeElapsed ? "hourglass.bottomhalf.filled" : "hourglass.tophalf.filled")
                }
                .buttonStyle(.borderless)
                .help(showTimeElapsed ? "Show Time Remaining" : "Show Time Elapsed")

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .frame(width: 220)
        .onAppear {
            locationManager.requestLocation()
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            currentTime = Date()
        }
    }

    // MARK: - Display Values

    private var displayHours: Int {
        showTimeElapsed ? hoursElapsed : hoursRemaining
    }

    private var displayMinutes: Int {
        showTimeElapsed ? minutesElapsed : minutesRemaining
    }

    private var displaySeconds: Int {
        showTimeElapsed ? secondsElapsed : secondsRemaining
    }

    // MARK: - Time Remaining

    private var hoursRemaining: Int {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentTime)!)
        let components = calendar.dateComponents([.hour], from: currentTime, to: endOfDay)
        return components.hour ?? 0
    }

    private var minutesRemaining: Int {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentTime)!)
        let components = calendar.dateComponents([.minute], from: currentTime, to: endOfDay)
        return (components.minute ?? 0) % 60
    }

    private var secondsRemaining: Int {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentTime)!)
        let components = calendar.dateComponents([.second], from: currentTime, to: endOfDay)
        return (components.second ?? 0) % 60
    }

    // MARK: - Time Elapsed

    private var hoursElapsed: Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentTime)
        let components = calendar.dateComponents([.hour], from: startOfDay, to: currentTime)
        return components.hour ?? 0
    }

    private var minutesElapsed: Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentTime)
        let components = calendar.dateComponents([.minute], from: startOfDay, to: currentTime)
        return (components.minute ?? 0) % 60
    }

    private var secondsElapsed: Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentTime)
        let components = calendar.dateComponents([.second], from: startOfDay, to: currentTime)
        return (components.second ?? 0) % 60
    }

    // MARK: - Progress

    private var progressThroughDay: Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentTime)
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentTime)!)
        let totalSeconds = endOfDay.timeIntervalSince(startOfDay)
        let elapsedSeconds = currentTime.timeIntervalSince(startOfDay)
        return elapsedSeconds / totalSeconds
    }

    // MARK: - Sunrise/Sunset

    private var sunriseTime: String {
        guard let location = locationManager.location,
              let solar = Solar(for: currentTime, coordinate: location.coordinate),
              let sunrise = solar.sunrise else {
            return "--:--"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: sunrise)
    }

    private var sunsetTime: String {
        guard let location = locationManager.location,
              let solar = Solar(for: currentTime, coordinate: location.coordinate),
              let sunset = solar.sunset else {
            return "--:--"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: sunset)
    }
}

#Preview {
    MenuBarView()
}
