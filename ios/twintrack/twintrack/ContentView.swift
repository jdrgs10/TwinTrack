import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var background: Color {
        colorScheme == .dark
            ? Color(red: 7 / 255, green: 11 / 255, blue: 18 / 255)
            : Color(red: 241 / 255, green: 244 / 255, blue: 248 / 255)
    }

    private var accent: Color {
        colorScheme == .dark
            ? Color(red: 90 / 255, green: 200 / 255, blue: 240 / 255)
            : Color(red: 14 / 255, green: 127 / 255, blue: 184 / 255)
    }

    var body: some View {
        // The locked navigation has exactly three tabs; iOS owns selection and safe areas.
        TabView {
            shellScreen("Home")
                .tabItem { Label("Home", systemImage: "house.fill") }

            shellScreen("TwinTrack AI")
                .tabItem { Label("TwinTrack AI", systemImage: "sparkles") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .tint(accent)
    }

    private func shellScreen(_ title: String) -> some View {
        NavigationStack {
            background
                .ignoresSafeArea()
                .navigationTitle(title)
                .toolbarBackground(background, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
    }
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
