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

            MyListingsScreen()
                .tabItem { Label("Ogłoszenia", systemImage: "list.bullet.rectangle") }

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

struct MessagesScreen: View {
    var body: some View {
        MatchesScreen()
    }
}

struct MyListingsScreen: View {
    @EnvironmentObject var app: AppState
    @StateObject private var store = ListingsStore()

    var body: some View {
        NavigationView {
            ZStack {
                KorBackground().ignoresSafeArea()
                content
            }
            .navigationTitle(app.role == .tutor ? "Moje ogłoszenia" : "Przeglądaj")
            .toolbar {
                if app.role == .tutor {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task { await store.reload() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(store.isLoading)
                        .accessibilityLabel("Odśwież ogłoszenia")
                    }
                }
            }
        }
        .task { await initialLoadIfNeeded() }
        .onChange(of: app.role) { _ in Task { await initialLoadIfNeeded() } }
        .onChange(of: app.token) { token in
            if token == nil { store.reset() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if app.role != .tutor {
            VStack(spacing: 12) {
                Text("Dostęp do ogłoszeń")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("Aby tworzyć i edytować ogłoszenia musisz mieć konto korepetytora.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal)
            }
        } else if store.isLoading && store.items.isEmpty {
            ProgressView("Ładuję ogłoszenia...")
                .tint(.white)
        } else if let error = store.errorMessage, store.items.isEmpty {
            VStack(spacing: 16) {
                Text(error)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                Button("Spróbuj ponownie") {
                    Task { await store.reload() }
                }
                .kor_glassPill()
            }
        } else if store.items.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.8))
                Text("Nie masz jeszcze żadnych ogłoszeń")
                    .foregroundStyle(.white)
                Text("Po ukończeniu onboardingu możesz dodać swój pierwszy wpis.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding()
        } else {
            ScrollView {
                LazyVStack(spacing: 18) {
                    ForEach(store.items) { listing in
                        card(for: listing)
                    }
                }
                .padding(20)
            }
            .refreshable { await store.reload() }
            .overlay(alignment: .bottom) {
                if let error = store.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .padding(12)
                        .kor_liquidGlass(cornerRadius: 14)
                        .padding()
                }
            }
        }
    }

    @ViewBuilder
    private func card(for listing: ListingOut) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ListingCard(listing: listing, showDescription: false)
            HStack {
                statusBadge(for: listing)
                Spacer()
                if let created = listing.createdAt {
                    Text(created.formatted(.dateTime.day().month().year()))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                Task { await store.delete(listingID: listing.id) }
            } label: {
                Label("Usuń ogłoszenie", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func statusBadge(for listing: ListingOut) -> some View {
        let published = listing.isPublished ?? true
        let text = published ? "Opublikowane" : "Szkic"
        let color: Color = published ? .green : .orange
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(.white)
    }

    private func initialLoadIfNeeded() async {
        guard app.role == .tutor, app.token != nil else {
            store.reset()
            return
        }
        if store.items.isEmpty && !store.isLoading {
            await store.reload()
        }
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
