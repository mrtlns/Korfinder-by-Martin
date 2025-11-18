//
//  ListingDetailView.swift
//  Korfinder
//
//  Created by martin on 18.11.25.
//
import SwiftUI

struct ListingDetailView: View {
    let listing: ListingOut
    var onClose: (() -> Void)? = nil        // zamknięcie z zewnątrz
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ta sama karta – nagłówek, bez opisu
                    ListingCard(listing: listing, showDescription: false)
                        .padding(.top, 8)
                        .padding(.horizontal)

                    // główny blok z opisem i szczegółami
                    VStack(alignment: .leading, spacing: 12) {
                        // pełny opis
                        if let desc = listing.description, !desc.isEmpty {
                            Text(desc)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }

                        // separator (opcjonalnie)
                        if (listing.city?.isEmpty == false) ||
                            (listing.subject?.isEmpty == false) ||
                            (listing.level?.isEmpty == false) ||
                            listing.price_per_hour != nil {
                            Divider().opacity(0.2)
                        }

                        // Dane szczegółowe
                        VStack(alignment: .leading, spacing: 8) {
                            if let city = listing.city, !city.isEmpty {
                                Label(city, systemImage: "mappin.and.ellipse")
                            }
                            if let subj = listing.subject, !subj.isEmpty {
                                Label(subj, systemImage: "book.closed")
                            }
                            if let level = listing.level, !level.isEmpty {
                                Label(level, systemImage: "graduationcap")
                            }
                            if let p = listing.price_per_hour {
                                Label("\(Int(p)) PLN/h", systemImage: "creditcard")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .kor_liquidGlass(cornerRadius: 22)
                    .padding(.horizontal)

                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Szczegóły")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zamknij") {
                        if let onClose {
                            onClose()
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .background(
                Color("Brand/PurpleBackground")
                    .ignoresSafeArea()
            )
        }
    }
}
