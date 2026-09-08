import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = TwinTrackTab.home

    private var accent: Color {
        colorScheme == .dark
            ? Color(red: 90 / 255, green: 200 / 255, blue: 240 / 255)
            : Color(red: 14 / 255, green: 127 / 255, blue: 184 / 255)
    }

    var body: some View {
        // The locked navigation has exactly three tabs; iOS owns selection and safe areas.
        TabView(selection: $selectedTab) {
            HomeView {
                selectedTab = .ai
            }
                .tag(TwinTrackTab.home)
                .tabItem { Label("Home", systemImage: "house.fill") }

            WhatIfView(isActive: selectedTab == .ai)
                .tag(TwinTrackTab.ai)
                .tabItem { Label("TwinTrack AI", systemImage: "sparkles") }

            ProfileView()
                .tag(TwinTrackTab.profile)
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .tint(accent)
    }
}

private enum TwinTrackTab: Hashable {
    case home
    case ai
    case profile
}

#Preview("Light") {
    ContentView()
        .environmentObject(TwinTrackState())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView()
        .environmentObject(TwinTrackState())
        .preferredColorScheme(.dark)
}
