//
//  KorBackground.swift
//  Korfinder
//
//  Created by martin on 2.10.25.
//
import SwiftUI

struct KorBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.36, green: 0.19, blue: 0.79), // фиолет (низ)
                Color(red: 0.59, green: 0.30, blue: 0.95)  // светлее (верх)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Circle()
                .fill(Color.white.opacity(0.06))
                .blur(radius: 80)
                .frame(width: 320, height: 320)
                .offset(x: -130, y: -180)
        )
        .overlay(
            Circle()
                .fill(Color.white.opacity(0.08))
                .blur(radius: 100)
                .frame(width: 280, height: 280)
                .offset(x: 140, y: 230)
        )
        .ignoresSafeArea() // ВАЖНО
    }
}
