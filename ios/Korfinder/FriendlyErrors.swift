//
//  FriendlyErrors.swift
//  Korfinder
//
//  Created by martin on 4.10.25.
//

import Foundation

enum FriendlyError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword
    case emailInUse
    case userNotFound
    case wrongPassword
    case offline
    case server
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:  return "Nieprawidłowy adres e-mail."
        case .weakPassword:  return "Hasło jest za słabe (min. 8 znaków, małe/duże litery, cyfra i znak specjalny)."
        case .emailInUse:    return "Taki e-mail jest już zarejestrowany."
        case .userNotFound:  return "Użytkownik nie istnieje."
        case .wrongPassword: return "Nieprawidłowe hasło."
        case .offline:       return "Brak połączenia z internetem."
        case .server:        return "Błąd serwera. Spróbuj ponownie."
        case .unknown(let m):return m
        }
    }
}

/// Грубое, но надёжное сопоставление текста ошибки от бэка на понятные сообщения.
func mapFriendly(_ error: Error) -> FriendlyError {
    if error is URLError { return .offline }

    let raw = String(describing: error).lowercased()

    if raw.contains("invalid email")        { return .invalidEmail }
    if raw.contains("weak password")        { return .weakPassword }
    if raw.contains("already") && raw.contains("exists") { return .emailInUse }
    if raw.contains("not found")            { return .userNotFound }
    if raw.contains("wrong password") ||
       raw.contains("incorrect password")   { return .wrongPassword }

    if raw.contains("http 5")               { return .server }
    if raw.contains("http 4")               { return .unknown("Nieprawidłowe dane. Sprawdź formularz.") }

    return .unknown("Coś poszło nie tak. Spróbuj ponownie.")
}

/// Простейшая локальная валидация перед отправкой на бэк
func validateCredentials(email: String, password: String, requireStrong: Bool) -> FriendlyError? {
    // Inline-флаг (?i) — регистронезависимый regex
    let emailRegex = #/(?i)^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/#
    if email.wholeMatch(of: emailRegex) == nil {
        return .invalidEmail
    }

    if requireStrong {
        let longEnough = password.count >= 8
        let hasLower   = password.firstMatch(of: #/[a-z]/#) != nil
        let hasUpper   = password.firstMatch(of: #/[A-Z]/#) != nil
        let hasDigit   = password.firstMatch(of: #/\d/#)    != nil
        let hasSpecial = password.firstMatch(of: #/[^\w\s]/#) != nil

        if !(longEnough && hasLower && hasUpper && hasDigit && hasSpecial) {
            return .weakPassword
        }
    }
    return nil
}
