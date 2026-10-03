// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableDrills

/// Something the learner did in one lesson, read from saved progress: a track's
/// challenge passed for the first time, or a skill mastered. It never describes chips or accuracy.
enum LearningMilestone: Equatable, Hashable {
    case trackFinished(LearningTrack.ID)
    case skillMastered(Concept)

    /// Milestones reached inside a finished lesson. The session's first answer marks its
    /// start, so a rerun of a passed challenge, or mastery from an earlier day, is not one.
    static func reached(in session: NodeSessionSnapshot,
                        state: ProgressState) -> [LearningMilestone] {
        guard session.phase == .finished,
              let start = session.answers.map(\.answer.submittedAt).min()
        else { return [] }
        var result: [LearningMilestone] = []
        if let track = Curriculum.tracks.first(where: { $0.challenge?.id == session.nodeID }),
           let clearedAt = state.nodes[session.nodeID]?.clearedAt, clearedAt >= start {
            result.append(.trackFinished(track.id))
        }
        var seen = Set<Concept>()
        for raw in session.scheduledConcepts {
            guard let concept = Concept(rawValue: raw), seen.insert(concept).inserted,
                  let masteredAt = state.record(for: concept).masteredAt,
                  masteredAt >= start else { continue }
            result.append(.skillMastered(concept))
        }
        return result
    }

    func kind(in language: LearningLanguage) -> String {
        switch self {
        case .trackFinished: language.text("트랙 완료", "Track finished")
        case .skillMastered: language.text("숙달 단계", "Mastered in app")
        }
    }

    func title(in language: LearningLanguage) -> String {
        switch self {
        case let .trackFinished(id): id.title(in: language)
        case let .skillMastered(concept): ConceptIntroduction.make(concept, language: language).title
        }
    }

    func detail(in language: LearningLanguage) -> String {
        switch self {
        case let .trackFinished(id):
            let count = Curriculum.tracks.first { $0.id == id }?.concepts.count ?? 0
            return language.text("개념 \(count)개를 섞어 풀었어요.",
                                 "Passed a mixed check of \(count) skills.")
        case .skillMastered:
            return language.text("섞어 풀기에서 목표 안에 들었어요.",
                                 "On target in a mixed check.")
        }
    }
}

/// The App Store rating request: only after a milestone, at most once per app version,
/// and never under UI tests, where a system dialog would block the run.
enum RatingPrompt {
    static let storageKey = "rating.requestedVersion"

    static func shouldRequest(milestones: [LearningMilestone], version: String,
                              defaults: UserDefaults = .standard,
                              environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        guard !milestones.isEmpty, defaults.string(forKey: storageKey) != version
        else { return false }
        #if DEBUG
        if environment["GT_TEST_STORE_ID"] != nil { return false }
        #endif
        return true
    }

    static func markRequested(version: String, defaults: UserDefaults = .standard) {
        defaults.set(version, forKey: storageKey)
    }
}
