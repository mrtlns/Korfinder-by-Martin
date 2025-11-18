//
//  ChatScreen.swift
//  Korfinder
//
//  Created by martin on 17.11.25.
//
// ChatScreen.swift
import SwiftUI

struct ChatScreen: View {
    let match: APIClient.MatchRes
    @StateObject private var store: ChatStore

    init(match: APIClient.MatchRes) {
        self.match = match
        _store = StateObject(wrappedValue: ChatStore(match: match))
    }

    var body: some View {
        ZStack {
            KorBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                // сообщения
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(store.messages) { msg in
                                messageRow(msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .onChange(of: store.messages.count) { _ in
                            if let last = store.messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                // разделитель
                Divider().background(Color.white.opacity(0.3))

                // поле ввода
                HStack(spacing: 8) {
                    TextField("Napisz wiadomość...", text: $store.draft, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await store.send() }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(8)
                    }
                    .disabled(store.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
        }
        .navigationTitle("Czat")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.reload()
        }
    }

    private func messageRow(_ msg: APIClient.MessageRes) -> some View {
        // наш id = match.user_id, партнёр = target_user_id
        let isMine = (msg.sender_id == match.user_id)

        return HStack {
            if isMine { Spacer() }

            Text(msg.body)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isMine ? Color.blue.opacity(0.8) : Color.white.opacity(0.15))
                )
                .foregroundColor(.white)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)

            if !isMine { Spacer() }
        }
    }
}

