import SwiftUI
import GlassTableDrills

struct OpponentPickerView: View {
    @Environment(\.learningLanguage) private var language
    @State private var selected: Archetype?
    let onStart: (Archetype) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text("상대 고르기", "Choose an opponent"))
                .font(GT.title(28)).foregroundStyle(GT.ink)
            Text(language.text("어떤 스타일과 연습할까요? 실력 순서는 아니에요.", "Which style would you like to practice against? These aren't difficulty levels."))
                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            ForEach(Archetype.allCases, id: \.self) { opponent in
                Button { selected = opponent } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(opponent.beginnerTitle(in: language)).font(GT.title(18))
                            Text(opponent.beginnerDescription(in: language))
                                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(GT.ink)
                    .padding(18).frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
                    .gtPanel().contentShape(Rectangle())
                }
                .buttonStyle(GTPress())
                .accessibilityIdentifier("opponent-\(opponent.rawValue)")
            }
        }
        .sheet(item: $selected) { opponent in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(opponent.beginnerTitle(in: language)).font(GT.title(28))
                            Text(opponent.beginnerDescription(in: language)).font(GT.body(16))
                        }
                        VStack(alignment: .leading, spacing: 18) {
                            Text(language.text("공용 카드가 나오기 전의 습관", "Starting habits"))
                                .font(GT.title(18))
                            scale(language.text("자발적으로 들어와요", "Chooses to join"), value: opponent.vpip)
                            scale(language.text("금액을 올려요", "Raises the price"), value: opponent.pfr)
                        }
                        DisclosureGroup(language.text("숫자와 포커 용어", "Numbers and poker terms")) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("VPIP \(Int(opponent.vpip))% · PFR \(Int(opponent.pfr))%")
                                Text(language.text("VPIP는 스스로 칩을 내고 들어오는 비율, PFR은 공용 카드 전에 올리는 비율이에요. 원래 이름은 \(opponent.name)이에요.", "VPIP is voluntary participation; PFR is raising before shared cards. The traditional name is \(opponent.rawValue)."))
                                Text(language.text("공개된 모델의 기준값이에요. 두 비율 모두 전체 핸드 기준이며, 실제 선택은 카드와 베팅 상황에 따라 달라져요. 관측한 성적이나 난이도가 아니에요.", "These are published model reference values, both measured per hand. Choices vary with cards and the betting situation. They aren't observed results or difficulty ratings."))
                            }
                            .font(GT.body(14)).foregroundStyle(GT.inkSecondary).padding(.top, 10)
                        }
                        FeltCTAButton(title: language.text("이 상대와 연습", "Practice with this opponent")) {
                            selected = nil
                            onStart(opponent)
                        }
                        .accessibilityIdentifier("opponent-start")
                    }
                    .padding(20)
                }
                .background(FeltBackground())
                .gtChrome(.topBarLeading) { ChromeButton.close { selected = nil } }
                .gtChrome(.topBarTrailing) { LanguageButton() }
            }
            .presentationDetents([.large])
        }
        .onAppear {
            #if DEBUG
            if let raw = ProcessInfo.processInfo.environment["GT_DEMO_OPPONENT"] {
                selected = Archetype(rawValue: raw)
            }
            #endif
        }
    }

    private func scale(_ title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(GT.semibold(15))
            ProgressView(value: value, total: 100).tint(GT.cta)
            HStack {
                Text(language.text("드물게", "Rarely"))
                Spacer()
                Text(language.text("자주", "Often"))
            }
            .font(GT.body(12)).foregroundStyle(GT.inkSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(Int(value))%")
    }
}

extension Archetype: @retroactive Identifiable {
    public var id: String { rawValue }
}
