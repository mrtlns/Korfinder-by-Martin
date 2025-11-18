import SwiftUI

struct SwipeDeckView: View {
    var items: [ListingOut]
    /// Возвращает true, если сервер ответил «match»
    var onSwipe: (Int, Bool) async -> Bool = { _,_ in false }
    var onReload: (() -> Void)? = nil

    @State private var index = 0
    @State private var drag: CGSize = .zero
    @State private var showMatch = false
    @State private var matchedTitle = ""
    @State private var finished = false
    @State private var expandedListing: ListingOut?

    private let threshold: CGFloat = 120
    private let rotation:  CGFloat = 12
    private let MARGIN_V: CGFloat = 14
    private let MARGIN_H: CGFloat = 18

    // MARK: - BODY

    var body: some View {
        GeometryReader { geo in
            content(geo: geo)
        }
        // попап матча
        .sheet(isPresented: $showMatch) {
            MatchPopupView(title: matchedTitle)
                .presentationDetents([.fraction(0.45)])
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: items.map(\.id)) { _ in
            index = 0
            drag = .zero
            finished = items.isEmpty
            expandedListing = nil
        }
    }

    // MARK: - Основной контент

    @ViewBuilder
    private func content(geo: GeometryProxy) -> some View {
        ZStack {
            KorBackground().ignoresSafeArea()

            if finished || index >= items.count {
                emptyStateView()
                    .allowsHitTesting(expandedListing == nil)
            } else {
                deckView(geo: geo)
                    .allowsHitTesting(expandedListing == nil)
            }

            if let listing = expandedListing {
                detailView(listing: listing)
                    .zIndex(10)
            }
        }
    }

    // MARK: - Пустой фид

    private func emptyStateView() -> some View {
        EmptyFeedView {
            index = 0
            drag  = .zero
            finished = false
            onReload?()
        }
    }

    // MARK: - Колода карточек

    private func deckView(geo: GeometryProxy) -> some View {
        let regionH = geo.size.height - geo.safeAreaInsets.bottom
        let cardH   = max(320, regionH - MARGIN_V * 2)

        return VStack(spacing: 0) {
            Spacer(minLength: MARGIN_V)

            ZStack {
                // следующая карточка — в фоне
                if index + 1 < items.count {
                    SwipeCardView(listing: items[index + 1])
                        .frame(height: cardH)
                        .padding(.horizontal, MARGIN_H)
                        .scaleEffect(0.965)
                        .offset(y: 8)
                        .allowsHitTesting(false)
                        .opacity(expandedListing == nil ? 1 : 0)
                }

                // текущая карточка
                SwipeCardView(listing: items[index])
                    .frame(height: cardH)
                    .padding(.horizontal, MARGIN_H)
                    .contentShape(Rectangle())
                    .overlay(alignment: .topLeading) {
                        if drag.width > 40 {
                            Badge(text: "LIKE", color: .green, angle: -14)
                                .padding(24)
                                .opacity(min(Double((drag.width - 40) / 80), 1))
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if drag.width < -40 {
                            Badge(text: "NOPE", color: .red, angle: 14)
                                .padding(24)
                                .opacity(min(Double((-drag.width - 40) / 80), 1))
                        }
                    }
                    .rotationEffect(
                        .degrees(Double(drag.width / 10)) * Double(rotation / 12)
                    )
                    .offset(x: drag.width, y: drag.height)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                drag = value.translation
                            }
                            .onEnded { value in
                                endDrag(value.translation)
                            }
                    )
                    .onTapGesture {
                        // раскрываем эту же карточку
                        withAnimation(.spring(response: 0.45,
                                              dampingFraction: 0.88)) {
                            expandedListing = items[index]
                        }
                    }
                    .allowsHitTesting(expandedListing == nil)
            }

            // кнопки под карточкой
            HStack(spacing: 28) {
                RoundIconButton(system: "xmark") { tapSwipe(like: false) }
                    .accessibilityLabel("Nope")
                RoundIconButton(system: "heart.fill") { tapSwipe(like: true) }
                    .accessibilityLabel("Like")
            }
            .padding(.top, 12)
            .opacity(expandedListing == nil ? 1 : 0)

            Spacer(minLength: MARGIN_V)
        }
    }

    // MARK: - Детальный вид

    private func detailView(listing: ListingOut) -> some View {
        ListingDetailView(
            listing: listing,
            onClose: {
                withAnimation(.spring(response: 0.45,
                                      dampingFraction: 0.88)) {
                    expandedListing = nil
                }
            }
        )
    }

    // MARK: - Логика свайпа

    private func endDrag(_ t: CGSize) {
        let w = t.width
        let swipeAwayX: CGFloat = 700

        if w > threshold {
            withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.82)) {
                drag = CGSize(width: swipeAwayX, height: 40)
            }
            advance(like: true)

        } else if w < -threshold {
            withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.82)) {
                drag = CGSize(width: -swipeAwayX, height: 40)
            }
            advance(like: false)

        } else {
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.9)) {
                drag = .zero
            }
        }
    }

    private func tapSwipe(like: Bool) {
        let swipeAwayX: CGFloat = 700
        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.82)) {
            drag = CGSize(width: like ? swipeAwayX : -swipeAwayX, height: 40)
        }
        advance(like: like)
    }

    private func advance(like: Bool) {
        guard index < items.count else { return }
        let current = items[index]
        let currentId = current.tutor_id ?? current.id

        // смена карточки
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            drag = .zero
            index += 1
            if index >= items.count { finished = true }
        }

        // отправка свайпа
        Task {
            let matched = await onSwipe(currentId, like)
            if matched && like {
                matchedTitle = current.title
                showMatch = true
            }
        }
    }
}

// MARK: - Вспомогательные вью

private struct RoundIconButton: View {
    let system: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 22, weight: .bold))
                .frame(width: 62, height: 62)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.28), lineWidth: 1)
                        .blendMode(.overlay)
                )
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
    }
}

private struct Badge: View {
    let text: String
    let color: Color
    let angle: Double

    var body: some View {
        Text(text)
            .font(.system(size: 32, weight: .heavy, design: .rounded))
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 4)
            )
            .foregroundStyle(color)
            .rotationEffect(.degrees(angle))
    }
}
