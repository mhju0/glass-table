// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

/// Static term list from docs/glossary.md — only terms the app actually uses.
struct GlossaryView: View {
    private struct Term {
        let korean: String
        let english: String
        let definition: String
    }

    private static let terms: [Term] = [
        Term(korean: "에퀴티", english: "Equity",
             definition: "지금 쇼다운까지 가면 이길 확률. 무승부는 절반으로 계산합니다."),
        Term(korean: "팟 오즈", english: "Pot odds",
             definition: "콜 금액 대비 팟이 주는 가격. 콜이 손해가 아니려면 필요 에퀴티를 넘어야 합니다."),
        Term(korean: "필요 에퀴티", english: "Required equity",
             definition: "벳 ÷ (팟 + 벳 + 콜). 이 이상의 에퀴티가 있어야 콜이 이득입니다."),
        Term(korean: "MDF", english: "Minimum defense frequency",
             definition: "팟 ÷ (팟 + 벳). 상대 블러프가 자동 이익이 되지 않게 지켜야 할 최소 방어 빈도입니다."),
        Term(korean: "아웃", english: "Outs",
             definition: "다음 카드 중 내 핸드를 역전시켜 주는 카드의 수입니다."),
        Term(korean: "룰 오브 2/4", english: "Rule of 2/4",
             definition: "아웃 × 2%(카드 1장) 또는 × 4%(카드 2장)로 개선 확률을 빠르게 근사합니다."),
        Term(korean: "블로커", english: "Blocker",
             definition: "내가 들고 있어서 상대가 특정 핸드를 가질 콤보 수를 줄이는 카드입니다."),
        Term(korean: "콤보", english: "Combo",
             definition: "핸드 클래스의 구체적 조합 수. 페어 6개, 수티드 4개, 오프수트 12개."),
        Term(korean: "레인지", english: "Range",
             definition: "한 손이 아니라, 이 상황에서 가질 수 있는 모든 핸드의 집합으로 생각합니다."),
        Term(korean: "정확 · 근접 · 빗나감", english: "Spot-on · Close · Off",
             definition: "추정 오차 등급. 정답 맞추기가 아니라 감각을 보정(캘리브레이션)하는 훈련입니다."),
    ]

    private func row(_ term: Term) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(term.korean).font(GT.title(14)).foregroundStyle(GT.ink)
                Text("· \(term.english)").font(GT.body(11)).foregroundStyle(GT.inkMuted)
            }
            Text(term.definition)
                .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("용어집").font(GT.title(16)).foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 18)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(Self.terms.enumerated()), id: \.offset) { i, term in
                        row(term)
                        if i < Self.terms.count - 1 { Divider() }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                    .fill(.white).ignoresSafeArea(edges: .bottom))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GT.green.ignoresSafeArea())
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview { NavigationStack { GlossaryView() } }
