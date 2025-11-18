import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            KorBackground()
            Text("Korfinder")
                .font(.system(size: 48, weight: .heavy))
                .foregroundStyle(.white)
                .shadow(radius: 12)
        }
    }
}
