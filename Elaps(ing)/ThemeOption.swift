//
//  ThemeOption.swift
//  Elapse(D) but for the Mac
//
//  Theme configuration for the Mac app
//

import Foundation

enum ThemeOption: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case daylightGradient = "Daylight Gradient"
    case minimalDark = "Minimal Dark"
    case minimalLight = "Minimal Light"
    case highContrast = "High Contrast"
    case nebula = "Nebula"

    var id: String { rawValue }
}
