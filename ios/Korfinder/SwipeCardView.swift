import SwiftUI

struct SwipeCardView: View {
    let listing: ListingOut

    var body: some View {
        GeometryReader { geo in
            let corner: CGFloat = 22

            ZStack(alignment: .bottomLeading) {
                // 1) Фото строго под размеры карточки
                if let url = listing.photoURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped() // <- ничего больше, ровно по рамке
                        default:
                            KorBackground()
                        }
                    }
                } else {
                    KorBackground()
                }

                // 2) затемнение снизу
                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .center, endPoint: .bottom
                )
                .frame(height: min(180, geo.size.height * 0.5))
                .allowsHitTesting(false)

                // 3) подписи
                VStack(alignment: .leading, spacing: 6) {
                    if let badge = listing.roleDisplay {
                        HStack(spacing: 6) {
                            Image(systemName: listing.isTutor ? "graduationcap.fill" : "person.text.rectangle")
                            Text(badge.uppercased())
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.25), in: Capsule())
                        .foregroundStyle(.black)
                    }

                    Text(listing.title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    HStack(spacing: 10) {
                        if let city = listing.city {
                            Label(city, systemImage: "mappin.and.ellipse")
                        }
                        if let subj = listing.subject {
                            Label(subj.capitalized, systemImage: "book.fill")
                        }
                        if let p = listing.price_per_hour {
                            Label("\(Int(p)) PLN/h", systemImage: "banknote.fill")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))

                    if let desc = listing.description {
                        Text(desc)
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                }
                .padding(16)
            }
            // ВАЖНО: маску и контур применяем к целой карточке,
            // и через compositingGroup, чтобы обрезка была ПОСЛЕ любых трансформаций
            .compositingGroup()
            .mask(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
                    .blendMode(.overlay)
            )
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
        }
    }
}
