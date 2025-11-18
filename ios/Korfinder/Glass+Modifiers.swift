import SwiftUI

// Делает нажатую кнопку чуть светлее (приятный визуальный отклик)
struct LightenOnPressStyle: ButtonStyle {
    var amount: Double = 0.12
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? amount : 0)
    }
}

extension View {
    /// Универсальный «жидкое стекло» для карточек, кнопок, сегментов
    func kor_liquidGlass(
        cornerRadius: CGFloat = 22,
        tint: Color = KorColor.brand.opacity(0.10)   // базовый лёгкий фиолетовый тинт
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial) // размытие фона + системный материал
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint)        // фирменный оттенок
                            .blendMode(.overlay)
                    )
            )
            .overlay(
                // «стеклянная» верхняя обводка (высветление)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.45), Color.white.opacity(0.06)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .blendMode(.screen)
            )
            .overlay(
                // тонкая белая кромка для читаемости границ
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 22, x: 0, y: 14)
    }

    /// Пилюля «стекло» (редко используется, но пусть будет под рукой)
    func kor_glassPill() -> some View {
        self
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.26), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}
