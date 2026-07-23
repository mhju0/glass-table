// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

/// 3분 시작 가이드 — the decide→reveal→grade loop and what each drill trains.
struct GuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("3분 시작 가이드").font(GT.title(26)).foregroundStyle(.white)
                    .padding(.top, 20)

                card("훈련 방식 · 결정 → 공개 → 채점") {
                    Text("""
                    모든 문제는 세 단계로 진행됩니다. 먼저 스스로 답을 \
                    정하고(결정), 정답과 풀이를 확인한 뒤(공개), \
                    정확·근접·빗나감으로 채점됩니다. 답을 보기 전에 먼저 \
                    결정하는 것이 핵심입니다 — 감이 아니라 계산으로 결정하는 \
                    습관을 만듭니다.
                    """)
                }

                card("추천 순서") {
                    Text("""
                    아웃 카운팅 → 팟 오즈 → 콜/폴드 → MDF → 블로커 순서를 \
                    추천합니다. 앞의 두 드릴이 만드는 숫자 감각을 뒤의 \
                    드릴들이 결정으로 연결합니다.
                    """)
                }

                card("아웃 카운팅 · Outs") {
                    Text("""
                    드로우에서 이기는 카드(아웃)를 세고, 룰 오브 2/4로 \
                    에퀴티를 빠르게 추정합니다. 리버까지 한 장이면 아웃 ×2, \
                    두 장이면 ×4가 대략의 에퀴티 %입니다.
                    """)
                }
                card("팟 오즈 · Pot Odds") {
                    Text("""
                    콜 가격을 필요 에퀴티 %로 바꿉니다. 필요 에퀴티 = 콜 ÷ \
                    (팟 + 벳 + 콜). 예: 팟 10bb에 10bb 벳이면 10 ÷ 30 ≈ 33%.
                    """)
                }
                card("콜/폴드") {
                    Text("""
                    추정 에퀴티와 필요 에퀴티를 비교해 결정합니다. 내 \
                    에퀴티가 가격보다 높으면 콜, 낮으면 폴드 — 앞의 두 \
                    드릴을 실전 결정으로 연결하는 훈련입니다.
                    """)
                }
                card("MDF") {
                    Text("""
                    상대 벳에 맞서 최소한 얼마나 자주 방어해야 하는지 \
                    계산합니다. MDF = 팟 ÷ (팟 + 벳). 이보다 적게 방어하면 \
                    상대의 아무 카드 블러프가 이익이 됩니다.
                    """)
                }
                card("블로커 · Blockers") {
                    Text("""
                    내 카드와 보드가 상대의 콤보를 얼마나 지우는지 셉니다. \
                    포켓 페어는 6콤보, 수티드는 4, 오프수트는 12 — 블로커가 \
                    있으면 그만큼 줄어듭니다.
                    """)
                }

                card("기록") {
                    Text("""
                    스트릭(🔥)과 정답률은 이 기기에만 저장되며, 설정 → \
                    통계에서 드릴별로 확인할 수 있습니다.
                    """)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(FeltBackground())
    }

    private func card(_ title: String, @ViewBuilder body: () -> Text) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(GT.title(16)).foregroundStyle(GT.ink)
            body()
                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview { NavigationStack { GuideView() } }
