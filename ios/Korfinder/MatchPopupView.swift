//
//  MatchPopupView.swift
//  Korfinder
//
//  Created by martin on 6.10.25.
//
import SwiftUI

struct MatchPopupView: View {
    let title: String
    var body: some View {
        VStack(spacing: 14) {
            Text("To jest Match!").font(.largeTitle.bold()).foregroundStyle(.white)
            Text("Masz dopasowanie z:").font(.headline).foregroundStyle(.white.opacity(0.9))
            Text(title).font(.title2.weight(.semibold)).foregroundStyle(.white)

            Spacer()
            Text("Napisz coś miłego 💬")
                .foregroundStyle(.white.opacity(0.9))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
        )
        .padding(16)
        .background(KorBackground().ignoresSafeArea())
    }
}
