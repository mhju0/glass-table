// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// A short run of lessons a new player takes in order. Tracks regroup the existing
/// nodes; they add no node and rename none, so saved progress is untouched.
public struct LearningTrack: Equatable, Identifiable, Sendable {
    public enum ID: String, CaseIterable, Sendable {
        /// In path order (decision D48): the game first, the math last.
        case basics, startingHands, readingOpponents, priceAndChance
        /// Useful once the four tracks feel easy. Never suggested, never required.
        case deeper
    }

    public let id: ID
    /// Lessons, easiest first.
    public let lessons: [CurriculumNode]
    /// One mixed round to finish on. Optional, and it may draw on "Go deeper" topics.
    public let challenge: CurriculumNode?

    public var isOptional: Bool { id == .deeper }

    /// Skills to practise one at a time.
    public var concepts: [Concept] {
        lessons.compactMap(Curriculum.taughtConcept)
    }
}

/// The one lesson Learn marks (owner, 2026-10-17). Read from saved state only; since
/// schema 4 that includes the last lesson started (`ProgressState.lastNodeID`, D52).
public enum MarkedLesson: Equatable, Sendable {
    /// A lesson left part-way; it picks up where the learner stopped.
    case inProgress(CurriculumNode)
    /// Hold'em basics, for a new player who has not started yet.
    case basics
    /// The lesson to start: the last one started while it is not passed, else the next
    /// owed lesson after it, else the suggested lesson (`suggestedLesson`).
    case next(CurriculumNode)
}

public extension Curriculum {
    /// The path a new player is shown (decisions D46, D48). Lessons outside it stay in
    /// `units` with their saved progress, but are not offered. Top to bottom is the
    /// suggested order: how the game plays first, then the math.
    static let tracks: [LearningTrack] = [
        track(.basics, ["u1-showdown", "u1-position"], challenge: "u1-boss"),
        track(.startingHands, ["u3-rfi", "u8-defend"], challenge: "u3-boss"),
        track(.readingOpponents, ["u4-rangeRead", "u7-actionRead"], challenge: "u4-boss"),
        track(.priceAndChance, ["u2-outs", "u1-potMath", "u2-equitySense", "u2-potOdds", "u2-callFold"],
              challenge: "u2-boss"),
        track(.deeper, ["u1-combos", "u3-notation", "u2-evCall"], challenge: "deeper-boss"),
    ]

    private static func track(_ id: LearningTrack.ID, _ lessons: [String], challenge: String?) -> LearningTrack {
        LearningTrack(id: id, lessons: lessons.map { baseNode(id: $0)! },
                      challenge: challenge.map { baseNode(id: $0)! })
    }

    /// The four tracks' lessons in suggested order, without challenges or "Go deeper":
    /// exactly the order the path screen lists them.
    static let trackLessons: [CurriculumNode] = tracks.filter { !$0.isOptional }.flatMap(\.lessons)

    static func track(containing node: CurriculumNode) -> LearningTrack? {
        tracks.first { $0.lessons.contains { $0.id == node.baseID } || $0.challenge?.id == node.baseID }
    }

    // MARK: Steps (D53)

    /// `node` at `level`: itself at the first step; a lesson whose skill reaches that
    /// step; or a challenge's `.3`, when one of its track's skills reaches Sharp.
    /// Nil for a step that does not exist.
    static func stepNode(_ node: CurriculumNode, at level: DrillLevel) -> CurriculumNode? {
        guard node.level == .learn else { return nil }
        if level == .learn { return node }
        switch node.kind {
        case let .drill(concept):
            guard DrillLevel.highest(for: concept) >= level else { return nil }
        case .boss:
            guard level == .sharp, let track = tracks.first(where: { $0.challenge == node }),
                  track.concepts.contains(where: { DrillLevel.highest(for: $0) == .sharp }) else { return nil }
        }
        return CurriculumNode(id: "\(node.id).\(level.rawValue)", kind: node.kind, title: node.title, level: level)
    }

    /// A lesson's steps, first to last.
    static func lessonSteps(for lesson: CurriculumNode) -> [CurriculumNode] {
        guard let base = baseNode(id: lesson.baseID) else { return [] }
        return DrillLevel.allCases.compactMap { stepNode(base, at: $0) }
    }

    /// The suggested order (owner default 1): each track's lessons at the first step,
    /// then those with a second step at it, then the track's challenge; after the four
    /// tracks, every lesson's third step, then each challenge again at its third step.
    /// "Go deeper" is never suggested.
    static let steps: [CurriculumNode] = firstLap + sharpLap

    /// The first lap: the four tracks at the first two steps, each with its challenge.
    private static let firstLap: [CurriculumNode] = tracks.filter { !$0.isOptional }.flatMap { track in
        track.lessons + track.lessons.compactMap { stepNode($0, at: .apply) } + [track.challenge].compactMap { $0 }
    }

    /// The second lap: every third step, then each challenge's third step.
    private static let sharpLap: [CurriculumNode] = {
        let main = tracks.filter { !$0.isOptional }
        return main.flatMap { $0.lessons.compactMap { stepNode($0, at: .sharp) } }
            + main.compactMap { $0.challenge.flatMap { stepNode($0, at: .sharp) } }
    }()

    /// The highest step of this skill's lesson the learner has passed; the first step
    /// otherwise. Practice and reviews deal the skill here.
    static func passedLevel(of concept: Concept, in state: ProgressState) -> DrillLevel {
        guard let lesson = tracks.flatMap(\.lessons).first(where: { taughtConcept(of: $0) == concept }) else {
            return .learn
        }
        return lessonSteps(for: lesson).last { $0.level > .learn && state.nodes[$0.id]?.cleared == true }?.level
            ?? .learn
    }

    /// The step a challenge deals one of its skills at: the learner's step, up to Apply
    /// in the first lap and up to Sharp in the second.
    static func challengeLevel(of concept: Concept, in challenge: CurriculumNode,
                               state: ProgressState) -> DrillLevel {
        min(challenge.level == .sharp ? .sharp : .apply, passedLevel(of: concept, in: state))
    }

    /// The next lesson to suggest: the first unfinished one from where the learner's
    /// level starts, then any left before it. A suggestion only. Every lesson stays open.
    /// `skipping` leaves one lesson out, for going on past a lesson not yet passed.
    static func suggestedLesson(in state: ProgressState,
                                skipping skipped: CurriculumNode? = nil) -> CurriculumNode? {
        let start = startIndex(in: state)
        let owed = { (step: CurriculumNode) in step != skipped && isOwed(step, in: state) }
        // The first lap from the learner's start, then what they skipped of it, then
        // the Sharp lap: a third step is never suggested before the first lap is done.
        return firstLap[start...].first(where: owed) ?? firstLap[..<start].first(where: owed)
            ?? sharpLap.first(where: owed)
    }

    /// The open, unfinished lesson; else the lesson last started, while it is not
    /// passed; once it is, the next owed lesson after it (D52). With no lesson started
    /// yet (or none this build lists): Hold'em basics while it is suggested, else the
    /// suggested lesson. A session saved at `.finished` (a summary closed with ✕) has
    /// nothing left to continue, so it counts as closed. Nil once every lesson is passed.
    static func markedLesson(in state: ProgressState) -> MarkedLesson? {
        if let session = state.activeNodeSession, session.phase != .finished,
           let node = node(id: session.nodeID) {
            return .inProgress(node)
        }
        if let last = state.lastNodeID.flatMap(node(id:)), let track = track(containing: last) {
            if state.nodes[last.id]?.cleared != true { return .next(last) }
            return lesson(after: last, in: track, state: state).map { .next($0) }
        }
        if suggestsBasicsLesson(in: state) { return .basics }
        return suggestedLesson(in: state).map { .next($0) }
    }

    /// The first owed step after a passed one in its lap. Nothing owed after it, or a
    /// "Go deeper" lesson, which has no place in the suggested order: the suggested lesson.
    private static func lesson(after node: CurriculumNode, in track: LearningTrack,
                               state: ProgressState) -> CurriculumNode? {
        guard !track.isOptional else { return suggestedLesson(in: state) }
        let lap = firstLap.contains(node) ? firstLap : sharpLap
        guard let index = lap.firstIndex(of: node) else { return suggestedLesson(in: state) }
        return lap[(index + 1)...].first { isOwed($0, in: state) } ?? suggestedLesson(in: state)
    }

    /// A new player who skipped the starting check and has passed nothing yet.
    static func suggestsBasicsLesson(in state: ProgressState) -> Bool {
        state.basicsLessonCompleted != true
            && state.level == .newToPoker
            && state.placement?.recommendedConcept == nil
            && !allNodes.contains { status(of: $0.id, in: state) == .cleared }
    }

    /// Where the suggested order begins: the starting check's result, or the level's
    /// usual first lesson when the check was skipped.
    private static func startIndex(in state: ProgressState) -> Int {
        let concept = state.placement?.recommendedConcept.flatMap(Concept.init(rawValue:))
            ?? state.level.startingConcept
        return firstLap.firstIndex { $0.level == .learn && $0.kind == .drill(concept) } ?? 0
    }

    /// The challenge whose pass skips this step: its track's challenge in the first
    /// lap, the challenge's third step in the Sharp lap. Nil for a challenge.
    private static func lapChallenge(of step: CurriculumNode) -> CurriculumNode? {
        guard case .drill = step.kind, let challenge = track(containing: step)?.challenge else { return nil }
        return step.level == .sharp ? stepNode(challenge, at: .sharp) : challenge
    }

    /// Not finished, and not skipped by passing the challenge of its lap.
    static func isOwed(_ step: CurriculumNode, in state: ProgressState) -> Bool {
        state.nodes[step.id]?.cleared != true
            && lapChallenge(of: step).map { state.nodes[$0.id]?.cleared == true } != true
    }

    /// The lesson steps of `step`'s track in the same lap: the first two steps, or the third.
    private static func lapLessons(of step: CurriculumNode) -> [CurriculumNode] {
        guard let track = track(containing: step) else { return [] }
        return steps.filter { other in
            guard case .drill = other.kind, track.lessons.contains(where: { $0.id == other.baseID }) else { return false }
            return (other.level == .sharp) == (step.level == .sharp)
        }
    }

    /// The challenge that lets a learner on a clean run skip the rest of this lesson's
    /// lap of its track. Nil once that lap is finished or the challenge is passed.
    static func skipAheadChallenge(after node: CurriculumNode, in state: ProgressState) -> CurriculumNode? {
        guard let track = track(containing: node), !track.isOptional, case .drill = node.kind,
              let challenge = lapChallenge(of: node),
              lapLessons(of: node).contains(where: { $0 != node && isOwed($0, in: state) }) else { return nil }
        return challenge
    }

    /// Lessons a learner is asked to finish before this one, for a gentle heads-up.
    /// Challenges are never groundwork: passing one only skips what it covers.
    static func unfinishedGroundwork(for node: CurriculumNode, in state: ProgressState) -> [CurriculumNode] {
        guard let track = track(containing: node) else { return [] }
        if track.isOptional {
            // A deeper topic builds on all four tracks; the deeper challenge on its own.
            let base = node == track.challenge ? track.lessons : trackLessons
            return base.filter { $0 != node && state.nodes[$0.id]?.cleared != true }
        }
        guard let index = steps.firstIndex(of: node) else { return [] }
        if case .boss = node.kind {
            // A challenge leans on its own track's lessons in the same lap.
            let sharp = node.level == .sharp
            return steps[..<index].filter { step in
                guard case .drill = step.kind, track.lessons.contains(where: { $0.id == step.baseID }),
                      (step.level == .sharp) == sharp else { return false }
                return state.nodes[step.id]?.cleared != true
            }
        }
        return steps[min(startIndex(in: state), index)..<index].filter { step in
            guard case .drill = step.kind else { return false }
            return isOwed(step, in: state)
        }
    }

    /// Where to send someone who found this lesson too hard: the step below it, or the
    /// lesson just before it on the tracks. Nil for the very first lesson, which follows
    /// the basics lesson.
    static func easierLesson(than node: CurriculumNode) -> CurriculumNode? {
        if node.level > .learn, let base = baseNode(id: node.baseID) {
            if case .boss = node.kind {
                // A challenge's third step: the last Sharp lesson of its track.
                return lapLessons(of: node).last
            }
            return lessonSteps(for: base).last { $0.level < node.level }
        }
        if let index = trackLessons.firstIndex(of: node) { return index > 0 ? trackLessons[index - 1] : nil }
        guard let track = track(containing: node) else { return nil }
        return track.isOptional && node != track.challenge ? trackLessons.last : track.lessons.last
    }
}
