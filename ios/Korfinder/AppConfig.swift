//
//  AppConfig.swift
//  Korfinder
//
//  Created by martin on 2.10.25.
//
import Foundation

enum AppConfig {
#if DEBUG
    static let apiBase = URL(string: "http://127.0.0.1:8000")!  // симулятор → твой Mac
#else
    static let apiBase = URL(string: "https://api.korfinder.pl")!
#endif
}
