import SwiftUI

enum TableFeedbackKind: Equatable {
    case tick, chip(allIn: Bool), card, won, commit(allIn: Bool), yourTurn
    var priority: Int {
        switch self { case .tick: 0; case .chip: 1; case .card: 2; case .won: 3; case .commit: 4; case .yourTurn: 5 }
    }
    var strength: Int {
        switch self { case .chip(true), .commit(true): 1; default: 0 }
    }
    var sensory: SensoryFeedback {
        switch self {
        case .tick: .selection
        case let .chip(allIn): .impact(weight: .light, intensity: allIn ? 0.8 : 0.5)
        case .card: .impact(flexibility: .soft, intensity: 0.5)
        case .won: .success
        case let .commit(allIn): .impact(weight: allIn ? .heavy : .medium, intensity: 0.8)
        case .yourTurn: .impact(flexibility: .rigid, intensity: 0.75)
        }
    }
}

struct TableFeedbackPulse: Equatable { let sequence: Int; let kind: TableFeedbackKind }

/// Requests wait for the window to close; an emitted pulse cannot be undone.
struct TableFeedbackCoalescer {
    private(set) var pending: TableFeedbackKind?
    private(set) var deadline: Double?
    private(set) var lastEmission: Double?
    private(set) var generation = 0
    private var sequence = 0

    mutating func request(_ kind: TableFeedbackKind, at time: Double) {
        if pending == nil { deadline = max(time + 150, (lastEmission ?? -150) + 150) }
        if pending == nil || kind.priority > pending!.priority
            || (kind.priority == pending!.priority && kind.strength > pending!.strength) { pending = kind }
    }
    mutating func emit(at time: Double, generation: Int) -> TableFeedbackPulse? {
        guard generation == self.generation, let pending, let deadline, time >= deadline,
              lastEmission.map({ time - $0 >= 150 }) ?? true else { return nil }
        self.pending = nil
        self.deadline = nil
        lastEmission = time
        sequence += 1
        return TableFeedbackPulse(sequence: sequence, kind: pending)
    }
    mutating func invalidate() { generation += 1; pending = nil; deadline = nil }
}
