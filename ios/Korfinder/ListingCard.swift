import SwiftUI

struct ListingCard: View {
    let listing: ListingOut
    var showDescription: Bool = true

    private var subtitle: String {
        let subj = listing.subject?.capitalized ?? "—"
        let lvl  = listing.level?.capitalized ?? "—"
        let priceText: String = {
            if let p = listing.price_per_hour { return "\(Int(p)) zł/h" }
            return "— zł/h"
        }()
        return "\(subj) • \(lvl) • \(priceText)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle().fill(KorColor.brand.opacity(0.25))
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(KorColor.brand)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text(listing.title)
                    .font(.headline)

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
