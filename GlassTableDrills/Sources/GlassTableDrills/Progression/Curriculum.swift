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
    public let nodes: [CurriculumNode]
}

public enum NodeStatus: Equatable, Sendable {
    case locked, available, cleared
}

/// The R1 path: one section (기초) of two units (spec §4.1).
///
/// Unlocking is strictly linear and not skippable in R1 — the only way past a node
/// is the first-run diagnostic pre-clearing it (spec §6).
public enum Curriculum {
    public static let units: [CurriculumUnit] = [
        CurriculumUnit(id: "u1", title: "테이블 읽기", nodes: [
            CurriculumNode(id: "u1-showdown", kind: .drill(.showdown), title: "쇼다운"),
            CurriculumNode(id: "u1-potMath", kind: .drill(.potMath), title: "팟 계산"),
            CurriculumNode(id: "u1-position", kind: .drill(.position), title: "포지션"),
            CurriculumNode(id: "u1-combos", kind: .drill(.combos), title: "콤보"),
            CurriculumNode(id: "u1-boss",
                           kind: .boss(own: nil,
                                       mixes: [.showdown, .potMath, .position, .combos]),
                           title: "섞어 풀기"),
        ]),
        CurriculumUnit(id: "u2", title: "가격과 확률", nodes: [
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
