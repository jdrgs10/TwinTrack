//
//  twintrackApp.swift
//  twintrack
//
//  Created by Z73 on 07/09/2026.
//

import SwiftUI

@main
struct twintrackApp: App {
    @StateObject private var twinTrackState = Self.makeState()
    @StateObject private var appearance = AppearancePreferences.forApp()
    @Environment(\.scenePhase) private var scenePhase

    private static func makeState() -> TwinTrackState {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--synthetic-v2-ui-tests"),
           arguments.indices.contains(index + 1), let id = UUID(uuidString: arguments[index + 1]) {
            return V2UITestFixture.state(id: id)
        }
        if arguments.contains("--synthetic-duration-ui-tests") {
            let name = "TwinTrack.DurationUITestFixture"
            let defaults = UserDefaults(suiteName: name)!
            defaults.removePersistentDomain(forName: name)
            return TwinTrackState(defaults: defaults)
        }
        if let index = arguments.firstIndex(of: "--synthetic-profile-ui-tests"),
           arguments.indices.contains(index + 1),
           let id = UUID(uuidString: arguments[index + 1]),
           let defaults = UserDefaults(suiteName: "TwinTrack.ProfileUITests.\(id.uuidString)") {
            return TwinTrackState(defaults: defaults)
        }
#endif
        return TwinTrackState()
    }

    @ViewBuilder private var appContent: some View {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--synthetic-duration-ui-tests") {
            DurationPickerTestFixture()
        } else { ContentView() }
#else
        ContentView()
#endif
    }

    var body: some Scene {
        WindowGroup {
            appContent
                .environmentObject(twinTrackState)
                .environment(\.appearanceSelection, $appearance.selection)
                .preferredColorScheme(appearance.selection.colorScheme)
                .task {
#if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("--synthetic-duration-ui-tests") { return }
#endif
                    await twinTrackState.refreshHealth()
                }
                .onChange(of: scenePhase) { _, phase in
#if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("--synthetic-duration-ui-tests") { return }
#endif
                    twinTrackState.healthSceneChanged(isActive: phase == .active)
                    if phase == .active {
                        Task { await twinTrackState.refreshHealth() }
                    }
                }
        }
    }
}
