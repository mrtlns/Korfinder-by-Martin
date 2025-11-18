import Foundation
import Combine

@MainActor
final class FeedStore: ObservableObject {
    @Published var items: [ListingOut] = []
    @Published var isLoading = false
    @Published var errorText: String?
    /// id карточек, которые мы уже «съели» локально
    @Published var consumed = Set<Int>()

    private let api = APIClient.shared

    /// Те, что ещё не просмотрены
    var deckItems: [ListingOut] {
        items.filter { !consumed.contains($0.id) }
    }

    func load(again: Bool = false) async {
        // не запускаем параллельные загрузки
        if isLoading { return }

        isLoading = true
        errorText = nil

        do {
            let fresh = try await api.feed(again: again)
            print("FEED OK, count =", fresh.count)

            let newIds = Set(fresh.map { $0.id })

            if again {
                // если явно просим «с нуля» – сбрасываем прогресс
                consumed.removeAll()
            } else {
                // чистим consumed от id, которых больше нет во фиде
                consumed = consumed.intersection(newIds)
            }

            items = fresh
        } catch {
            // игнорируем отменённые запросы (код -999)
            if let urlError = error as? URLError, urlError.code == .cancelled {
                print("FEED CANCELLED")
            } else {
                print("FEED ERROR:", error)
                if let decoding = error as? DecodingError {
                    dump(decoding)
                }
                errorText = friendly(error)
            }
        }

        isLoading = false
    }

    func markConsumed(id: Int, like: Bool) {
        consumed.insert(id)
        // тут можно сохранять лайки/дизлайки, если понадобится
    }

    func clearConsumed() {
        consumed.removeAll()
    }

    private func friendly(_ error: Error) -> String {
        if case let APIError.http(code, body) = error {
            switch code {
            case 401: return "Twoja sesja wygasła. Zaloguj się ponownie."
            case 403: return "Brak uprawnień."
            case 404: return "Nie znaleziono danych."
            case 500...599: return "Błąd serwera. Spróbuj ponownie."
            default: return body ?? "Nieznany błąd (\(code))."
            }
        }
        return "Coś poszło nie tak. Sprawdź Internet i spróbuj ponownie."
    }
}
