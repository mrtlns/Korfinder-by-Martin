import SwiftUI
import UIKit

struct OnboardingWizard: View {
    @EnvironmentObject var app: AppState

    @State private var subjects: [APIClient.SubjectRes] = []
    @State private var selectedSubjectIDs = Set<Int>()
    @State private var online = true
    @State private var group  = false
    @State private var city = ""
    @State private var rate = ""        // tylko dla tutor
    @State private var expYears = 0

    @State private var step = 0
    private var totalSteps: Int { app.role == .tutor ? 4 : 3 }

    @State private var isBusy = false
    @State private var errorText: String?

    var body: some View {
        ZStack {
            KorBackground()

            VStack(spacing: 14) {
                // Прогресс-бар
                KorProgress(step: step, total: totalSteps)
                    .padding(.top, 8)

                if isLastStep {
                    // центрируем карточку и держим её ближе к верху
                    VStack {
                        Spacer(minLength: 0)
                        stepSummary
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 14) {
                            switch step {
                            case 0: stepSubjects
                            case 1: stepFormat
                            case 2: stepDetails
                            default: EmptyView()
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 10)
                    }
                }

                // В последний шаг вставляем большой Spacer перед кнопками,
                // чтобы оставить пустое место посередине и опустить кнопки вниз.
                if isLastStep {
                    Spacer(minLength: 0)
                }

                HStack(spacing: 12) {
                    KorSecondaryButton("Wstecz", disabled: step == 0) {
                        withAnimation(.easeInOut) { step = max(0, step-1) }
                    }
                    KorPrimaryButton(step == totalSteps-1 ? "Zapisz" : "Dalej") {
                        withAnimation(.easeInOut) {
                            if step < totalSteps-1 { step += 1 } else { submit() }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: — Экраны шагов
    
    private var isLastStep: Bool { step == totalSteps - 1 }

    private var stepSubjects: some View {
        KorCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Jakich przedmiotów uczysz?")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                if subjects.isEmpty {
                    ProgressView().tint(.white)
                        .task { await loadSubjects() }
                } else {
                    FlowLayout(subjects, id: \.id, spacing: 10) { s in
                        let isOn = selectedSubjectIDs.contains(s.id)
                        SubjectChip(title: s.name, isOn: isOn) {
                            if isOn { selectedSubjectIDs.remove(s.id) }
                            else    { selectedSubjectIDs.insert(s.id) }
                            Haptics.tap()
                        }
                    }
                    .padding(.top, 4)
                }

                if let e = errorText {
                    Text(e).font(.footnote).foregroundStyle(.red)
                }
            }
        }
    }

    private var stepFormat: some View {
        KorCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Format zajęć")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Toggle("Zajęcia online", isOn: $online)
                    .tint(.green)
                    .foregroundStyle(.white)

                Toggle("Zajęcia grupowe", isOn: $group)
                    .tint(.green)
                    .foregroundStyle(.white)
            }
        }
    }

    private var stepDetails: some View {
        KorCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Szczegóły (korepetytor)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                KorTextField("Miasto", text: $city)
                KorTextField("Stawka (PLN/h)", text: $rate, keyboard: .numberPad)

                HStack {
                    Text("Doświadczenie: \(expYears) lat")
                        .foregroundStyle(.white)
                    Spacer()
                    KorIconButton("-", action: { expYears = max(0, expYears-1) })
                    KorIconButton("+", action: { expYears += 1 })
                }
            }
        }
    }

    private var stepSummary: some View {
        KorCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Podsumowanie")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .padding(.bottom, 6)

                SummaryRow(icon: "book.fill",
                           label: "Przedmioty",
                           value: summarySubjects)

                SummaryRow(icon: "laptopcomputer.and.iphone",
                           label: "Format",
                           value: online ? "Online" : "Offline")

                SummaryRow(icon: "person.3.fill",
                           label: "Grupy",
                           value: group ? "tak" : "nie")

                if app.role == .tutor {
                    SummaryRow(icon: "banknote.fill",
                               label: "Stawka",
                               value: "\(rate) PLN")
                    SummaryRow(icon: "mappin.and.ellipse",
                               label: "Miasto",
                               value: city)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: 560)
        .shadow(color: KorColor.brand.opacity(0.35), radius: 22, y: 16)
        .padding(.vertical, 20)
    }

    // MARK: — Helpers

    private var summarySubjects: String {
        subjects.filter { selectedSubjectIDs.contains($0.id) }.map(\.name).joined(separator: ", ")
    }

    private func loadSubjects() async {
        do {
            let res = try await APIClient.shared.subjects()
            await MainActor.run { subjects = res; errorText = nil }
        } catch {
            await MainActor.run { errorText = mapFriendly(error).errorDescription }
        }
    }

    private func submit() {
        guard !isBusy else { return }
        isBusy = true
        Haptics.tap()

        // Сохраняем предпочтения, которыми пользуется FeedScreen
        let ud = UserDefaults.standard
        ud.set(Array(selectedSubjectIDs), forKey: "prefs.subjects")
        ud.set(online, forKey: "prefs.online")
        ud.set(!online, forKey: "prefs.offline")
        ud.set(group ? ["group"] : [], forKey: "prefs.types")
        ud.set(city.isEmpty ? nil : city, forKey: "prefs.city")
        if let r = Double(rate.replacingOccurrences(of: ",", with: ".")) {
            ud.set(r, forKey: "prefs.rate")
        } else {
            ud.removeObject(forKey: "prefs.rate")
        }

        Task { @MainActor in
            withAnimation(.easeInOut) {
                app.finishOnboarding()
            }
            isBusy = false
        }
    }
}

// ---- Cтандартные «стеклянные» компоненты ----

private struct KorCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .kor_liquidGlass(cornerRadius: 18)
            .padding(.vertical, 4)
    }
}

private struct KorPrimaryButton: View {
    let title: String; let action: () -> Void
    init(_ title: String, action: @escaping () -> Void) { self.title = title; self.action = action }
    var body: some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
        }
        .foregroundStyle(.white)
        .kor_liquidGlass(cornerRadius: 18, tint: KorColor.brand.opacity(0.18))
        .buttonStyle(LightenOnPressStyle())
    }
}

private struct KorSecondaryButton: View {
    let title: String; var disabled = false; let action: () -> Void
    init(_ title: String, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title; self.disabled = disabled; self.action = action
    }
    var body: some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
        }
        .foregroundStyle(.white.opacity(disabled ? 0.5 : 0.9))
        .kor_liquidGlass(cornerRadius: 18, tint: .clear)
        .buttonStyle(LightenOnPressStyle())
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1)
    }
}

private struct KorTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    init(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) {
        self.placeholder = placeholder; self._text = text; self.keyboard = keyboard
    }
    var body: some View {
        TextField("", text: $text)
            .keyboardType(keyboard)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .overlay(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder).foregroundStyle(.white.opacity(0.55))
                        .padding(.horizontal, 20).padding(.vertical, 14)
                }
            }
            .padding(14)
            .kor_liquidGlass(cornerRadius: 16)
            .foregroundStyle(.white)
    }
}

private struct KorIconButton: View {
    let title: String; let action: () -> Void
    init(_ title: String, action: @escaping () -> Void) { self.title = title; self.action = action }
    var body: some View {
        Button(title, action: action)
            .font(.headline)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .kor_liquidGlass(cornerRadius: 12, tint: .clear)
            .foregroundStyle(.white)
            .buttonStyle(LightenOnPressStyle())
    }
}

private struct KorProgress: View {
    let step: Int; let total: Int
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let progress = CGFloat(max(0, min(total, step+1))) / CGFloat(max(total,1))
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule().fill(Color.white.opacity(0.55))
                    .frame(width: w * progress)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 18)
    }
}

// MARK: - SubjectChip
private struct SubjectChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    private let checkW: CGFloat = 16

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.small)
                    .opacity(isOn ? 1 : 0)
                    .frame(width: checkW, height: checkW)

                Text(title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .kor_liquidGlass(
            cornerRadius: 16,
            tint: isOn ? KorColor.brand.opacity(0.32) : .clear
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(isOn ? 0.9 : 0.35),
                              lineWidth: isOn ? 1.2 : 1)
        )
        .scaleEffect(isOn ? 1.02 : 1.0)
        .shadow(color: KorColor.brand.opacity(isOn ? 0.35 : 0),
                radius: isOn ? 10 : 0, y: isOn ? 6 : 0)
        .animation(.spring(response: 0.22, dampingFraction: 0.8), value: isOn)
        .foregroundStyle(.white.opacity(isOn ? 1 : 0.92))
        .buttonStyle(LightenOnPressStyle())
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

private struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.95))
                .frame(width: 26)

            Text("\(label):")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Лёгкий хаптик
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
