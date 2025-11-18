import SwiftUI

enum SignMode { case login, register }

struct WelcomeAuthView: View {
    @EnvironmentObject var app: AppState

    @State private var mode: SignMode = .login
    @State private var role: UserRole = UserRole.student

    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var email     = ""
    @State private var password  = ""

    @State private var isBusy = false
    @State private var errorText: String?

    var body: some View {
        ZStack {
            KorBackground()

            ScrollView {
                VStack(spacing: 22) {

                    // Заголовок
                    VStack(spacing: 10) {
                        Text("Zacznij od swipe’a")
                            .font(.system(size: 40, weight: .heavy))
                            .foregroundStyle(Color.white)
                            .multilineTextAlignment(.center)
                        Text("Znajdź korepetytora lub ucznia\nw parę sekund.")
                            .font(.callout)
                            .foregroundStyle(Color.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 36)

                    // ЕДИНАЯ кнопка: Zaloguj się <-> Utwórz konto
                    ModeTogglePill(mode: $mode)

                    // ЕДИНАЯ кнопка: Uczeń <-> Korepetytor
                    RoleTogglePill(role: $role)

                    // Форма
                    VStack(spacing: 12) {
                        if mode == .register {
                            HStack(spacing: 12) {
                                AuthField("Imię", text: $firstName)
                                AuthField("Nazwisko", text: $lastName)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        AuthField("Email", text: $email, keyboard: .emailAddress)

                        SecureField("", text: $password)
                            .textContentType(.password)
                            .placeholder("Hasło", when: password.isEmpty)
                            .padding(14)
                            .kor_liquidGlass(cornerRadius: 16)

                        if mode == .register {
                            Text("Min. 8 znaków, litery małe/duże, cyfra i znak specjalny")
                                .font(.footnote)
                                .foregroundStyle(Color.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut, value: mode)

                    if let errorText {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundStyle(Color.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }

                    // CTA
                    Button(action: submit) {
                        Text(mode == .login ? "Zaloguj się" : "Utwórz konto")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .disabled(isBusy)
                    .opacity(isBusy ? 0.7 : 1)
                    .kor_liquidGlass(cornerRadius: 18)
                    .foregroundStyle(Color.white)
                    .buttonStyle(LightenOnPressStyle())

                    // Линк «Проблемы с логином?»
                    Button {
                        // TODO: открыть экран «zabyli hasło?»
                    } label: {
                        Text("Masz problem z logowaniem?")
                            .font(.footnote)
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 60)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar) // полностью прячем навбар
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Actions
    private func submit() {
        errorText = nil

        // локальная валидация до сети
        if mode == .register {
            if let fe = validateCredentials(email: email, password: password, requireStrong: true) {
                errorText = fe.errorDescription
                return
            }
        } else {
            if let fe = validateCredentials(email: email, password: password, requireStrong: false) {
                errorText = fe.errorDescription
                return
            }
        }

        isBusy = true
        Task {
            defer { isBusy = false }
            do {
                if mode == .register {
                    let req = APIClient.AuthRegisterReq(
                        first_name: firstName,
                        last_name:  lastName,
                        email:      email,
                        role:       role.rawValue,
                        password:   password
                    )
                    let res = try await APIClient.shared.register(req)
                    UserDefaults.standard.set(role.rawValue, forKey: "user.role")
                    app.role = role
                    app.signIn(token: res.token, newUser: res.new_user ?? true)
                } else {
                    let res = try await APIClient.shared.login(
                        APIClient.AuthLoginReq(email: email, password: password)
                    )
                    app.signIn(token: res.token, newUser: res.new_user ?? false)
                }
            } catch {
                errorText = mapFriendly(error).errorDescription
            }
        }
    }
}

// MARK: - ЕДИНЫЕ «переключающие» пилюли

private struct ModeTogglePill: View {
    @Binding var mode: SignMode
    var body: some View {
        Button {
            withAnimation(.easeInOut) {
                mode = (mode == .login ? .register : .login)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: mode == .login ? "person.crop.circle" : "person.badge.plus")
                Text(mode == .login ? "Zaloguj się" : "Utwórz konto")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "arrow.2.squarepath")
                    .opacity(0.9)
            }
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .kor_liquidGlass(cornerRadius: 18)
        .foregroundStyle(.white)
        .buttonStyle(LightenOnPressStyle())
        .accessibilityLabel("Przełącz tryb logowania")
        .accessibilityValue(mode == .login ? "Logowanie" : "Rejestracja")
    }
}

private struct RoleTogglePill: View {
    @Binding var role: UserRole
    var body: some View {
        Button {
            withAnimation(.easeInOut) {
                role = (role == .student ? .tutor : .student)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: role == .student ? "person" : "graduationcap")
                Text(role == .student ? "Uczeń" : "Korepetytor")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "arrow.left.arrow.right")
                    .opacity(0.9)
            }
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .kor_liquidGlass(cornerRadius: 18)
        .foregroundStyle(.white)
        .buttonStyle(LightenOnPressStyle())
        .accessibilityLabel("Przełącz rolę")
        .accessibilityValue(role == .student ? "Uczeń" : "Korepetytor")
    }
}

// MARK: - Вспомогательные UI-компоненты

private struct SegmentedPill: View {
    let title: String; let isOn: Bool; let action: () -> Void
    init(_ title: String, isOn: Bool, action: @escaping () -> Void) {
        self.title = title; self.isOn = isOn; self.action = action
    }
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .kor_liquidGlass(
            cornerRadius: 18,
            // делаем выбранный чуть менее «густым», чтобы вернулась «стеклянность»
            tint: isOn ? KorColor.brand.opacity(0.18) : Color.clear
        )
        .foregroundStyle(Color.white.opacity(isOn ? 1.0 : 0.85))
        .buttonStyle(LightenOnPressStyle())
    }
}

private struct AuthRolePill: View {
    let title: String; let system: String; let isOn: Bool; let action: () -> Void
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
    }
}

private struct AuthField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    init(_ title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) {
        self.title = title
        self._text = text
        self.keyboard = keyboard
    }

    var body: some View {
        TextField("", text: $text)
            .keyboardType(keyboard)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .placeholder(title, when: text.isEmpty)
            .padding(14)
            .kor_liquidGlass(cornerRadius: 16)
            .foregroundStyle(Color.white)
    }
}

private extension View {
    func placeholder(_ text: String, when show: Bool) -> some View {
        overlay(alignment: .leading) {
            if show {
                Text(text)
                    .foregroundStyle(Color.white.opacity(0.55))
                    .allowsHitTesting(false)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
            }
        }
    }
}
