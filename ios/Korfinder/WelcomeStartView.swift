//
//  WelcomeStartView.swift
//  Korfinder
//
//  Created by martin on 4.10.25.
//
import SwiftUI

struct WelcomeStartView: View {
    @EnvironmentObject var app: AppState
    @State private var role: UserRole = .student
    @State private var showAuth = false

    var body: some View {
        ZStack {
            KorBackground()

            GeometryReader { geo in
                VStack(spacing: 0) {
                    // TOP — заголовок у верхнего края
                    VStack(spacing: 10) {
                        Text("Zacznij od swipe’a")
                            .font(.system(size: 40, weight: .heavy))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        Text("Znajdź korepetytora lub ucznia\nw parę sekund.")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, max(12, geo.safeAreaInsets.top + 8))
                    .padding(.horizontal, 22)

                    // Пустое пространство посередине
                    Spacer(minLength: 0)

                    // BOTTOM — роли, кнопка и ссылка у нижнего края
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            RolePill(title: "Uczeń", system: "person", isOn: role == .student) { role = .student }
                            RolePill(title: "Korepetytor", system: "graduationcap", isOn: role == .tutor) { role = .tutor }
                        }

                        Button {
                            UserDefaults.standard.set(role.rawValue, forKey: "user.role")
                            app.role = role
                            showAuth = true
                        } label: {
                            Text("Kontynuuj")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .kor_liquidGlass(cornerRadius: 18)
                        .foregroundStyle(.white)
                        .buttonStyle(LightenOnPressStyle())

                        Button {
                            // TODO: Forgot password flow
                        } label: {
                            Text("Masz problem z logowaniem?")
                                .font(.footnote).foregroundStyle(.white.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAuth) {
            WelcomeAuthView()
                .environmentObject(app)
        }
    }
}

private struct RolePill: View {
    let title: String
    let system: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: system)
                Text(title)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .kor_liquidGlass(
            cornerRadius: 18,
            tint: isOn ? KorColor.brand.opacity(0.20) : Color.clear
        )
        .foregroundStyle(Color.white.opacity(isOn ? 1 : 0.85))
        .buttonStyle(LightenOnPressStyle())
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
