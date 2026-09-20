// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// The table opponent's real, deterministic policy. This is a reference view over
/// `TableHand.policy`, so the explanation and the bot can never drift into two rules.
struct TablePolicyReferenceView: View {
    let hand: TableHand
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GT.Space.section) {
                    rangeSummary
                    policySection(title: "포스트플랍 기본 · 상대가 먼저 행동할 때") { bucket in
                        hand.policy.opens(with: bucket)
                            ? "벳 · 팟의 \(pctText(hand.policy.betFraction * 100))%"
                            : "체크"
                    }
                    policySection(title: "포스트플랍 기본 · 내가 벳했을 때") { bucket in
                        switch hand.policy.response(toBetWith: bucket) {
                        case .fold: return "폴드"
                        case .call: return "콜"
                        case .raise: return "레이즈"
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: "테이블에서 적용되는 제한")
                        Text("벳은 남은 스택보다 커질 수 없어요. 리버의 끝난 드로우는 노페어로 다뤄요. "
                             + "한 스트리트에서 레이즈가 이미 나왔거나 스택이 부족하면 레이즈할 버킷도 콜해요. "
                             + "내가 상대의 벳을 레이즈한 뒤에는 상대가 다시 레이즈하지 않고, 폴드하지 않는 버킷은 콜해요.")
                            .font(GT.body(12.5)).foregroundStyle(GT.onFeltSecondary)
                            .lineSpacing(GT.Typography.bodyLineSpacing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text("프리플랍은 이 표와 별개예요. 상대의 자리별 오픈 레인지에서 시작하고, 내 3벳에는 그 상대의 3벳 콜 레인지로 다시 좁혀요.")
                        .font(GT.body(12.5)).foregroundStyle(GT.onFeltSecondary)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("실제 플레이어는 같은 핸드도 섞어서 행동할 수 있어요. 이 표는 연습용 상대의 고정된 규칙이에요.")
                        .font(GT.body(12.5)).foregroundStyle(GT.onFeltSecondary)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
            }
            .background(FeltBackground())
            .navigationTitle("\(hand.villain.name) 전략과 레인지")
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
            SectionLabel(text: "현재 상대 레인지")
            Text("\(hand.villainCombos.count)콤보")
                .font(GT.title(28).monospacedDigit()).foregroundStyle(GT.onFelt)
            Text("\(hand.villainSeat.rawValue) 오픈 레인지에서 내 카드와 공개된 보드를 빼고, 지금까지 본 상대 행동과 맞는 조합만 남긴 수예요.")
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
                        Text(bucket.korean)
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
