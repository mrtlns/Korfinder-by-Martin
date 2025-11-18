import Foundation

struct ListingOut: Identifiable, Codable {
    let id: Int
    let ownerId: Int?
    let tutorId: Int?
    let title: String
    let description: String?
    let subject: String?
    let level: String?
    let pricePerHour: Double?
    let city: String?
    let isPublished: Bool?      // 👈 теперь Optional
    let createdAt: Date?        // 👈 тоже Optional
    let photoUrl: String?
    let role: String?

    // 👇 совместимость со старым UI (SwipeCardView, SwipeDeckView, ListingCard)
    var tutor_id: Int? { tutorId }
    var owner_id: Int? { ownerId }
    var profileOwnerID: Int? { ownerId ?? tutorId ?? id }
    var isTutor: Bool { role == "tutor" }
    var isStudent: Bool { role == "student" }
    var roleDisplay: String? {
        switch role {
        case "tutor": return "Korepetytor"
        case "student": return "Uczeń"
        default: return nil
        }
    }
    var price_per_hour: Double? { pricePerHour }
    var photoURL: URL? {
        guard let s = photoUrl, !s.isEmpty else { return nil }
        return URL(string: s)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case tutorId = "tutor_id"
        case title
        case description
        case subject
        case level
        case pricePerHour = "price_per_hour"
        case city
        case isPublished = "is_published"
        case createdAt = "created_at"
        case photoUrl = "photo_url"
        case role
    }
}
