import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var feed = FeedStore()
    @State private var showOnboarding = false

    var body: some View {
        TabView {
            ContentView()
                .environmentObject(feed)
                .tabItem { Label("Swipe", systemImage: "heart.circle.fill") }

            SearchScreen()
                .tabItem { Label("Szukaj", systemImage: "magnifyingglass") }

            MessagesScreen()
                .tabItem { Label("Czat", systemImage: "bubble.left.and.bubble.right.fill") }

            ProfileScreen()
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }
        }
        // Pokaż onboarding jako sheet
        .onAppear { showOnboarding = app.needsOnboarding }
        .onChange(of: app.needsOnboarding) { show in
            showOnboarding = show
        }
        .sheet(isPresented: $showOnboarding, onDismiss: {
            if !app.needsOnboarding {
                Task { await feed.load(again: true) }
            }
        }) {
            OnboardingWizard()
                .environmentObject(app)
                .interactiveDismissDisabled(app.needsOnboarding)
        }
    }
}

struct SearchScreen: View {
    var body: some View {
        ZStack {
            KorBackground().ignoresSafeArea()
            Text("Wyszukiwanie (soon)").foregroundStyle(.white)
        }
    }
}

struct MessagesScreen: View {
    var body: some View {
        MatchesScreen()
    }
}

struct ProfileScreen: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        ZStack { KorBackground().ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Profil (\(app.role == .tutor ? "Tutor" : "Uczeń"))")
                    .font(.title2.bold()).foregroundStyle(.white)
                Button("Wyloguj się") { app.signOut() }
                    .kor_glassPill().foregroundStyle(.white)
            }
        }
    }
}
