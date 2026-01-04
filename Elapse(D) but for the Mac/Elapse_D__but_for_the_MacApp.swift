//
//  Elapse_D__but_for_the_MacApp.swift
//  Elapse(D) but for the Mac
//
//  Created by Geoffrey Silva on 1/3/26.
//

import SwiftUI

@main
struct Elapse_D__but_for_the_MacApp: App {
    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 500, height: 600)

        // Menu bar extra
        MenuBarExtra {
            MenuBarView()
        } label: {
            Label("Elapse(D)", systemImage: "hourglass")
        }
        .menuBarExtraStyle(.window)
    }
}
