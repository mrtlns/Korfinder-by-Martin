import SwiftUI

@main
struct KorfinderApp: App {
    @StateObject var app = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        root
    }

    @ViewBuilder
    private var root: some View {
        switch app.phase {
        case .splash:
            SplashView()
                .task {
                    try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 s
                    await MainActor.run { app.phase = .auth }
                }

        case .auth:
            WelcomeStartView()

        case .main:
            MainTabView()
        }
    }
}
