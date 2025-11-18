// MatchesStore.swift
import Foundation
import Combine

@MainActor
final class MatchesStore: ObservableObject {
    @Published var matches: [APIClient.MatchRes] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIClient.shared

    func reload() async {
        isLoading = true
        errorMessage = nil
        do {
            matches = try await api.matches()
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
}
