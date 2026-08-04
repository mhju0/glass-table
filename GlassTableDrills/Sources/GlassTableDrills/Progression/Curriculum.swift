// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// What a node asks the user to do.
public enum NodeKind: Equatable, Sendable {
    /// A single concept, drilled. First exposure is blocked practice (spec §4.2).
    case drill(Concept)
    /// A mixed challenge. The *only* way to reach 숙달 (spec §4.3), because it
    /// certifies transfer rather than fluency.
    ///
    /// `own` is the concept the boss itself introduces, if any: 콜/폴드 *is* unit 2's
    /// boss (spec §3.2) because deciding call-or-fold is exactly the act of composing
    /// everything before it. 섞어 풀기 has no concept of its own and passes `nil`.
    case boss(own: Concept?, mixes: [Concept])
}

public struct CurriculumNode: Equatable, Identifiable, Sendable {
    public let id: String
    public let kind: NodeKind
    /// Korean title, from the approved spec §4.1 roster.
    public let title: String
}

public struct CurriculumUnit: Equatable, Sendable {
    public let id: String
    public let title: String
    /// Which section of the path this unit belongs to. Was a hardcoded 기초 in the
    /// path header, which stopped being true the moment R2 added 레인지 — the label
    /// claimed every unit was basics, including a read drill.
    public let section: String
    public let nodes: [CurriculumNode]
}

public enum NodeStatus: Equatable, Sendable {
    case locked, available, cleared
}

/// The path, by section: 기초 (R1) → 레인지 (R2's charts, R3's reads) → 보드 (R4-S1) →
/// 결정 (R4-S2).
///
/// Unlocking is strictly linear and not skippable — the only way past a node is the
/// first-run diagnostic pre-clearing it (spec §6).
public enum Curriculum {
    public static let units: [CurriculumUnit] = [
        CurriculumUnit(id: "u1", title: "테이블 읽기", section: "기초", nodes: [
            CurriculumNode(id: "u1-showdown", kind: .drill(.showdown), title: "쇼다운"),
            CurriculumNode(id: "u1-potMath", kind: .drill(.potMath), title: "팟 계산"),
            CurriculumNode(id: "u1-position", kind: .drill(.position), title: "포지션"),
            CurriculumNode(id: "u1-combos", kind: .drill(.combos), title: "콤보"),
            CurriculumNode(id: "u1-boss",
                           kind: .boss(own: nil,
                                       mixes: [.showdown, .potMath, .position, .combos]),
                           title: "섞어 풀기"),
        ]),
        CurriculumUnit(id: "u2", title: "가격과 확률", section: "기초", nodes: [
            CurriculumNode(id: "u2-potOdds", kind: .drill(.potOdds), title: "팟 오즈"),
            CurriculumNode(id: "u2-outs", kind: .drill(.outs), title: "아웃"),
            CurriculumNode(id: "u2-equitySense", kind: .drill(.equitySense), title: "에퀴티 감각"),
            CurriculumNode(id: "u2-evCall", kind: .drill(.evCall), title: "EV 계산"),
            // Reaches back into unit 1 (콤보 · 포지션) as spec §4.1 requires, and is
            // the node 첫 핸드's authored hand becomes.
            CurriculumNode(id: "u2-boss",
                           kind: .boss(own: .callFold,
                                       mixes: [.potOdds, .outs, .equitySense,
                                               .evCall, .combos, .position]),
                           title: "콜/폴드"),
        ]),
        CurriculumUnit(id: "u3", title: "표기와 차트", section: "레인지", nodes: [
            CurriculumNode(id: "u3-notation", kind: .drill(.rangeNotation),
                           title: "레인지 표기법"),
            CurriculumNode(id: "u3-rfi", kind: .drill(.rfi), title: "RFI 차트"),
            // Reaches back into both earlier units, as spec §4.1 requires.
            CurriculumNode(id: "u3-boss",
                           kind: .boss(own: nil,
                                       mixes: [.rangeNotation, .rfi, .position,
                                               .combos, .potOdds]),
                           title: "오픈 결정"),
        ]),
        // R3. One concept, so one drill node — but the boss reaches back across all
        // three earlier units, because reading an opponent is where notation, charts,
        // position and combos finally have to be used at once.
        CurriculumUnit(id: "u4", title: "상대 읽기", section: "레인지", nodes: [
            CurriculumNode(id: "u4-rangeRead", kind: .drill(.rangeRead), title: "레인지 리드"),
            CurriculumNode(id: "u4-boss",
                           kind: .boss(own: nil,
                                       mixes: [.rangeRead, .rfi, .rangeNotation,
                                               .combos, .position]),
                           // Narrowing the villain is the composite act: a read, plus
                           // the chart, plus the combos it removes.
                           title: "상대 좁히기"),
        ]),
        // R4-S1. The first postflop unit: not "what should I do", which needs the
        // EV-loss grading of S2, but "what is even out there" — the question every
        // postflop decision starts from.
        CurriculumUnit(id: "u5", title: "보드 읽기", section: "보드", nodes: [
            CurriculumNode(id: "u5-hitFrequency", kind: .drill(.hitFrequency),
                           title: "히트 프리퀀시"),
            CurriculumNode(id: "u5-rangeAdvantage", kind: .drill(.rangeAdvantage),
                           title: "레인지 어드밴티지"),
            CurriculumNode(id: "u5-boss",
                           kind: .boss(own: nil,
                                       mixes: [.hitFrequency, .rangeAdvantage,
                                               .rangeRead, .rfi, .equitySense]),
                           title: "플랍 읽기"),
        ]),
        // R4-S2. The first unit that scores a decision by what it cost rather than by
        // whether it was the one. Its boss is the first place a board read (S1) and a
        // price (u2) have to be spent in the same answer.
        CurriculumUnit(id: "u6", title: "손실 줄이기", section: "결정", nodes: [
            CurriculumNode(id: "u6-evLoss", kind: .drill(.evLoss), title: "EV 손실"),
            CurriculumNode(id: "u6-boss",
                           kind: .boss(own: nil,
                                       mixes: [.evLoss, .rangeAdvantage, .potOdds,
                                               .equitySense, .callFold]),
                           title: "리버 결정"),
        ]),
    ]

    /// Flattened in path order — this ordering *is* the unlock order.
    public static let allNodes: [CurriculumNode] = units.flatMap(\.nodes)

    public static func node(id: String) -> CurriculumNode? {
        allNodes.first { $0.id == id }
    }

    /// Every concept a node can serve up.
    public static func concepts(of node: CurriculumNode) -> [Concept] {
        switch node.kind {
        case let .drill(c): return [c]
        case let .boss(own, mixes): return (own.map { [$0] } ?? []) + mixes
        }
    }

    /// The concept a node *introduces*, as opposed to the ones it revisits.
    public static func taughtConcept(of node: CurriculumNode) -> Concept? {
        switch node.kind {
        case let .drill(c): return c
        case let .boss(own, _): return own
        }
    }

    /// Derived, never stored, so there is no second source of truth to drift from
    /// the cleared flags.
    public static func status(of nodeID: String, in state: ProgressState) -> NodeStatus {
        guard let index = allNodes.firstIndex(where: { $0.id == nodeID }) else { return .locked }
        if state.nodes[nodeID]?.cleared == true { return .cleared }
        // Available once everything before it is cleared. A pre-cleared gap from the
        // diagnostic therefore opens the node after it, rather than stranding the path.
        let precedingAllCleared = allNodes[..<index]
            .allSatisfy { state.nodes[$0.id]?.cleared == true }
        return precedingAllCleared ? .available : .locked
    }

    /// The single node 오늘 points at: the first one not yet cleared.
    public static func nextNode(in state: ProgressState) -> CurriculumNode? {
        allNodes.first { status(of: $0.id, in: state) == .available }
    }
}
