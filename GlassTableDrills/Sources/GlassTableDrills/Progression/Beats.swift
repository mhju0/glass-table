// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// What the board shows during one beat.
public enum BeatFocus: Equatable, Sendable {
    /// No cards — a text-only concept (포지션, 팟 계산, EV 계산).
    case none
    /// The hero / villain / board rows, with `highlight` glowing and the rest dimmed.
    case table
    /// A countable grid laid out to be counted, which is the whole point of the
    /// beat the user described: "show them in a layout where it's easily countable".
    case grid([Card])
}

/// One tap of a worked example (spec §5.2).
///
/// The board is the teaching surface and the text is the caption, never the other way
/// round. Everything here is *derived from the spot*, so a script runs on any
/// generated spot rather than only on an authored one.
public struct Beat: Equatable, Sendable {
    public let caption: String
    /// The short payload the beat exists to deliver — a hand name, a card, a count.
    /// Rendered as the largest thing in the sheet, because the caption is only its
    /// label: "지금 내 패" is not the lesson, "10 하이" is.
    public let value: String?
    public let detail: String?
    public let focus: BeatFocus
    public let highlight: [Card]
    /// Struck through **in place** rather than removed: seeing what was taken away,
    /// and why, is the lesson.
    public let struck: [Card]
    /// Not dealt yet — rendered face-down. A card leaving this set between beats is
    /// the river landing, which is what lets a walkthrough replay the actual street
    /// progression instead of presenting a finished board as a fait accompli.
    public let hidden: [Card]

    public init(_ caption: String, value: String? = nil, detail: String? = nil,
                focus: BeatFocus = .none,
                highlight: [Card] = [], struck: [Card] = [], hidden: [Card] = []) {
        self.caption = caption; self.value = value; self.detail = detail
        self.focus = focus; self.highlight = highlight
        self.struck = struck; self.hidden = hidden
    }
}

/// Templated worked examples, one script per concept.
///
/// Nothing here asserts a fact the spot does not carry. In particular the outs script
/// only says "flush" when the spot actually holds four to a suit, because
/// `OutsSpotGenerator.excludedCards` is a flush-draw heuristic and is empty otherwise.
public enum BeatScript {

    // MARK: 쇼다운

    /// Replays the hand as it was actually played: the turn, both hands as they stand,
    /// then the river lands and both are re-read before they are compared. A finished
    /// board shown all at once teaches the answer; this teaches the reading.
    public static func showdown(_ s: ShowdownSpot) -> [Beat] {
        let turn = Array(s.board.prefix(4))
        let river = Array(s.board.suffix(1))

        let heroTurn = bestFiveCards(s.hero + turn)
        let villainTurn = bestFiveCards(s.villain + turn)
        let heroRiver = bestFiveCards(s.hero + s.board)
        let villainRiver = bestFiveCards(s.villain + s.board)
        let heroTurnName = handName(bestHandOfAny(s.hero + turn))
        let villainTurnName = handName(bestHandOfAny(s.villain + turn))
        let heroName = handName(s.heroBest)
        let villainName = handName(s.villainBest)

        var beats = [
            Beat("턴까지 왔어요", detail: "보드 4장. 리버 한 장이 남았어요.",
                 focus: .table, hidden: river),
            Beat("지금 내 패", value: heroTurnName,
                 focus: .table, highlight: heroTurn, hidden: river),
            Beat("지금 상대 패", value: villainTurnName,
                 focus: .table, highlight: villainTurn, hidden: river),
            // The river lands here — nothing is highlighted, so the eye goes to the
            // one card that just changed.
            Beat("리버", value: river[0].display, detail: "두 사람 다 다시 읽어야 해요.",
                 focus: .table, highlight: river),
        ]

        beats.append(Beat("다시 읽은 내 패", value: heroName,
                          detail: heroTurnName == heroName
                              ? "그대로예요."
                              : "\(heroTurnName)에서 바뀌었어요.",
                          focus: .table, highlight: heroRiver))
        beats.append(Beat("다시 읽은 상대 패", value: villainName,
                          detail: villainTurnName == villainName
                              ? "그대로예요."
                              : "\(villainTurnName)에서 바뀌었어요.",
                          focus: .table, highlight: villainRiver))

        // Shares `showdownWhy` with the reveal, so both get the same particle
        // agreement and the same kicker sentence when the two hands share a name.
        switch s.winner {
        case 0: beats.append(Beat("내가 이겨요",
                                  detail: showdownWhy(winner: heroName, loser: villainName,
                                                      spot: s, heroWon: true),
                                  focus: .table, highlight: heroRiver))
        case 1: beats.append(Beat("상대가 이겨요",
                                  detail: showdownWhy(winner: villainName, loser: heroName,
                                                      spot: s, heroWon: false),
                                  focus: .table, highlight: villainRiver))
        default: beats.append(Beat("찹이에요", detail: "둘 다 \(heroName) — 보드가 그대로 플레이돼요.",
                                   focus: .table, highlight: s.board))
        }
        return beats
    }

    // MARK: 아웃

    public static func outs(_ s: OutsSpot) -> [Beat] {
        let unseen = 52 - Set(s.hero + s.villain + s.board).count
        // A 4-flush is the only draw shape the spot can prove it has: `excluded` is
        // non-empty exactly when hero holds four to a suit.
        let flushSuit = s.excluded.first?.suit
        let suitOuts = flushSuit.map { suit in s.outs.filter { $0.suit == suit } } ?? []
        let otherOuts = flushSuit.map { suit in s.outs.filter { $0.suit != suit } } ?? s.outs

        var beats: [Beat] = [
            Beat("지금 상황이에요", detail: "리버 한 장이 남았어요.", focus: .table),
            Beat("내 카드", focus: .table, highlight: s.hero),
            Beat("상대 카드", detail: "지금은 상대가 앞서 있어요. 리버가 나를 이기게 해줘야 해요.",
                 focus: .table, highlight: s.villain),
        ]

        if let suit = flushSuit {
            let inHand = s.hero.filter { $0.suit == suit }
            let onBoard = s.board.filter { $0.suit == suit }
            let inVillain = s.villain.filter { $0.suit == suit }
            let mine = inHand + onBoard
            let remaining = suitOuts + s.excluded
            // 13 minus every card of that suit already visible. Villain's cards are
            // face-up in this drill, so they count too — otherwise the subtraction
            // shown to the user would not reconcile with the grid below it.
            let seen = inHand.count + onBoard.count + inVillain.count
            var sub = "\(suitName(suit))는 13장. 내 손에 \(inHand.count)장, 보드에 \(onBoard.count)장"
            if !inVillain.isEmpty { sub += ", 상대에게 \(inVillain.count)장" }
            sub += " 있어요 → 13 − \(seen) = \(13 - seen)장."

            beats.append(Beat("\(suitName(suit)) \(mine.count)장을 들고 있어요",
                              detail: "한 장만 더 오면 플러시예요.",
                              focus: .table, highlight: mine))
            beats.append(Beat("남은 \(suitName(suit)) \(remaining.count)장",
                              detail: sub,
                              focus: .grid(remaining.sorted(by: byRank))))
            if !s.excluded.isEmpty {
                beats.append(Beat("그런데 \(s.excluded.map(\.display).joined(separator: "·"))는 아니에요",
                                  detail: "완성해도 상대가 더 강해져서 져요. 그래서 아웃에서 빼요.",
                                  focus: .grid(remaining.sorted(by: byRank)),
                                  struck: s.excluded))
            }
            if !otherOuts.isEmpty {
                beats.append(Beat("\(suitName(suit))가 아닌 아웃도 \(otherOuts.count)장 있어요",
                                  detail: "플러시 말고도 이기는 방법이 있어요.",
                                  focus: .grid(s.outs.sorted(by: byRank))))
            }
        } else {
            beats.append(Beat("나를 이기게 해주는 카드",
                              detail: "리버에 이 카드들이 오면 내가 앞서요.",
                              focus: .grid(s.outs.sorted(by: byRank))))
        }

        beats.append(Beat("진짜 아웃", value: "\(s.outCount)장",
                          detail: "남은 \(unseen)장 중 \(s.outCount)장 — 룰 오브 2로 약 "
                                + "\(Int(s.improvementPct))%예요.",
                          focus: .grid(s.outs.sorted(by: byRank))))
        return beats
    }

    // MARK: 팟 계산

    public static func potMath(_ s: PotMathSpot) -> [Beat] {
        var running = 0
        var beats: [Beat] = [Beat("팟은 들어간 칩을 더한 값이에요",
                                  detail: "한 줄씩 더해볼게요.")]
        for action in s.actions {
            let before = running
            switch action {
            case let .blinds(sb, bb):
                running += sb + bb
                beats.append(Beat("블라인드 \(sb) + \(bb)", detail: "팟 \(running)bb"))
            case let .bet(n):
                running += n
                beats.append(Beat("벳 \(n)bb", detail: "\(before) + \(n) = \(running)bb"))
            case let .call(n):
                running += n
                beats.append(Beat("콜 \(n)bb", detail: "\(before) + \(n) = \(running)bb"))
            case let .raiseTo(to, from):
                running += to - from
                beats.append(from == 0
                    ? Beat("레이즈 \(to)bb", detail: "\(before) + \(to) = \(running)bb")
                    : Beat("\(to)bb로 레이즈",
                           detail: "이미 넣은 \(from)은 다시 세지 않아요 — "
                                 + "\(before) − \(from) + \(to) = \(running)bb"))
            }
        }
        switch s.question {
        case .potNow:
            beats.append(Beat("그래서 팟은", value: "\(s.pot)bb"))
        case let .fractionOfPot(f):
            beats.append(Beat("팟의 \(Int((f * 100).rounded()))%", value: "\(s.correctAnswer)bb",
                              detail: "\(s.pot) × \(Int((f * 100).rounded()))%"))
        }
        return beats
    }

    // MARK: 포지션

    public static func position(_ s: PositionSpot) -> [Beat] {
        switch s.question {
        case let .behind(p, preflop):
            let order = preflop ? Position.preflopOrder : Position.postflopOrder
            let after = Array(order.drop(while: { $0 != p }).dropFirst())
            return [
                Beat("\(preflop ? "프리플랍" : "플랍 이후") 행동 순서예요",
                     detail: order.map(\.rawValue).joined(separator: " → ")),
                Beat("내 자리는 \(p.rawValue)",
                     detail: preflop
                        ? "프리플랍은 블라인드가 마지막에 행동해요."
                        : "플랍 이후에는 블라인드가 먼저, 버튼이 마지막이에요."),
                Beat(after.isEmpty ? "뒤에 아무도 없어요" : "뒤에 \(after.count)명 남았어요",
                     detail: after.isEmpty ? "\(p.rawValue)가 마지막이에요."
                                           : after.map(\.rawValue).joined(separator: " · ")),
                Beat("뒤에 사람이 많을수록 좁게 플레이해요",
                     detail: "누군가 좋은 패를 들고 있을 확률이 그만큼 올라가니까요."),
            ]
        case let .whichIsLater(a, b):
            let later = b.actsAfter(a) ? b : a
            return [
                Beat("플랍 이후 행동 순서예요",
                     detail: Position.postflopOrder.map(\.rawValue).joined(separator: " → ")),
                Beat("\(a.rawValue) vs \(b.rawValue)",
                     detail: "늦게 행동할수록 상대의 행동을 먼저 보고 결정할 수 있어요."),
                Beat("\(later.rawValue)가 더 좋아요", detail: "더 늦게 행동하니까요."),
            ]
        }
    }

    // MARK: 콤보

    public static func combos(_ s: BlockerSpot) -> [Beat] {
        let removedNames = s.removed.map(\.display).joined(separator: "·")
        return [
            Beat("\(s.className)는 원래 \(s.baseline)가지예요",
                 detail: kindExplain(s.kind)),
            Beat("그런데 이 카드들이 보여요", detail: removedNames,
                 focus: .grid(s.removed), highlight: s.removed),
            Beat("보이는 카드는 상대가 가질 수 없어요",
                 detail: "그만큼 조합이 줄어요."),
            Beat("그래서", value: "\(s.count)가지",
                 detail: "\(s.baseline) → \(s.count)"),
        ]
    }

    private static func kindExplain(_ kind: ComboKind) -> String {
        switch kind {
        case .pair: return "페어는 4장 중 2장을 고르니 6가지예요."
        case .suited: return "수티드는 무늬마다 하나씩, 4가지예요."
        default: return "두 랭크를 짝지으면 4 × 4 = 16가지예요."
        }
    }

    // MARK: 팟 오즈 · MDF

    public static func potOdds(_ s: BetSpot) -> [Beat] {
        [
            Beat("콜하면 얼마를 걸고 얼마를 받나요",
                 detail: "\(s.bet)bb를 내고, 이기면 팟 \(s.pot) + 벳 \(s.bet) + 내 콜 \(s.bet)을 가져와요."),
            Beat("필요 에퀴티 = 내 콜 ÷ 전체 팟",
                 detail: "\(s.bet) ÷ (\(s.pot) + \(s.bet) + \(s.bet))"),
            Beat("\(pctText(s.requiredPct))%보다 이길 확률이 높으면 콜",
                 detail: "낮으면 폴드가 이득이에요."),
        ]
    }

    public static func mdf(_ s: BetSpot) -> [Beat] {
        [
            Beat("상대는 \(s.bet)bb로 팟 \(s.pot)bb를 노려요",
                 detail: "내가 너무 자주 폴드하면 상대의 블러프가 공짜가 돼요."),
            Beat("MDF = 팟 ÷ (팟 + 벳)",
                 detail: "\(s.pot) ÷ (\(s.pot) + \(s.bet)) = \(pctText(s.mdfPct))%"),
            Beat("최소 \(pctText(s.mdfPct))%는 지켜요",
                 detail: "그래야 상대의 블러프가 자동 이익이 되지 않아요."),
        ]
    }

    // MARK: 에퀴티 감각

    public static func equitySense(_ s: EquitySenseSpot) -> [Beat] {
        let unseen = 52 - Set(s.hero + s.villain + s.board).count
        return [
            Beat("두 손이 보여요", detail: "여기서 쇼다운까지 갔을 때를 세어봐요.", focus: .table),
            Beat("내 카드", focus: .table, highlight: s.hero),
            Beat("상대 카드", focus: .table, highlight: s.villain),
            Beat("남은 \(unseen)장으로 가능한 보드를 전부 세요",
                 detail: "몇 번 이기는지 세면 그게 에퀴티예요.", focus: .table),
            Beat("내 에퀴티", value: "\(pctText(s.equityPct))%",
                 detail: "근사가 아니라 전부 세어본 정확한 값이에요.", focus: .table),
        ]
    }

    // MARK: EV 계산

    public static func evCall(_ s: EVCallSpot) -> [Beat] {
        let win = Double(s.pot + s.bet)
        return [
            Beat("EV는 이길 때와 질 때를 저울에 올리는 거예요"),
            Beat("이기면 \(s.pot + s.bet)bb를 가져와요",
                 detail: "\(pctText(s.equityPct))% 확률로 +\(pctText(s.equityPct / 100 * win))bb"),
            Beat("지면 \(s.bet)bb를 잃어요",
                 detail: "\(pctText(100 - s.equityPct))% 확률로 −\(pctText((1 - s.equityPct / 100) * Double(s.bet)))bb"),
            Beat("둘을 더하면", value: "\(pctText(s.evBB))bb",
                 detail: s.isProfitable ? "장기적으로 이득인 콜이에요."
                                        : "장기적으로 손해인 콜이에요."),
            Beat("이번 판의 결과는 상관없어요",
                 detail: "한 판의 승패는 이 계산을 바꾸지 않아요."),
        ]
    }

    // MARK: 콜/폴드

    public static func callFold(_ s: CallFoldSpot) -> [Beat] {
        [
            Beat("지금 상황이에요", detail: "팟 \(s.pot)bb, 상대 벳 \(s.bet)bb.", focus: .table),
            Beat("이길 확률", detail: "\(pctText(s.equityPct))%", focus: .table,
                 highlight: s.hero),
            Beat("낼 가격", detail: "필요 에퀴티 \(pctText(s.requiredPct))%"),
            Beat(s.correctIsCall ? "이길 확률이 더 커요 → 콜" : "낼 가격이 더 비싸요 → 폴드",
                 detail: "\(pctText(s.equityPct))% vs \(pctText(s.requiredPct))%"),
        ]
    }

    // MARK: helpers

    static func byRank(_ a: Card, _ b: Card) -> Bool {
        a.rank == b.rank ? a.suit < b.suit : a.rank < b.rank
    }

    /// Defers to the shared table in CardDisplay so suit names cannot drift between
    /// the walkthrough prose and the card faces.
    public static func suitName(_ suit: Int) -> String { suitKoreanName(suit) }
}
