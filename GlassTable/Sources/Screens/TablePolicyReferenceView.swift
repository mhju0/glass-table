// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// The table opponent's real, deterministic policy. This is a reference view over
/// `TableHand.policy`, so the explanation and the bot can never drift into two rules.
struct TablePolicyReferenceView: View {
    @Environment(\.learningLanguage) private var language
    let hand: TableHand
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GT.Space.section) {
                    rangeSummary
                    policySection(title: language.text("포스트플랍 기본 · 상대가 먼저 행동할 때",
                                                       "After the first betting round · opponent acts first")) { bucket in
                        hand.policy.opens(with: bucket)
                            ? language.text("벳 · 팟의 \(pctText(hand.policy.betFraction * 100))%",
                                            "Bet · \(pctText(hand.policy.betFraction * 100))% of pot")
                            : language.text("체크", "Check")
                    }
                    policySection(title: language.text("포스트플랍 기본 · 내가 벳했을 때",
                                                       "After the first betting round · I bet")) { bucket in
                        switch hand.policy.response(toBetWith: bucket) {
                        case .fold: return language.text("폴드", "Fold")
                        case .call: return language.text("콜", "Call")
                        case .raise: return language.text("레이즈", "Raise")
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: language.text("테이블에서 적용되는 제한", "Rules this table uses"))
                        Text(language.text(
                            "벳은 남은 스택보다 커질 수 없어요. 리버의 끝난 드로우는 노페어로 다뤄요. "
                            + "한 스트리트에서 레이즈가 이미 나왔거나 스택이 부족하면 레이즈할 버킷도 콜해요. "
                            + "내가 상대의 벳을 레이즈한 뒤에는 상대가 다시 레이즈하지 않고, 폴드하지 않는 버킷은 콜해요.",
                            "A bet cannot exceed the remaining stack. On the final card, a missed draw counts as no pair. "
                            + "If this betting round already had a raise or the stack is too short, a hand marked Raise calls instead. "
                            + "After I raise the opponent's bet, the opponent does not raise again and calls with hands that would not fold."))
                            .font(GT.body(12.5)).foregroundStyle(GT.onFeltSecondary)
                            .lineSpacing(GT.Typography.bodyLineSpacing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(language.text(
                        "프리플랍은 이 표와 별개예요. 상대의 자리별 오픈 레인지에서 시작하고, "
                        + "내 3벳에 상대가 콜하면 그 상대의 3벳 콜 레인지로 좁혀요. "
                        + "상대가 폴드하면 폴드 레인지를 따로 추정하지 않아요.",
                        "Before the shared cards, this table uses a separate rule. It starts with the opponent's opening hands for their seat. "
                        + "If they call my raise over the opener, their possible hands narrow to their call range. "
                        + "If they fold, this view does not infer a separate folding range."))
                        .font(GT.body(12.5)).foregroundStyle(GT.onFeltSecondary)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(language.text("실제 플레이어는 같은 핸드도 섞어서 행동할 수 있어요. 이 표는 연습용 상대의 고정된 규칙이에요.",
                                       "Real players can vary their action with the same hand. These are fixed rules for a practice opponent."))
                        .font(GT.body(12.5)).foregroundStyle(GT.onFeltSecondary)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
            }
            .background(FeltBackground())
            .navigationTitle("\(hand.villain.beginnerTitle(in: language)) \(language.text("전략과 레인지", "policy and possible hands"))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ChromeButton.close(onClose)
                }
            }
        }
    }

    private var rangeSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: language.text("현재 상대 레인지", "Possible opponent hands now"))
            Text(language.text("\(hand.villainCombos.count)콤보", "\(hand.villainCombos.count) combinations"))
                .font(GT.title(28).monospacedDigit()).foregroundStyle(GT.onFelt)
            Text(language.text(
                "\(hand.villainSeat.rawValue) 오픈 레인지에서 내 카드와 공개된 보드를 빼고, "
                + "지금까지 본 상대 행동과 맞는 조합만 남긴 수예요. "
                + "단, 프리플랍에서 내 3벳에 상대가 폴드했다면 폴드 직전의 레인지를 유지해요.",
                "From this seat's opening hands, remove my cards and the shared cards. Then keep only hands that fit the opponent's observed actions. "
                + "If they folded to my raise before the shared cards, this count stays at the range just before that fold."))
                .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtPanel()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("table-policy-range-summary")
    }

    private func policySection(title: String,
                               action: @escaping (MadeHand) -> String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title)
            VStack(spacing: 0) {
                ForEach(Array(MadeHand.allCases.enumerated()), id: \.element.rawValue) { index, bucket in
                    HStack(spacing: 12) {
                        Text(DrillTerms.madeHand(bucket, in: language))
                            .font(GT.body(14)).foregroundStyle(GT.onFelt)
                        Spacer(minLength: 12)
                        Text(action(bucket))
                            .font(GT.semibold(14)).foregroundStyle(GT.mint)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, 11)
                    .accessibilityElement(children: .combine)
                    if index < MadeHand.allCases.count - 1 {
                        Divider().overlay(GT.hairlineFelt)
                    }
                }
            }
            .padding(.horizontal, 14)
            .gtPanel()
        }
    }
}
