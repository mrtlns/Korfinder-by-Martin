import SwiftUI

struct ContentView: View {
    @EnvironmentObject var feed: FeedStore
    @State private var deckVersion = 0

    var body: some View {
        NavigationStack {
            ZStack {
                KorBackground().ignoresSafeArea()

                if let err = feed.errorText {
                    errorView(err)

                } else if feed.isLoading && feed.items.isEmpty {
                    loadingView

                } else {
                    SwipeDeckView(
                        items: feed.deckItems,
                        onSwipe: { id, like in
                            // отмечаем локально — чтобы следующая карта показалась без перезагрузки
                            feed.markConsumed(id: id, like: like)
                            // стреляем на бэк
                            do {
                                let matched = try await APIClient.shared.swipe(
                                    targetUserId: id,
                                    like: like
                                )
                                return matched
                            } catch {
                                return false
                            }
                        },
                        onReload: {
                            Task {
                                await feed.load(again: true)
                                feed.clearConsumed()
                            }
                            deckVersion &+= 1
                        }
                    )
                    .id(deckVersion)
                }
            }
            .navigationTitle("Korfinder")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task { if feed.items.isEmpty { await feed.load() } }
            .refreshable {
                await feed.load()
                deckVersion &+= 1
            }
        }
    }

    private var loadingView: some View {
        ProgressView("Aktualizujemy…")
            .padding()
            .background(.ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                    .blendMode(.overlay)
            )
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text("Błąd połączenia").font(.headline)
            Text(message)
                .font(.footnote).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Spróbować ponownie") {
                Task { await feed.load() }
            }
            .kor_glassPill().foregroundStyle(.white)
        }
        .padding()
    }
}
