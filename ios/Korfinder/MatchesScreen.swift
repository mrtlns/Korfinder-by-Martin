// MatchesScreen.swift
import SwiftUI
import Combine

struct MatchesScreen: View {
    @StateObject private var store = MatchesStore()

    var body: some View {
        NavigationStack {
            ZStack {
                KorBackground().ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    if store.isLoading {
                        ProgressView().tint(.white)
                    } else if let error = store.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                        Button("Spróbuj ponownie") {
                            Task { await store.reload() }
                        }
                        .buttonStyle(.borderedProminent)
                    } else if store.matches.isEmpty {
                        Text("Na razie nie masz żadnych match’y.\nSwipe’uj dalej!")
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        List {
                            ForEach(store.matches) { m in
                                NavigationLink {
                                    ChatScreen(match: m)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Użytkownik #\(m.target_user_id)")
                                                .font(.headline)
                                            Text(m.created_at.formatted(date: .abbreviated,
                                                                        time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "bubble.left.and.bubble.right.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Twoje match’e")
        }
        .task {
            await store.reload()
        }
    }
}
