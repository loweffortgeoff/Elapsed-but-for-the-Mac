//
//  AboutSectionView.swift
//  Elapse(D) but for the Mac
//
//  About section for settings, adapted for macOS
//

import SwiftUI

// MARK: - App Info Model

struct LowEffortApp: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let appStoreID: String

    var appStoreURL: URL? {
        URL(string: "https://apps.apple.com/us/app/\(name.lowercased().replacingOccurrences(of: " ", with: "-"))/id\(appStoreID)")
    }
}

// MARK: - App Catalog

enum LowEffortApps {
    static let loudSky = LowEffortApp(name: "Loud Sky", iconName: "boomskydark", appStoreID: "6755754767")
    static let elapseD = LowEffortApp(name: "Elapse(D)", iconName: "TimeFlux", appStoreID: "6755078545")
    static let routinee = LowEffortApp(name: "Routine(e)", iconName: "routineedarknew", appStoreID: "6755685503")
    static let yesNoGo = LowEffortApp(name: "Yes? No? Go!", iconName: "yesnogo", appStoreID: "6754826659")
    static let muzzletoff = LowEffortApp(name: "Muzzletoff", iconName: "muzzletoff", appStoreID: "6754781167")
    static let aisleWise = LowEffortApp(name: "AisleWise", iconName: "aislewisedark", appStoreID: "6755057084")
    static let tasked = LowEffortApp(name: "Task(ed)", iconName: "taskedlight", appStoreID: "6755186421")
    static let trackked = LowEffortApp(name: "Trackked", iconName: "trackked3", appStoreID: "6756798126")

    static let all: [LowEffortApp] = [
        loudSky, elapseD, routinee, yesNoGo, muzzletoff, aisleWise, tasked, trackked
    ]
}

// MARK: - About Section View

struct AboutSectionView: View {
    let currentAppName: String?
    let appsToShow: [LowEffortApp]?

    init(currentAppName: String? = nil, appsToShow: [LowEffortApp]? = nil) {
        self.currentAppName = currentAppName
        self.appsToShow = appsToShow
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private var otherApps: [LowEffortApp] {
        if let appsToShow = appsToShow {
            return appsToShow
        }

        guard let currentAppName = currentAppName else {
            return LowEffortApps.all
        }

        return LowEffortApps.all.filter { !currentAppName.contains($0.name) && $0.name != currentAppName }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // We Also Make Section
            VStack(alignment: .leading, spacing: 12) {
                Text("We Also Make")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ForEach(otherApps) { app in
                        OtherAppRow(app: app)
                    }
                }
            }

            Divider()

            // About Section
            VStack(alignment: .leading, spacing: 12) {
                Text("About")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // Version & Build
                HStack {
                    Text("Version")
                    Spacer()
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundStyle(.secondary)
                }

                // Company Website
                HStack {
                    Text("Company Website")
                    Spacer()
                    Link(destination: URL(string: "https://www.loweffortapps.dev")!) {
                        HStack(spacing: 4) {
                            Text("loweffortapps.dev")
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                    }
                }

                // Privacy Policy
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Link(destination: URL(string: "https://www.loweffortapps.dev/privacy-policy")!) {
                        HStack(spacing: 4) {
                            Text("View")
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}

// MARK: - Other App Row

struct OtherAppRow: View {
    let app: LowEffortApp

    var body: some View {
        Button(action: openAppStore) {
            HStack(spacing: 12) {
                // Placeholder for app icon (you'd need to add these to assets)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "app.fill")
                            .foregroundStyle(.secondary)
                    )

                Text(app.name)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func openAppStore() {
        guard let url = app.appStoreURL else { return }
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    AboutSectionView(currentAppName: "Elapse(D) but for the Mac")
        .padding()
        .frame(width: 400)
}
