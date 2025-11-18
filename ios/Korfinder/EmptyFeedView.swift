import SwiftUI

struct EmptyFeedView: View {
    let onReload: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Na ten moment obejrzałeś wszystkich korepetytorów.")
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)

            Button(action: onReload) {
                Text("Oglądaj ponownie")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .kor_liquidGlass(cornerRadius: 16)
            .foregroundStyle(.white)
            .buttonStyle(.plain)
        }
        .padding(24)
        .background( Color.clear )
        .contentShape(Rectangle()) // чтобы тап наверняка проходил
    }
}
