import SwiftUI
import GlassTableEngine

struct CombinationExampleView: View {
    @Environment(\.learningLanguage) private var language
    private let examples = ["AsAh", "AsAd", "AsAc", "AhAd", "AhAc", "AdAc"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text("카드가 다르면 다른 조합이에요", "Different cards, different combinations"))
                .font(GT.title(18)).foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
            pair(examples[0])
            pair(examples[1])
            Text(language.text("둘 다 A 두 장(AA)이지만 무늬가 달라요. 카드 순서를 바꾼 것은 새 조합이 아니에요.",
                               "Both are two aces (AA), but the suits differ. Reversing their order doesn't make another combination."))
                .font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            DisclosureGroup(language.text("AA의 여섯 조합 보기", "See all six AA combinations")) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(examples, id: \.self) { pair($0) }
                    Text(language.text("카드가 보이지 않을 때는 6개예요. 보이는 A가 있으면 그 카드를 쓰는 조합은 빼요.",
                                       "There are six before any aces are visible. Exclude combinations that use an ace you can see."))
                        .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }.padding(.top, 8)
            }
            .font(GT.semibold(14)).tint(GT.inkSecondary)
            .accessibilityIdentifier("combination-all-six")
        }
        .gtInset(GT.Space.card, firstText: .title(18))
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtPanel()
        .accessibilityIdentifier("combination-physical-example")
    }

    private func pair(_ raw: String) -> some View {
        HStack(spacing: 8) {
            ForEach(Card.parse(raw) ?? [], id: \.self) { card in
                PlayingCardView(card: card, size: 44)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
