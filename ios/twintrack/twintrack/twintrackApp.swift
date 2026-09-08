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
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(twinTrackState)
                .task { await twinTrackState.refreshHealth() }
                .onChange(of: scenePhase) { _, phase in
                    twinTrackState.healthSceneChanged(isActive: phase == .active)
                    if phase == .active {
                        Task { await twinTrackState.refreshHealth() }
                    }
                }
        }
    }
}
