//
//  twintrackApp.swift
//  twintrack
//
//  Created by Z73 on 07/09/2026.
//

import SwiftUI

@main
struct twintrackApp: App {
    @StateObject private var twinTrackState = TwinTrackState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(twinTrackState)
        }
    }
}
