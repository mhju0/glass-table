// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// A short run of lessons a new player takes in order. Tracks regroup the existing
/// nodes; they add no node and rename none, so saved progress is untouched.
public struct LearningTrack: Equatable, Identifiable, Sendable {
    public enum ID: String, CaseIterable, Sendable {
        case basics, startingHands, priceAndChance, readingOpponents
        /// Useful once the four tracks feel easy. Never suggested, never required.
        case deeper
    }

    public let id: ID
    /// Lessons, easiest first.
    public let lessons: [CurriculumNode]
    /// One mixed round to finish on. Optional, and it may draw on "Go deeper" topics.
    public let challenge: CurriculumNode?

    public var isOptional: Bool { id == .deeper }

    /// Skills to practise one at a time. Call-or-fold has no lesson of its own; it is
    /// the decision the price-and-chance lessons build up to.
    public var concepts: [Concept] {
        lessons.compactMap(Curriculum.taughtConcept) + (id == .priceAndChance ? [.callFold] : [])
    }
}

public extension Curriculum {
    /// The path a new player is shown (decision D46). Lessons outside it stay in
    /// `units` with their saved progress, but are not offered.
    static let tracks: [LearningTrack] = [
        track(.basics, ["u1-showdown", "u1-potMath"], challenge: "u1-boss"),
        track(.startingHands, ["u1-position", "u3-rfi", "u8-defend"], challenge: "u3-boss"),
        track(.priceAndChance, ["u2-outs", "u2-equitySense", "u2-potOdds"], challenge: "u2-boss"),
        track(.readingOpponents, ["u4-rangeRead", "u7-actionRead"], challenge: "u4-boss"),
        track(.deeper, ["u1-combos", "u3-notation", "u2-evCall"], challenge: nil),
    ]

    private static func track(_ id: LearningTrack.ID, _ lessons: [String], challenge: String?) -> LearningTrack {
        LearningTrack(id: id, lessons: lessons.map { node(id: $0)! }, challenge: challenge.map { node(id: $0)! })
    }

    /// The four tracks' lessons in suggested order, without challenges or "Go deeper".
    static let trackLessons: [CurriculumNode] = tracks.filter { !$0.isOptional }.flatMap(\.lessons)

    static func track(containing node: CurriculumNode) -> LearningTrack? {
        tracks.first { $0.lessons.contains(node) || $0.challenge == node }
    }

    /// The next lesson to suggest: the first unfinished one from where the learner's
    /// level starts, then any left before it. A suggestion only. Every lesson stays open.
    static func suggestedLesson(in state: ProgressState) -> CurriculumNode? {
        let start = startIndex(in: state)
        return trackLessons[start...].first { isOwed($0, in: state) }
            ?? trackLessons[..<start].first { isOwed($0, in: state) }
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
