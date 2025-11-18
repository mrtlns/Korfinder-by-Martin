import Foundation

enum APIError: Error, LocalizedError {
    case badResponse
    case http(Int, String?)

    var errorDescription: String? {
        switch self {
        case .badResponse:
            return "Błąd odpowiedzi serwera"
        case .http(let code, let body):
            return "HTTP \(code): \(body ?? "")"
        }
    }
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    // Базовый адрес зависит от окружения (Debug → localhost, Release → прод)
    var baseURL = AppConfig.apiBase
    var authToken: String?

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()

        // ISO8601 с/без миллисекунд и таймзоной
        let isoWithFraction = ISO8601DateFormatter()
        isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let isoNoFraction = ISO8601DateFormatter()
        isoNoFraction.formatOptions = [.withInternetDateTime]

        // Доп. формат именно под наш бэк:
        // "2025-11-17T14:17:14.304975" (без Z, с микросекундами, считаем UTC)
        let plainFraction: DateFormatter = {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(secondsFromGMT: 0)
            f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            return f
        }()

        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            // 1) ISO8601 с дробной частью и таймзоной
            if let date = isoWithFraction.date(from: str) {
                return date
            }
            // 2) ISO8601 без дробной части
            if let date = isoNoFraction.date(from: str) {
                return date
            }
            // 3) Формат, который сейчас шлет бэк: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = plainFraction.date(from: str) {
                return date
            }

            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid date format: \(str)"
                )
            )
        }

        return d
    }()


    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    // MARK: - Unified request (с query!)
    @discardableResult
    func request(
        _ path: String,
        method: String = "GET",
        query: [String: String]? = nil,
        body: Encodable? = nil
    ) async throws -> (Data, HTTPURLResponse) {

        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        if let query = query, !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw APIError.badResponse }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = authToken {
            req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = try Self.encoder.encode(AnyEncodable(body))
        }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.badResponse }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.http(http.statusCode, String(data: data, encoding: .utf8))
        }
        return (data, http)
    }

    // MARK: - Auth

    struct AuthRegisterReq: Codable {
        let first_name, last_name, email, role, password: String
    }

    struct AuthLoginReq: Codable {
        let email, password: String
    }

    struct AuthRes: Codable {
        let token: String
        let new_user: Bool?
    }

    struct MeRes: Codable {
        let id: Int
        let first_name, last_name, email, role: String
        let onboarding_done: Bool
    }

    func register(_ r: AuthRegisterReq) async throws -> AuthRes {
        let (d, _) = try await request("api/v1/auth/register", method: "POST", body: r)
        return try Self.decoder.decode(AuthRes.self, from: d)
    }

    func login(_ r: AuthLoginReq) async throws -> AuthRes {
        let (d, _) = try await request("api/v1/auth/login", method: "POST", body: r)
        return try Self.decoder.decode(AuthRes.self, from: d)
    }

    func me() async throws -> MeRes {
        let (d, _) = try await request("api/v1/auth/me")
        return try Self.decoder.decode(MeRes.self, from: d)
    }

    // MARK: - Subjects

    struct SubjectRes: Codable {
        let id: Int
        let name: String
    }

    func subjects() async throws -> [SubjectRes] {
        let (d, _) = try await request("api/v1/subjects")
        return try Self.decoder.decode([SubjectRes].self, from: d)
    }

    // MARK: - Feed / Listings (старое)

    func feed(again: Bool = false) async throws -> [ListingOut] {
        let q = again ? ["again": "true"] : nil
        let (d, _) = try await request("api/v1/feed", query: q)
        return try Self.decoder.decode([ListingOut].self, from: d)
    }

    func listings() async throws -> [ListingOut] {
        try await feed()
    }

    // MARK: - NEW: tworzenie ogłoszenia + moje ogłoszenia

    struct ListingCreateReq: Codable {
        let subject_id: Int
        let title: String
        let description: String
        let city: String?
        let is_online: Bool
        let is_offline: Bool
        let hourly_rate: Double?
        let level: String?
        let is_published: Bool
        let photo_url: String?
    }

    struct ListingUpdateReq: Codable {
        let subject_id: Int?
        let title: String?
        let description: String?
        let city: String?
        let is_online: Bool?
        let is_offline: Bool?
        let hourly_rate: Double?
        let level: String?
        let is_published: Bool?
        let photo_url: String?
    }

    func createListing(_ r: ListingCreateReq) async throws -> ListingOut {
        let (d, _) = try await request("api/v1/listings", method: "POST", body: r)
        return try Self.decoder.decode(ListingOut.self, from: d)
    }

    func listing(id: Int) async throws -> ListingOut {
        let (d, _) = try await request("api/v1/listings/\(id)")
        return try Self.decoder.decode(ListingOut.self, from: d)
    }

    func myListings() async throws -> [ListingOut] {
        let (d, _) = try await request("api/v1/listings/me")
        return try Self.decoder.decode([ListingOut].self, from: d)
    }

    func updateListing(id: Int, payload: ListingUpdateReq) async throws -> ListingOut {
        let (d, _) = try await request(
            "api/v1/listings/\(id)",
            method: "PATCH",
            body: payload
        )
        return try Self.decoder.decode(ListingOut.self, from: d)
    }

    func deleteListing(id: Int) async throws {
        _ = try await request("api/v1/listings/\(id)", method: "DELETE")
    }

    // MARK: - Swipes

    struct SwipeIn: Codable {
        let target_user_id: Int
        let like: Bool
    }

    struct SwipeOut: Codable {
        let match: Bool
    }

    func swipe(_ payload: SwipeIn) async throws -> SwipeOut {
        let (d, _) = try await request("api/v1/swipes", method: "POST", body: payload)
        return try Self.decoder.decode(SwipeOut.self, from: d)
    }

    func swipe(targetUserId: Int, like: Bool) async throws -> Bool {
        let out = try await swipe(.init(target_user_id: targetUserId, like: like))
        return out.match
    }

    // MARK: - NEW: Matches

    struct MatchRes: Codable, Identifiable {
        let id: Int
        let user_id: Int
        let target_user_id: Int
        let created_at: Date
    }

    func matches() async throws -> [MatchRes] {
        let (d, _) = try await request("api/v1/matches")
        return try Self.decoder.decode([MatchRes].self, from: d)
    }

    // MARK: - Private AnyEncodable

    private struct AnyEncodable: Encodable {
        let encodeFunc: (Encoder) throws -> Void
        init(_ e: Encodable) { self.encodeFunc = e.encode }
        func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
    }
    
    struct MessageRes: Codable, Identifiable {
        let id: Int
        let match_id: Int
        let sender_id: Int
        let body: String
        let created_at: Date
    }

    struct MessageCreateReq: Codable {
        let match_id: Int
        let body: String
    }

    func messages(matchId: Int) async throws -> [MessageRes] {
        let (d, _) = try await request(
            "api/v1/messages",
            query: ["match_id": String(matchId)]
        )
        return try Self.decoder.decode([MessageRes].self, from: d)
    }

    func sendMessage(_ req: MessageCreateReq) async throws -> MessageRes {
        let (d, _) = try await request(
            "api/v1/messages",
            method: "POST",
            body: req
        )
        return try Self.decoder.decode(MessageRes.self, from: d)
    }
}
