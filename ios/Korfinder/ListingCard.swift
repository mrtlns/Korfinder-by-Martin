import SwiftUI

struct ListingCard: View {
    let listing: ListingOut
    var showDescription: Bool = true

    private var subtitle: String {
        if listing.isStudent {
            let subj = listing.subject?.capitalized ?? "Wiele przedmiotów"
            let priceText: String = {
                if let p = listing.price_per_hour { return "budżet do \(Int(p)) zł/h" }
                return "budżet otwarty"
            }()
            return "\(subj) • \(priceText)"
        }

        let subj = listing.subject?.capitalized ?? "—"
        let lvl  = listing.level?.capitalized ?? "—"
        let priceText: String = {
            if let p = listing.price_per_hour { return "\(Int(p)) zł/h" }
            return "— zł/h"
        }()
        return "\(subj) • \(lvl) • \(priceText)"
    }

    private var roleBadge: some View {
        HStack(spacing: 6) {
            if listing.isTutor {
                Image(systemName: "graduationcap.fill")
            } else if listing.isStudent {
                Image(systemName: "person.text.rectangle")
            }
            Text(listing.roleDisplay ?? "")
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.white.opacity(0.18), in: Capsule())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle().fill(KorColor.brand.opacity(0.25))
                Image(systemName: listing.isTutor ? "graduationcap.fill" : "person.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(KorColor.brand)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text(listing.title)
                    .font(.headline)

                if listing.roleDisplay != nil {
                    roleBadge
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if showDescription,
                   let desc = listing.description,
                   !desc.isEmpty {
                    Text(desc)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .kor_liquidGlass(cornerRadius: 18)
    }
}
