import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    enum Phase { case splash, auth, main }

    @Published var phase: Phase = .splash
    @Published var token: String?
    @Published var role: UserRole = .student    // используем глобальный enum
    @Published var onboardingDone = false
    @Published var needsOnboarding = false
    @Published var justRegistered = false

    init() {
        // Восстановим роль из кэша, если есть
        if let raw = UserDefaults.standard.string(forKey: "user.role"),
           let r = UserRole(rawValue: raw) {
            self.role = r
        }
    }

    func signIn(token: String, newUser: Bool) {
        self.token = token
        APIClient.shared.authToken = token
        self.justRegistered = newUser

        if newUser {
            // после регистрации сразу нужен онбординг
            self.onboardingDone = false
            self.needsOnboarding = true
            if let raw = UserDefaults.standard.string(forKey: "user.role"),
               let r = UserRole(rawValue: raw) {
                self.role = r
            }
            self.phase = .main
            return
        }

        // логин существующего — тянем /me
        Task { @MainActor in
            do {
                let me = try await APIClient.shared.me()
                if let r = UserRole(rawValue: me.role) { self.role = r }
                self.onboardingDone = me.onboarding_done
                self.needsOnboarding = !me.onboarding_done
                UserDefaults.standard.set(self.role.rawValue, forKey: "user.role")
            } catch {
                // на всякий случай позволим пройти онбординг
                self.needsOnboarding = true
            }
            self.phase = .main
        }
    }

    func finishOnboarding() {
        onboardingDone = true
        needsOnboarding = false
    }

    func signOut() {
        token = nil
        APIClient.shared.authToken = nil
        onboardingDone = false
        needsOnboarding = false
        role = .student
        phase = .auth
    }
}
