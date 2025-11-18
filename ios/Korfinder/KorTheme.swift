//
//  KorTheme.swift
//  Korfinder
//
//  Created by martin on 2.10.25.
//

import SwiftUI

enum KorColor {
    static let brand  = Color("PurplePrimary")
    static let brand2 = Color("Brand/PurpleSecondary")
    static let indigo = Color("Brand/KorIndigo") // опционально

    static var grad: LinearGradient {
        LinearGradient(
            colors: [KorColor.brand2, KorColor.brand],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}
