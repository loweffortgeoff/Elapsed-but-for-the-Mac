//
//  ContentView.swift
//  Elapse(D) but for the Mac
//
//  Created by Geoffrey Silva on 1/3/26.
//

import SwiftUI
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorized {
            manager.startUpdatingLocation()
        }
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var currentTime = Date()
    @State private var timer: Timer?
    @State private var showingSettings = false

    // Ambient mode state
    @State private var ambientMode = false
    @State private var showAmbientHint = false
    @AppStorage(SettingsKeys.hasSeenAmbientHint) private var hasSeenAmbientHint = false

    // Settings from UserDefaults
    @AppStorage(SettingsKeys.useDynamicBackground) private var useDynamicBackground = true
    @AppStorage(SettingsKeys.selectedTheme) private var selectedTheme = ThemeOption.auto.rawValue
    @AppStorage(SettingsKeys.lastResolvedTheme) private var lastResolvedTheme = ThemeOption.daylightGradient.rawValue
    @AppStorage(SettingsKeys.showSunriseSunset) private var showSunriseSunset = true
    @AppStorage(SettingsKeys.showPercentComplete) private var showPercentComplete = true
    @AppStorage(SettingsKeys.showSeconds) private var showSeconds = true
    @AppStorage(SettingsKeys.showTimeElapsed) private var showTimeElapsed = false

    var body: some View {
        ZStack {
            gradientBackground
                .ignoresSafeArea()

            VStack(spacing: ambientMode ? 0 : 40) {
                // Settings button (hidden in ambient mode)
                if !ambientMode {
                    HStack {
                        Spacer()
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundStyle(textColor.opacity(0.8))
                                .padding(8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(",", modifiers: .command)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Title (hidden in ambient mode)
                VStack(spacing: 8) {
                    if !ambientMode {
                        Text(showTimeElapsed ? "Time Elapsed Today" : "Time Remaining Today")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(textColor.opacity(0.9))
                    }

                    // Main time display
                    VStack(spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%02d", displayHours))
                                .font(.system(size: ambientMode ? 96 : 72, weight: .bold, design: .rounded))
                                .foregroundStyle(textColor)

                            Text(":")
                                .font(.system(size: ambientMode ? 96 : 72, weight: .bold, design: .rounded))
                                .foregroundStyle(textColor.opacity(0.6))

                            Text(String(format: "%02d", displayMinutes))
                                .font(.system(size: ambientMode ? 96 : 72, weight: .bold, design: .rounded))
                                .foregroundStyle(textColor)

                            if showSeconds {
                                Text(":")
                                    .font(.system(size: ambientMode ? 96 : 72, weight: .bold, design: .rounded))
                                    .foregroundStyle(textColor.opacity(0.6))

                                Text(String(format: "%02d", displaySeconds))
                                    .font(.system(size: ambientMode ? 96 : 72, weight: .bold, design: .rounded))
                                    .foregroundStyle(textColor)
                            }
                        }
                        .monospacedDigit()
                        .onTapGesture(count: 2) {
                            toggleAmbientMode()
                        }
                        .help(ambientMode ? "Double-click or press Escape to exit Ambient Mode" : "Double-click to enter Ambient Mode")

                        // Time labels (hidden in ambient mode)
                        if !ambientMode {
                            HStack(spacing: showSeconds ? 44 : 66) {
                                Text("hours")
                                    .font(.caption)
                                    .foregroundStyle(textColor.opacity(0.7))
                                    .frame(width: 62)

                                Text("min")
                                    .font(.caption)
                                    .foregroundStyle(textColor.opacity(0.7))
                                    .frame(width: 62)

                                if showSeconds {
                                    Text("sec")
                                        .font(.caption)
                                        .foregroundStyle(textColor.opacity(0.7))
                                        .frame(width: 62)
                                }
                            }
                        }
                    }
                }

                // Progress bar (hidden in ambient mode)
                if showPercentComplete && !ambientMode {
                    VStack(spacing: 12) {
                        ProgressView(value: progressThroughDay)
                            .tint(textColor)
                            .scaleEffect(y: 2)
                            .frame(width: 300)

                        Text("\(Int(progressThroughDay * 100))% of day complete")
                            .font(.subheadline)
                            .foregroundStyle(textColor.opacity(0.8))
                    }
                }

                // Sunrise/Sunset info (hidden in ambient mode)
                if showSunriseSunset && !ambientMode {
                    HStack(spacing: 60) {
                        HStack(spacing: 8) {
                            Image(systemName: "sunrise.fill")
                                .font(.title2)
                                .foregroundStyle(.orange.opacity(0.9))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sunrise")
                                    .font(.caption)
                                    .foregroundStyle(textColor.opacity(0.6))
                                Text(sunriseTime)
                                    .font(.headline)
                                    .foregroundStyle(textColor)
                            }
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "sunset.fill")
                                .font(.title2)
                                .foregroundStyle(.orange.opacity(0.9))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sunset")
                                    .font(.caption)
                                    .foregroundStyle(textColor.opacity(0.6))
                                Text(sunsetTime)
                                    .font(.headline)
                                    .foregroundStyle(textColor)
                            }
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "sun.max.fill")
                                .font(.title2)
                                .foregroundStyle(.yellow.opacity(0.9))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daylight")
                                    .font(.caption)
                                    .foregroundStyle(textColor.opacity(0.6))
                                Text(daylightHours)
                                    .font(.headline)
                                    .foregroundStyle(textColor)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Spacer()
            }
            .padding()
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: ambientMode)

            // Ambient mode hint overlay
            if showAmbientHint && !ambientMode {
                AmbientHintView(textColor: textColor, showHint: $showAmbientHint)
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }
            locationManager.requestLocation()

            // Show ambient mode hint for first-time users
            if !hasSeenAmbientHint {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showAmbientHint = true
                    }

                    // Hide hint after 4 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showAmbientHint = false
                        }
                        hasSeenAmbientHint = true
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(locationManager: locationManager)
        }
        // Escape key exits ambient mode
        .onKeyPress(.escape) {
            if ambientMode {
                toggleAmbientMode()
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Ambient Mode

    private func toggleAmbientMode() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            ambientMode.toggle()
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

    var hoursRemaining: Int {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentTime)!)
        let components = calendar.dateComponents([.hour], from: currentTime, to: endOfDay)
        return components.hour ?? 0
    }

    var minutesRemaining: Int {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentTime)!)
        let components = calendar.dateComponents([.minute], from: currentTime, to: endOfDay)
        return (components.minute ?? 0) % 60
    }

    var secondsRemaining: Int {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentTime)!)
        let components = calendar.dateComponents([.second], from: currentTime, to: endOfDay)
        return (components.second ?? 0) % 60
    }

    // MARK: - Time Elapsed

    var hoursElapsed: Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentTime)
        let components = calendar.dateComponents([.hour], from: startOfDay, to: currentTime)
        return components.hour ?? 0
    }

    var minutesElapsed: Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentTime)
        let components = calendar.dateComponents([.minute], from: startOfDay, to: currentTime)
        return (components.minute ?? 0) % 60
    }

    var secondsElapsed: Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentTime)
        let components = calendar.dateComponents([.second], from: startOfDay, to: currentTime)
        return (components.second ?? 0) % 60
    }

    // MARK: - Progress

    var progressThroughDay: Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentTime)
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentTime)!)
        let totalSeconds = endOfDay.timeIntervalSince(startOfDay)
        let elapsedSeconds = currentTime.timeIntervalSince(startOfDay)
        return elapsedSeconds / totalSeconds
    }

    // MARK: - Sunrise/Sunset

    var sunriseTime: String {
        guard let location = locationManager.location else {
            return "--:--"
        }

        let solar = Solar(for: currentTime, coordinate: location.coordinate)
        guard let sunrise = solar?.sunrise else {
            return "--:--"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: sunrise)
    }

    var sunsetTime: String {
        guard let location = locationManager.location else {
            return "--:--"
        }

        let solar = Solar(for: currentTime, coordinate: location.coordinate)
        guard let sunset = solar?.sunset else {
            return "--:--"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: sunset)
    }

    var daylightHours: String {
        guard let location = locationManager.location,
              let solar = Solar(for: currentTime, coordinate: location.coordinate),
              let sunrise = solar.sunrise,
              let sunset = solar.sunset else {
            return "--:--"
        }

        let daylightSeconds = sunset.timeIntervalSince(sunrise)
        let hours = Int(daylightSeconds) / 3600
        let minutes = (Int(daylightSeconds) % 3600) / 60

        return "\(hours)h \(minutes)m"
    }

    // MARK: - Text Color

    var textColor: Color {
        if useDynamicBackground {
            return .white
        }

        guard let theme = ThemeOption(rawValue: selectedTheme) else {
            return .white
        }

        switch theme {
        case .auto:
            return .primary
        case .daylightGradient:
            return .white
        case .minimalDark:
            return .white
        case .minimalLight:
            return .black
        case .highContrast:
            return .white
        case .nebula:
            return .white
        }
    }

    // MARK: - Gradient Background

    var gradientBackground: LinearGradient {
        // If dynamic background is disabled, use the selected theme
        if !useDynamicBackground {
            let effectiveTheme: ThemeOption = {
                if selectedTheme == ThemeOption.auto.rawValue {
                    return ThemeOption(rawValue: lastResolvedTheme) ?? .daylightGradient
                } else {
                    return ThemeOption(rawValue: selectedTheme) ?? .daylightGradient
                }
            }()

            return gradientForTheme(effectiveTheme)
        }

        // Dynamic background based on time of day
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let timeInMinutes = (hour * 60) + minute

        if let location = locationManager.location,
           let solar = Solar(for: currentTime, coordinate: location.coordinate),
           let sunrise = solar.sunrise,
           let sunset = solar.sunset {

            let sunriseMinutes = (calendar.component(.hour, from: sunrise) * 60) + calendar.component(.minute, from: sunrise)
            let sunsetMinutes = (calendar.component(.hour, from: sunset) * 60) + calendar.component(.minute, from: sunset)

            let earlyMorning = sunriseMinutes - 60
            let lateEvening = sunsetMinutes + 60

            let colors: [Color]
            let resolvedTheme: ThemeOption

            switch timeInMinutes {
            case 0..<earlyMorning:
                colors = [.black, .indigo.opacity(0.8), .purple.opacity(0.6)]
                resolvedTheme = .minimalDark
            case earlyMorning..<sunriseMinutes:
                let progress = Double(timeInMinutes - earlyMorning) / Double(sunriseMinutes - earlyMorning)
                colors = [
                    Color.purple.opacity(1.0 - (progress * 0.3)),
                    Color.orange.opacity(0.3 + (progress * 0.7)),
                    Color.pink.opacity(0.5 + (progress * 0.5))
                ]
                resolvedTheme = .daylightGradient
            case sunriseMinutes..<(sunriseMinutes + 180):
                colors = [.orange, .yellow, .pink]
                resolvedTheme = .daylightGradient
            case (sunriseMinutes + 180)..<(sunsetMinutes - 120):
                colors = [.cyan, .blue, .indigo]
                resolvedTheme = .auto
            case (sunsetMinutes - 120)..<sunsetMinutes:
                let progress = Double(timeInMinutes - (sunsetMinutes - 120)) / 120.0
                colors = [
                    Color.blue.opacity(1.0 - (progress * 0.3)),
                    Color.orange.opacity(0.3 + (progress * 0.7)),
                    Color.pink.opacity(0.4 + (progress * 0.4))
                ]
                resolvedTheme = .daylightGradient
            case sunsetMinutes..<lateEvening:
                let progress = Double(timeInMinutes - sunsetMinutes) / Double(lateEvening - sunsetMinutes)
                colors = [
                    Color.orange.opacity(1.0 - (progress * 0.5)),
                    Color.red.opacity(0.8 - (progress * 0.3)),
                    Color.purple.opacity(0.6 + (progress * 0.3))
                ]
                resolvedTheme = .daylightGradient
            default:
                colors = [.indigo.opacity(0.9), .black, .purple.opacity(0.8)]
                resolvedTheme = .minimalDark
            }

            // Store resolved theme
            if lastResolvedTheme != resolvedTheme.rawValue {
                DispatchQueue.main.async {
                    lastResolvedTheme = resolvedTheme.rawValue
                }
            }

            return LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Fallback when location is unavailable
            let colors: [Color]
            let resolvedTheme: ThemeOption

            switch hour {
            case 0..<5:
                colors = [.indigo.opacity(0.9), .black, .purple.opacity(0.8)]
                resolvedTheme = .minimalDark
            case 5..<7:
                colors = [.purple, .orange, .pink]
                resolvedTheme = .daylightGradient
            case 7..<10:
                colors = [.orange, .yellow, .pink]
                resolvedTheme = .daylightGradient
            case 10..<16:
                colors = [.cyan, .blue, .indigo]
                resolvedTheme = .auto
            case 16..<18:
                colors = [.blue, .orange, .pink]
                resolvedTheme = .daylightGradient
            case 18..<20:
                colors = [.orange, .red, .purple]
                resolvedTheme = .daylightGradient
            case 20..<22:
                colors = [.purple, .indigo, .black]
                resolvedTheme = .minimalDark
            default:
                colors = [.indigo, .black, .purple.opacity(0.8)]
                resolvedTheme = .minimalDark
            }

            // Store resolved theme
            if lastResolvedTheme != resolvedTheme.rawValue {
                DispatchQueue.main.async {
                    lastResolvedTheme = resolvedTheme.rawValue
                }
            }

            return LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func gradientForTheme(_ theme: ThemeOption) -> LinearGradient {
        switch theme {
        case .auto:
            return LinearGradient(
                colors: [.cyan, .blue, .indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .daylightGradient:
            return LinearGradient(
                colors: [.orange, .yellow, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .minimalDark:
            return LinearGradient(
                colors: [.black, .gray.opacity(0.3), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .minimalLight:
            return LinearGradient(
                colors: [.white, .gray.opacity(0.1), .white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .highContrast:
            return LinearGradient(
                colors: [.black, .black, .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .nebula:
            return LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.0, blue: 0.35),
                    Color(red: 0.25, green: 0.1, blue: 0.55),
                    Color(red: 0.1, green: 0.2, blue: 0.6),
                    Color(red: 0.4, green: 0.15, blue: 0.65),
                    Color(red: 0.05, green: 0.15, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Ambient Mode Hint View

struct AmbientHintView: View {
    let textColor: Color
    @Binding var showHint: Bool

    var body: some View {
        VStack {
            Spacer()
                .frame(height: 80)

            Text("Double-click the time to enter Ambient Mode")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(textColor.opacity(0.9))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.1))
                )
                .opacity(showHint ? 1 : 0)
                .scaleEffect(showHint ? 1 : 0.9)

            Spacer()
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Solar Calculations

struct Solar {
    let sunrise: Date?
    let sunset: Date?

    init?(for date: Date, coordinate: CLLocationCoordinate2D) {
        let calendar = Calendar.current

        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        guard let (sunriseHour, sunsetHour) = Solar.calculateSunriseSunset(
            year: year,
            month: month,
            day: day,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timezone: TimeZone.current.secondsFromGMT() / 3600
        ) else {
            return nil
        }

        let startOfDay = calendar.startOfDay(for: date)
        self.sunrise = startOfDay.addingTimeInterval(sunriseHour * 3600.0)
        self.sunset = startOfDay.addingTimeInterval(sunsetHour * 3600.0)
    }

    private static func calculateSunriseSunset(
        year: Int,
        month: Int,
        day: Int,
        latitude: Double,
        longitude: Double,
        timezone: Int
    ) -> (Double, Double)? {
        // Calculate day of year
        let N1 = floor(275.0 * Double(month) / 9.0)
        let N2 = floor((Double(month) + 9.0) / 12.0)
        let N3 = (1.0 + floor((Double(year) - 4.0 * floor(Double(year) / 4.0) + 2.0) / 3.0))
        let N = N1 - (N2 * N3) + Double(day) - 30.0

        // Convert longitude to hour value
        let lngHour = longitude / 15.0

        // Calculate approximate time
        let tRise = N + ((6.0 - lngHour) / 24.0)
        let tSet = N + ((18.0 - lngHour) / 24.0)

        // Calculate sun's mean anomaly
        let MRise = (0.9856 * tRise) - 3.289
        let MSet = (0.9856 * tSet) - 3.289

        // Calculate sun's true longitude
        var LRise = MRise + (1.916 * sin(MRise * .pi / 180.0)) + (0.020 * sin(2.0 * MRise * .pi / 180.0)) + 282.634
        LRise = fmod(LRise, 360.0)
        if LRise < 0 { LRise += 360.0 }

        var LSet = MSet + (1.916 * sin(MSet * .pi / 180.0)) + (0.020 * sin(2.0 * MSet * .pi / 180.0)) + 282.634
        LSet = fmod(LSet, 360.0)
        if LSet < 0 { LSet += 360.0 }

        // Calculate sun's right ascension
        var RARise = atan(0.91764 * tan(LRise * .pi / 180.0)) * 180.0 / .pi
        RARise = fmod(RARise, 360.0)
        if RARise < 0 { RARise += 360.0 }

        let LquadrantRise = floor(LRise / 90.0) * 90.0
        let RAquadrantRise = floor(RARise / 90.0) * 90.0
        RARise = RARise + (LquadrantRise - RAquadrantRise)
        RARise = RARise / 15.0

        var RASet = atan(0.91764 * tan(LSet * .pi / 180.0)) * 180.0 / .pi
        RASet = fmod(RASet, 360.0)
        if RASet < 0 { RASet += 360.0 }

        let LquadrantSet = floor(LSet / 90.0) * 90.0
        let RAquadrantSet = floor(RASet / 90.0) * 90.0
        RASet = RASet + (LquadrantSet - RAquadrantSet)
        RASet = RASet / 15.0

        // Calculate sun's declination
        let sinDecRise = 0.39782 * sin(LRise * .pi / 180.0)
        let cosDecRise = cos(asin(sinDecRise))

        let sinDecSet = 0.39782 * sin(LSet * .pi / 180.0)
        let cosDecSet = cos(asin(sinDecSet))

        // Calculate sun's local hour angle
        let zenith = 90.833
        let cosHRise = (cos(zenith * .pi / 180.0) - (sinDecRise * sin(latitude * .pi / 180.0))) / (cosDecRise * cos(latitude * .pi / 180.0))
        let cosHSet = (cos(zenith * .pi / 180.0) - (sinDecSet * sin(latitude * .pi / 180.0))) / (cosDecSet * cos(latitude * .pi / 180.0))

        guard cosHRise >= -1 && cosHRise <= 1 && cosHSet >= -1 && cosHSet <= 1 else {
            return nil
        }

        // Calculate local mean time of rising/setting
        let HRise = (360.0 - (acos(cosHRise) * 180.0 / .pi)) / 15.0
        let HSet = (acos(cosHSet) * 180.0 / .pi) / 15.0

        let TRise = HRise + RARise - (0.06571 * tRise) - 6.622
        let TSet = HSet + RASet - (0.06571 * tSet) - 6.622

        // Adjust back to UTC
        var UTRise = TRise - lngHour
        UTRise = fmod(UTRise, 24.0)
        if UTRise < 0 { UTRise += 24.0 }

        var UTSet = TSet - lngHour
        UTSet = fmod(UTSet, 24.0)
        if UTSet < 0 { UTSet += 24.0 }

        // Convert to local time
        var localTRise = UTRise + Double(timezone)
        if localTRise < 0 { localTRise += 24.0 }
        if localTRise >= 24.0 { localTRise -= 24.0 }

        var localTSet = UTSet + Double(timezone)
        if localTSet < 0 { localTSet += 24.0 }
        if localTSet >= 24.0 { localTSet -= 24.0 }

        return (localTRise, localTSet)
    }
}

#Preview {
    ContentView()
}
