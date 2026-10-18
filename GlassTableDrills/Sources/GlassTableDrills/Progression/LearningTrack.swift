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

/// The one lesson Learn marks (owner, 2026-10-17). Read from saved state only: there
/// is no record of the last lesson, and none is needed.
public enum MarkedLesson: Equatable, Sendable {
    /// A lesson left part-way; it picks up where the learner stopped.
    case inProgress(CurriculumNode)
    /// Hold'em basics, for a new player who has not started yet.
    case basics
    /// The suggested next lesson (`suggestedLesson`).
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
        track(.deeper, ["u1-combos", "u3-notation", "u2-evCall"], challenge: nil),
    ]

    private static func track(_ id: LearningTrack.ID, _ lessons: [String], challenge: String?) -> LearningTrack {
        LearningTrack(id: id, lessons: lessons.map { node(id: $0)! }, challenge: challenge.map { node(id: $0)! })
    }

    /// The four tracks' lessons in suggested order, without challenges or "Go deeper":
    /// exactly the order the path screen lists them.
    static let trackLessons: [CurriculumNode] = tracks.filter { !$0.isOptional }.flatMap(\.lessons)

    /// The skills the tracks teach, in path order, then "Go deeper". Concepts kept only
    /// for older saved progress (MDF, EV loss, retired drills) are not among them.
    static let skills: [Concept] = tracks.flatMap(\.concepts)

    static func track(containing node: CurriculumNode) -> LearningTrack? {
        tracks.first { $0.lessons.contains(node) || $0.challenge == node }
    }

    /// The next lesson to suggest: the first unfinished one from where the learner's
    /// level starts, then any left before it. A suggestion only. Every lesson stays open.
    /// `skipping` leaves one lesson out, for going on past a lesson not yet passed.
    static func suggestedLesson(in state: ProgressState,
                                skipping skipped: CurriculumNode? = nil) -> CurriculumNode? {
        let start = startIndex(in: state)
        let owed = { (lesson: CurriculumNode) in lesson != skipped && isOwed(lesson, in: state) }
        return trackLessons[start...].first(where: owed) ?? trackLessons[..<start].first(where: owed)
    }

    /// The open, unfinished lesson; else Hold'em basics while it is suggested; else the
    /// suggested lesson. A session saved at `.finished` (a summary closed with ✕) has
    /// nothing left to continue, so it counts as closed. Nil once every lesson is passed.
    static func markedLesson(in state: ProgressState) -> MarkedLesson? {
        if let session = state.activeNodeSession, session.phase != .finished,
           let node = node(id: session.nodeID) {
            return .inProgress(node)
        }
        if suggestsBasicsLesson(in: state) { return .basics }
        return suggestedLesson(in: state).map { .next($0) }
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
        return trackLessons.firstIndex { taughtConcept(of: $0) == concept } ?? 0
    }

    /// Not finished, and not skipped by passing its track's challenge.
    private static func isOwed(_ lesson: CurriculumNode, in state: ProgressState) -> Bool {
        state.nodes[lesson.id]?.cleared != true
            && track(containing: lesson)?.challenge.map { state.nodes[$0.id]?.cleared == true } != true
    }

    /// The challenge that lets a learner on a clean run skip the rest of this lesson's
    /// track. Nil once the track is finished or the challenge is passed.
    static func skipAheadChallenge(after node: CurriculumNode, in state: ProgressState) -> CurriculumNode? {
        guard let track = track(containing: node), !track.isOptional, track.lessons.contains(node),
              let challenge = track.challenge,
              track.lessons.contains(where: { $0 != node && isOwed($0, in: state) }) else { return nil }
        return challenge
    }

    /// Lessons a learner is asked to finish before this one, for a gentle heads-up.
    static func unfinishedGroundwork(for node: CurriculumNode, in state: ProgressState) -> [CurriculumNode] {
        guard let index = trackLessons.firstIndex(of: node) else {
            // A challenge or a deeper topic builds on its own track, or on all four.
            let base = track(containing: node).map { $0.isOptional ? trackLessons : $0.lessons } ?? []
            return base.filter { $0 != node && state.nodes[$0.id]?.cleared != true }
        }
        return trackLessons[min(startIndex(in: state), index)..<index].filter { isOwed($0, in: state) }
    }

    /// Where to send someone who found this lesson too hard: the lesson just before it
    /// on the tracks. Nil for the very first lesson, which follows the basics lesson.
    static func easierLesson(than node: CurriculumNode) -> CurriculumNode? {
        if let index = trackLessons.firstIndex(of: node) { return index > 0 ? trackLessons[index - 1] : nil }
        guard let track = track(containing: node) else { return nil }
        return track.isOptional ? trackLessons.last : track.lessons.last
    }
}
