//
//  ChatStore.swift
//  Korfinder
//
//  Created by martin on 17.11.25.
//

import Foundation
import Combine

@MainActor
final class ChatStore: ObservableObject {
    @Published var messages: [APIClient.MessageRes] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var draft: String = ""

    let match: APIClient.MatchRes
    private let api = APIClient.shared

    init(match: APIClient.MatchRes) {
        self.match = match
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        do {
            messages = try await api.messages(matchId: match.id)
        } catch let error as APIError {
            switch error {
            case .badResponse:
                errorMessage = "Błąd odpowiedzi serwera."
            case .http(let code, let body):
                errorMessage = "HTTP \(code): \(body ?? "")"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        draft = ""

        do {
            let req = APIClient.MessageCreateReq(match_id: match.id, body: text)
            let created = try await api.sendMessage(req)
            messages.append(created)
        } catch let error as APIError {
            switch error {
            case .badResponse:
                errorMessage = "Błąd odpowiedzi serwera."
            case .http(let code, let body):
                errorMessage = "HTTP \(code): \(body ?? "")"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

