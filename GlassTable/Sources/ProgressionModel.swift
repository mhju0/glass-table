// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import Observation
import GlassTableEngine
import GlassTableDrills

enum ProgressCommandError: Error, Equatable { case staleImport }

/// The app's single window onto the progression core.
///
/// Everything with a rule in it — unlocking, mastery, scheduling, streaks,
/// calibration — lives in `GlassTableDrills` and is tested without a simulator. This
/// type only loads, forwards, and saves, so there is no second place where a rule
/// could quietly disagree with the tested one.
@Observable
@MainActor
final class ProgressionModel {
    private(set) var state = ProgressState()
    /// Set when the store exists but will not parse. The UI must offer recovery rather
    /// than silently starting the user over (spec §8.2).
    private(set) var unreadable: String?
    /// Failed ordinary saves keep the latest answers in memory for retry or export.
    private(set) var saveError: String?
    /// A session captures this value. Import/reset changes it, rejecting late UI work.
    private(set) var epoch = UUID()
    private var pendingState: ProgressState?

    private let store: ProgressionStore
    private let scheduler = FSRSScheduler()

    var recoveryFileURL: URL? {
        guard unreadable != nil, FileManager.default.fileExists(atPath: store.url.path) else {
            return nil
        }
        return store.url
    }

    init(store: ProgressionStore? = nil) {
        let hasInjectedStore = store != nil
        let store = store ?? Self.launchStore()
        self.store = store
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if !hasInjectedStore,
           environment["GT_TEST_STORE_ID"].flatMap(UUID.init(uuidString:)) != nil,
           let nodeID = environment["GT_TEST_PATH_CURRENT_NODE"],
           let index = Curriculum.allNodes.firstIndex(where: { $0.id == nodeID }) {
            var fixture = ProgressState()
            fixture.firstLessonCompleted = true
            for node in Curriculum.allNodes[..<index] {
                fixture.nodes[node.id] = NodeRecord(cleared: true, clearedAt: Date(), attempts: 1)
            }
            state = fixture
            return
        }
        // GT_DEMO_SEED=1 — a representative mid-path state for screenshot runs.
        // Built through the real types rather than a hand-written JSON fixture, so it
        // can never encode a shape the store would reject.
        if ProcessInfo.processInfo.environment["GT_DEMO_SEED"] != nil {
            state = Self.demoState()
            return
        }
        #endif
        switch store.load() {
        case .fresh:
            // First launch on this build. Fold in any M1 per-drill progress, then
            // persist once so the next launch takes the .loaded path.
            state = LegacyMigration.migrate(from: store.url.deletingLastPathComponent(),
                                            into: ProgressState())
            save()
        case let .loaded(loaded):
            state = loaded
        case let .unreadable(reason):
            unreadable = reason
        }
    }

    private static func launchStore() -> ProgressionStore {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["GT_TEST_STORE_ID"],
           let id = UUID(uuidString: raw) {
            let standard = ProgressionStore.standard().url
            return ProgressionStore(url: standard.deletingLastPathComponent()
                .appendingPathComponent("progression-test-\(id.uuidString).json"))
        }
        #endif
        return .standard()
    }

    // MARK: - reads

    var nextNode: CurriculumNode? { Curriculum.nextNode(in: state) }

    func status(of node: CurriculumNode) -> NodeStatus {
        Curriculum.status(of: node.id, in: state)
    }

    func dueConcepts(now: Date = Date()) -> [Concept] {
        ReviewQueue.dueConcepts(in: state, at: now)
    }

    func reviewSessionConcepts(now: Date = Date()) -> [Concept] {
        ReviewQueue.sessionConcepts(in: state, at: now)
    }

    func needingExplainer() -> [Concept] { ReviewQueue.needingExplainer(in: state) }

    func record(for concept: Concept) -> ConceptRecord { state.record(for: concept) }

    /// Spec §4.3: the number the home screen leads with, never XP and never streak.
    var masteredCount: Int {
        Concept.allCases.filter { state.record(for: $0).tier >= .proficient }.count
    }

    var calibrationHitRate: Double? { Calibration.hitRate(in: state) }

    var calibrationVerdict: Calibration.Verdict? {
        calibrationHitRate.map { Calibration.verdict(hitRate: $0) }
    }

    /// A legacy or imported learner should land where they left off. Unknown concept
    /// and node keys count too because they can be valid history from another build.
    var shouldPresentFirstLesson: Bool {
        guard unreadable == nil else { return false }
        guard state.firstLessonCompleted != true else { return false }
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["GT_TEST_FIRST_LESSON"] == "1"
            || environment["GT_DEMO_FIRST_LESSON"] != nil { return true }
        if environment["GT_TEST_FIRST_LESSON"] == "0"
            || environment.keys.contains(where: { $0.hasPrefix("GT_DEMO_") }) {
            return false
        }
        #endif
        return !hasHistoricalActivity
    }

    private var hasHistoricalActivity: Bool {
        !state.concepts.isEmpty || !state.nodes.isEmpty || !state.answers.isEmpty
            || state.streak.current > 0 || state.streak.longest > 0
            || state.streak.lastSessionDay != nil
            || state.streak.lastFreezeEarnedDay != nil
    }

    /// Spec §4.6: three misses in a row means the explanation didn't land.
    func shouldOfferWalkthrough(_ concept: Concept) -> Bool {
        Mastery.shouldOfferWalkthrough(state.record(for: concept))
    }

    /// The count that seeds a concept's next spot. Answers with help add to it, so
    /// opening help, leaving and starting again deals a different spot. Without help
    /// it equals the graded total, keeping earlier seeds unchanged.
    func seedCount(for concept: Concept) -> Int {
        state.record(for: concept).total + state.assistedAttempts(for: concept)
    }

    // MARK: - writes

    enum HelpRoute { case lesson, round, review }

    /// Records that the learner opened help showing the current question's calculation.
    /// Only a question awaiting its answer can be marked; a round's guided "together"
    /// step never is. The UI shows the help only after this returns true.
    @discardableResult
    func markHelpUsed(_ route: HelpRoute, sessionID: String, ordinal: Int,
                      expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch else { return false }
        switch route {
        case .lesson:
            guard let session = state.activeNodeSession, session.id == sessionID,
                  session.phase == .question, session.ordinal == ordinal else { return false }
            if session.helpOrdinal == ordinal { return true }
            return commit { $0.activeNodeSession?.helpOrdinal = ordinal }
        case .round:
            guard let round = state.activeRound, round.id == sessionID,
                  round.introPhase == nil, round.phase == .question,
                  round.ordinal == ordinal else { return false }
            if round.helpOrdinal == ordinal { return true }
            return commit { $0.activeRound?.helpOrdinal = ordinal }
        case .review:
            guard let session = state.activeReviewSession, session.id == sessionID,
                  session.phase == .question, session.ordinal == ordinal else { return false }
            if session.helpOrdinal == ordinal { return true }
            return commit { $0.activeReviewSession?.helpOrdinal = ordinal }
        }
    }

    /// Whether the given question's help was opened. Restored screens read this so
    /// shown totals stay shown.
    func helpUsed(_ route: HelpRoute, sessionID: String, ordinal: Int) -> Bool {
        switch route {
        case .lesson:
            state.activeNodeSession.map { $0.id == sessionID && $0.helpOrdinal == ordinal } ?? false
        case .round:
            state.activeRound.map { $0.id == sessionID && $0.helpOrdinal == ordinal } ?? false
        case .review:
            state.activeReviewSession.map { $0.id == sessionID && $0.helpOrdinal == ordinal } ?? false
        }
    }

    /// One graded answer: counts, miss streak, FSRS schedule, calibration log.
    @discardableResult
    func record(concept: Concept, band: GradeBand, interval: IntervalAnswer? = nil,
                evLoss: Double? = nil, now: Date = Date(),
                attemptID: String? = nil, mode: String = "practice",
                language: LearningLanguage = .korean,
                assisted: Bool = false, eligibleSeconds: Double? = nil,
                expectedEpoch: UUID? = nil) -> Bool {
        if let expectedEpoch, expectedEpoch != epoch { return false }
        if let attemptID, state.processedAttemptIDs.contains(attemptID) { return true }
        return commit { candidate in
        if assisted {
            ReviewQueue.recordAssistedPractice(&candidate, concept: concept, now: now)
        } else {
            ReviewQueue.recordReview(&candidate, concept: concept, rating: .forBand(band),
                                     interval: interval, now: now, scheduler: scheduler,
                                     evLoss: evLoss)
        }
        if let attemptID {
            candidate.processedAttemptIDs.insert(attemptID)
            let key = DailyPracticeKey(day: DayKey(now), concept: concept.rawValue,
                                       mode: mode, formatVersion: 1,
                                       language: language.rawValue, assisted: assisted)
            candidate.recordDetailedAttempt(PracticeEvidence(
                attemptID: attemptID, key: key, at: now, band: band,
                eligibleCorrectSeconds: !assisted && band == .spotOn
                    && (evLoss == nil || evLoss == 0) ? eligibleSeconds : nil,
                decisionLossBB: evLoss))
        }
        }
    }

    /// Marks a fully answered node cleared, then evaluates each concept against only
    /// its own current-session evidence. Missing or extra evidence changes nothing.
    @discardableResult
    func completeNode(_ node: CurriculumNode, scheduled: [Concept],
                      evidence: [Concept: SessionEvidence], now: Date = Date()) -> Bool {
        guard Curriculum.isValidSession(scheduled, for: node),
              SessionEvidence.validates(evidence, scheduled: scheduled)
        else { return false }
        return commit { candidate in
        var record = candidate.nodes[node.id] ?? NodeRecord()
        record.attempts += 1
        record.cleared = true
        if record.clearedAt == nil { record.clearedAt = now }
        candidate.nodes[node.id] = record

        let viaBoss: Bool
        if case .boss = node.kind { viaBoss = true } else { viaBoss = false }
        for concept in Set(scheduled) {
            guard let conceptEvidence = evidence[concept],
                  conceptEvidence.attempted > 0 else { continue }
            candidate.updateRecord(for: concept) {
                Mastery.promote(&$0, evidence: conceptEvidence, viaBoss: viaBoss, now: now)
            }
        }
        }
    }

    /// A finished walkthrough releases the stuck-state guard without fabricating a
    /// graded attempt, review schedule, streak credit, or mastery evidence.
    func completeWalkthrough(concept: Concept) {
        _ = commit { Mastery.completeWalkthrough(&$0, concept: concept) }
    }

    /// The introduction is practice, not assessment. Completing or skipping it writes
    /// only this marker: no answer, streak, review date, node, or mastery changes.
    func completeFirstLesson() {
        _ = commit { $0.firstLessonCompleted = true }
    }

    /// Learn leads with the basics lesson only for someone who has not started the
    /// course: nothing cleared, no starting-point recommendation, lesson unfinished.
    var shouldSuggestBasicsLesson: Bool {
        state.basicsLessonCompleted != true
            && state.placement?.recommendedConcept == nil
            && !Curriculum.allNodes.contains { status(of: $0) == .cleared }
    }

    /// Like the first lesson, the basics lesson is practice: finishing it writes only
    /// its marker.
    func completeBasicsLesson() {
        _ = commit { $0.basicsLessonCompleted = true }
    }

    // MARK: - beginner sessions and durable summaries

    /// A new round never replaces an unfinished round by accident.
    @discardableResult
    func beginRound(concept: Concept, seed: UInt64, roundID: String = UUID().uuidString,
                    expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, state.activeRound == nil else { return false }
        let needsIntro = state.record(for: concept).total == 0
            && !state.introducedConcepts.contains(concept.rawValue)
        return commit { candidate in
            candidate.activeRound = PracticeRound(id: roundID, concept: concept.rawValue,
                seed: seed, introPhase: needsIntro ? .show : nil)
        }
    }

    @discardableResult
    func advanceRoundIntroduction(roundID: String, skip: Bool,
                                  expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let round = state.activeRound,
              round.id == roundID, let phase = round.introPhase else { return false }
        return commit { candidate in
            if phase == .show && !skip {
                candidate.activeRound?.introPhase = .together
            } else {
                candidate.activeRound?.introPhase = nil
                candidate.activeRound?.guidedDraft = nil
                candidate.activeRound?.guidedAnswer = nil
                candidate.introducedConcepts.insert(round.concept)
            }
        }
    }

    @discardableResult
    func setRoundShowBeat(roundID: String, index: Int, expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let round = state.activeRound,
              round.id == roundID, round.introPhase == .show,
              (0...100).contains(index) else { return false }
        if round.showBeatIndex == index { return true }
        return commit { $0.activeRound?.showBeatIndex = index }
    }

    @discardableResult
    func saveRoundGuidedDraft(roundID: String, input: SavedDrillDraftInput,
                              expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let round = state.activeRound,
              round.id == roundID, round.introPhase == .together,
              round.guidedAnswer == nil,
              let concept = Concept(rawValue: round.concept), input.isValid(for: concept)
        else { return false }
        let draft = SavedDrillDraft(ordinal: 0, concept: round.concept, input: input)
        if round.guidedDraft == draft { return true }
        return commit { $0.activeRound?.guidedDraft = draft }
    }

    @discardableResult
    func commitRoundGuidedAnswer(roundID: String, band: GradeBand,
                                 input: Data, reveal: Data,
                                 expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let round = state.activeRound,
              round.id == roundID, round.introPhase == .together,
              !input.isEmpty, !reveal.isEmpty else { return false }
        if round.guidedAnswer != nil { return true }
        return commit { candidate in
            candidate.activeRound?.guidedAnswer = RoundAnswer(
                attemptID: "guided:\(round.id)", ordinal: 0, band: band,
                submittedAt: Date(), input: input, reveal: reveal)
            candidate.activeRound?.guidedDraft = nil
        }
    }

    @discardableResult
    func saveRoundDraft(roundID: String, ordinal: Int, input: SavedDrillDraftInput,
                        expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let round = state.activeRound,
              round.id == roundID, round.ordinal == ordinal, round.phase == .question,
              let concept = Concept(rawValue: round.concept), input.isValid(for: concept)
        else { return false }
        let draft = SavedDrillDraft(ordinal: ordinal, concept: concept.rawValue, input: input)
        if round.draft == draft { return true }
        return commit { $0.activeRound?.draft = draft }
    }

    /// One disk transaction holds the grade, FSRS state, daily count and reveal.
    /// Repeating the same command cannot count the answer twice.
    @discardableResult
    func commitRoundAnswer(roundID: String, attemptID: String, ordinal: Int,
                           band: GradeBand, language: String, assisted: Bool,
                           formatVersion: Int = 1, input: Data, reveal: Data,
                           eligibleSeconds: Double? = nil, interval: IntervalAnswer? = nil,
                           evLoss: Double? = nil, now: Date = Date(),
                           expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch,
              let round = state.activeRound, round.id == roundID,
              ["ko", "en"].contains(language), !attemptID.isEmpty,
              !input.isEmpty, !reveal.isEmpty,
              eligibleSeconds.map({ $0.isFinite && $0 >= 0 }) ?? true,
              evLoss.map({ $0.isFinite && $0 >= 0 }) ?? true
        else { return false }
        if round.answers.contains(where: { $0.attemptID == attemptID }) { return true }
        guard round.phase == .question, round.introPhase == nil,
              round.ordinal == ordinal,
              let concept = Concept(rawValue: round.concept),
              round.formatVersion == formatVersion else { return false }
        let assisted = assisted || round.helpOrdinal == ordinal
        return commit { candidate in
            if assisted {
                ReviewQueue.recordAssistedPractice(&candidate, concept: concept, now: now)
            } else {
                ReviewQueue.recordReview(&candidate, concept: concept,
                                         rating: .forBand(band), interval: interval,
                                         now: now, scheduler: scheduler, evLoss: evLoss)
            }
            let key = DailyPracticeKey(day: DayKey(now), concept: concept.rawValue,
                                       mode: "single-skill", formatVersion: formatVersion,
                                       language: language, assisted: assisted)
            let seconds = !assisted && band == .spotOn
                && (evLoss == nil || evLoss == 0) ? eligibleSeconds : nil
            candidate.recordDetailedAttempt(PracticeEvidence(
                attemptID: attemptID, key: key, at: now, band: band,
                eligibleCorrectSeconds: seconds, decisionLossBB: evLoss))
            candidate.activeRound?.answers.append(RoundAnswer(
                attemptID: attemptID, ordinal: ordinal, band: band,
                submittedAt: now, input: input, reveal: reveal, assisted: assisted))
            candidate.activeRound?.phase = .reveal
            candidate.activeRound?.draft = nil
        }
    }

    @discardableResult
    func nextRoundQuestion(roundID: String, afterOrdinal: Int,
                           expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let round = state.activeRound,
              round.id == roundID else { return false }
        if round.ordinal > afterOrdinal || round.phase == .finished { return true }
        guard round.ordinal == afterOrdinal, round.phase == .reveal else { return false }
        return commit { candidate in
            if afterOrdinal + 1 == round.questionCount {
                candidate.activeRound?.phase = .finished
            } else {
                candidate.activeRound?.ordinal += 1
                candidate.activeRound?.phase = .question
            }
            candidate.activeRound?.draft = nil
            candidate.activeRound?.helpOrdinal = nil
        }
    }

    @discardableResult
    func dismissFinishedRound(roundID: String, expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let round = state.activeRound,
              round.id == roundID, round.phase == .finished else { return false }
        return commit { $0.activeRound = nil }
    }

    @discardableResult
    func beginReviewSession(now: Date = Date(), seed: UInt64, expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch else { return false }
        if state.activeReviewSession != nil { return true }
        let concepts = ReviewQueue.sessionConcepts(in: state, at: now)
        guard !concepts.isEmpty else { return false }
        return commit { candidate in
            candidate.activeReviewSession = ReviewSessionSnapshot(
                id: UUID().uuidString, seed: seed,
                scheduledConcepts: concepts.map(\.rawValue))
        }
    }

    @discardableResult
    func saveReviewDraft(sessionID: String, ordinal: Int, input: SavedDrillDraftInput,
                         expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let session = state.activeReviewSession,
              session.id == sessionID, session.ordinal == ordinal,
              session.phase == .question,
              let concept = Concept(rawValue: session.scheduledConcepts[ordinal]),
              input.isValid(for: concept) else { return false }
        let draft = SavedDrillDraft(ordinal: ordinal, concept: concept.rawValue, input: input)
        if session.draft == draft { return true }
        return commit { $0.activeReviewSession?.draft = draft }
    }

    @discardableResult
    func commitReviewAnswer(sessionID: String, attemptID: String, ordinal: Int,
                            band: GradeBand, input: Data, reveal: Data,
                            language: LearningLanguage, assisted: Bool = false,
                            interval: IntervalAnswer? = nil,
                            evLoss: Double? = nil, eligibleSeconds: Double? = nil,
                            now: Date = Date(), expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let session = state.activeReviewSession,
              session.id == sessionID, !attemptID.isEmpty,
              !input.isEmpty, !reveal.isEmpty,
              eligibleSeconds.map({ $0.isFinite && $0 >= 0 }) ?? true else { return false }
        if session.answers.contains(where: { $0.answer.attemptID == attemptID }) { return true }
        guard session.phase == .question, session.ordinal == ordinal,
              let concept = Concept(rawValue: session.scheduledConcepts[ordinal])
        else { return false }
        // Help leaves the concept unscheduled, so it stays due and returns later.
        let assisted = assisted || session.helpOrdinal == ordinal
        return commit { candidate in
            if assisted {
                ReviewQueue.recordAssistedPractice(&candidate, concept: concept, now: now)
            } else {
                ReviewQueue.recordReview(&candidate, concept: concept, rating: .forBand(band),
                                         interval: interval, now: now, scheduler: scheduler,
                                         evLoss: evLoss)
            }
            let key = DailyPracticeKey(day: DayKey(now), concept: concept.rawValue,
                mode: "review", formatVersion: session.formatVersion,
                language: language.rawValue, assisted: assisted)
            candidate.recordDetailedAttempt(PracticeEvidence(
                attemptID: attemptID, key: key, at: now, band: band,
                eligibleCorrectSeconds: !assisted && band == .spotOn
                    && (evLoss == nil || evLoss == 0) ? eligibleSeconds : nil,
                decisionLossBB: evLoss))
            candidate.activeReviewSession?.answers.append(NodeGradedAnswer(
                concept: concept.rawValue, answer: RoundAnswer(attemptID: attemptID,
                    ordinal: ordinal, band: band, submittedAt: now,
                    input: input, reveal: reveal, assisted: assisted)))
            candidate.activeReviewSession?.phase = .reveal
            candidate.activeReviewSession?.draft = nil
        }
    }

    @discardableResult
    func nextReviewQuestion(sessionID: String, afterOrdinal: Int,
                            expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let session = state.activeReviewSession,
              session.id == sessionID else { return false }
        if session.ordinal > afterOrdinal || session.phase == .finished { return true }
        guard session.ordinal == afterOrdinal, session.phase == .reveal else { return false }
        return commit { candidate in
            if afterOrdinal + 1 == session.scheduledConcepts.count {
                candidate.activeReviewSession?.phase = .finished
            } else {
                candidate.activeReviewSession?.ordinal += 1
                candidate.activeReviewSession?.phase = .question
            }
            candidate.activeReviewSession?.draft = nil
            candidate.activeReviewSession?.helpOrdinal = nil
        }
    }

    @discardableResult
    func dismissFinishedReviewSession(sessionID: String, expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, state.activeReviewSession?.id == sessionID,
              state.activeReviewSession?.phase == .finished else { return false }
        return commit { $0.activeReviewSession = nil }
    }

    /// Only an explicit concept change discards the unfinished question sequence;
    /// each already committed answer remains in the concepts and daily history.
    @discardableResult
    func abandonRound(roundID: String, expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, state.activeRound?.id == roundID else { return false }
        return commit { $0.activeRound = nil }
    }

    @discardableResult
    func beginNodeSession(_ node: CurriculumNode, seed: UInt64,
                          expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch else { return false }
        if state.activeNodeSession?.nodeID == node.id { return true }
        guard state.activeNodeSession == nil else { return false }
        let scheduled = Curriculum.sessionConcepts(for: node, seed: seed)
        guard Curriculum.isValidSession(scheduled, for: node) else { return false }
        let taught = Curriculum.taughtConcept(of: node)
        let hasSeen = taught.map { state.record(for: $0).total > 0
            || state.introducedConcepts.contains($0.rawValue) } ?? true
        return commit { candidate in
            candidate.activeNodeSession = NodeSessionSnapshot(
                id: UUID().uuidString, nodeID: node.id, seed: seed,
                scheduledConcepts: scheduled.map(\.rawValue),
                phase: hasSeen ? .question : .show)
        }
    }

    @discardableResult
    func saveNodeDraft(sessionID: String, ordinal: Int, input: SavedDrillDraftInput,
                       expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let session = state.activeNodeSession,
              session.id == sessionID, session.ordinal == ordinal,
              session.phase == .question,
              let concept = Concept(rawValue: session.scheduledConcepts[ordinal]),
              input.isValid(for: concept) else { return false }
        let draft = SavedDrillDraft(ordinal: ordinal, concept: concept.rawValue, input: input)
        if session.draft == draft { return true }
        return commit { $0.activeNodeSession?.draft = draft }
    }

    @discardableResult
    func advanceNodeTeaching(sessionID: String, skip: Bool,
                             expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let session = state.activeNodeSession,
              session.id == sessionID,
              session.phase == .show || session.phase == .together else { return false }
        return commit { candidate in
            candidate.activeNodeSession?.phase = skip || session.phase == .together
                ? .question : .together
            if candidate.activeNodeSession?.phase == .question {
                candidate.activeNodeSession?.guidedDraft = nil
                candidate.activeNodeSession?.guidedAnswer = nil
            }
            if candidate.activeNodeSession?.phase == .question,
               let node = Curriculum.node(id: session.nodeID),
               let taught = Curriculum.taughtConcept(of: node) {
                candidate.introducedConcepts.insert(taught.rawValue)
            }
        }
    }

    @discardableResult
    func setNodeShowBeat(sessionID: String, index: Int, expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let session = state.activeNodeSession,
              session.id == sessionID, session.phase == .show,
              (0...100).contains(index) else { return false }
        if session.showBeatIndex == index { return true }
        return commit { $0.activeNodeSession?.showBeatIndex = index }
    }

    @discardableResult
    func saveNodeGuidedDraft(sessionID: String, input: SavedDrillDraftInput,
                             expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let session = state.activeNodeSession,
              session.id == sessionID, session.phase == .together,
              session.guidedAnswer == nil,
              let node = Curriculum.node(id: session.nodeID),
              let concept = Curriculum.taughtConcept(of: node)
                ?? Curriculum.concepts(of: node).first,
              input.isValid(for: concept) else { return false }
        let draft = SavedDrillDraft(ordinal: 0, concept: concept.rawValue, input: input)
        if session.guidedDraft == draft { return true }
        return commit { $0.activeNodeSession?.guidedDraft = draft }
    }

    @discardableResult
    func commitNodeGuidedAnswer(sessionID: String, band: GradeBand,
                                input: Data, reveal: Data,
                                expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let session = state.activeNodeSession,
              session.id == sessionID, session.phase == .together,
              !input.isEmpty, !reveal.isEmpty else { return false }
        if session.guidedAnswer != nil { return true }
        return commit { candidate in
            candidate.activeNodeSession?.guidedAnswer = RoundAnswer(
                attemptID: "guided:\(session.id)", ordinal: 0, band: band,
                submittedAt: Date(), input: input, reveal: reveal)
            candidate.activeNodeSession?.guidedDraft = nil
        }
    }

    @discardableResult
    func commitNodeAnswer(sessionID: String, attemptID: String, ordinal: Int,
                          band: GradeBand, input: Data, reveal: Data,
                          language: LearningLanguage, assisted: Bool = false,
                          eligibleSeconds: Double? = nil,
                          interval: IntervalAnswer? = nil, evLoss: Double? = nil,
                          now: Date = Date(), expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch,
              let session = state.activeNodeSession, session.id == sessionID,
              !attemptID.isEmpty, !input.isEmpty, !reveal.isEmpty,
              eligibleSeconds.map({ $0.isFinite && $0 >= 0 }) ?? true else { return false }
        if session.answers.contains(where: { $0.answer.attemptID == attemptID }) { return true }
        guard session.phase == .question, session.ordinal == ordinal,
              let concept = Concept(rawValue: session.scheduledConcepts[ordinal]),
              let node = Curriculum.node(id: session.nodeID) else { return false }
        let assisted = assisted || session.helpOrdinal == ordinal
        return commit { candidate in
            if assisted {
                ReviewQueue.recordAssistedPractice(&candidate, concept: concept, now: now)
            } else {
                ReviewQueue.recordReview(&candidate, concept: concept,
                    rating: .forBand(band), interval: interval, now: now,
                    scheduler: scheduler, evLoss: evLoss)
            }
            let key = DailyPracticeKey(day: DayKey(now), concept: concept.rawValue,
                mode: "path", formatVersion: session.formatVersion,
                language: language.rawValue, assisted: assisted)
            candidate.recordDetailedAttempt(PracticeEvidence(
                attemptID: attemptID, key: key, at: now, band: band,
                eligibleCorrectSeconds: !assisted && band == .spotOn
                    && (evLoss == nil || evLoss == 0)
                    ? eligibleSeconds : nil, decisionLossBB: evLoss))
            let answer = RoundAnswer(attemptID: attemptID, ordinal: ordinal,
                band: band, submittedAt: now, input: input, reveal: reveal,
                assisted: assisted)
            candidate.activeNodeSession?.answers.append(
                NodeGradedAnswer(concept: concept.rawValue, answer: answer))
            candidate.activeNodeSession?.phase = .reveal
            candidate.activeNodeSession?.draft = nil
            if ordinal + 1 == session.scheduledConcepts.count {
                let scheduled = session.scheduledConcepts.compactMap(Concept.init(rawValue:))
                var evidence: [Concept: SessionEvidence] = [:]
                for graded in candidate.activeNodeSession?.answers ?? [] {
                    guard let gradedConcept = Concept(rawValue: graded.concept) else { continue }
                    evidence[gradedConcept, default: SessionEvidence()].record(
                        spotOn: graded.answer.band == GradeBand.spotOn.rawValue,
                        assisted: graded.answer.isAssisted)
                }
                if Curriculum.isValidSession(scheduled, for: node),
                   SessionEvidence.validates(evidence, scheduled: scheduled) {
                    var nodeRecord = candidate.nodes[node.id] ?? NodeRecord()
                    nodeRecord.attempts += 1
                    nodeRecord.cleared = true
                    if nodeRecord.clearedAt == nil { nodeRecord.clearedAt = now }
                    candidate.nodes[node.id] = nodeRecord
                    let viaBoss: Bool
                    if case .boss = node.kind { viaBoss = true } else { viaBoss = false }
                    for (gradedConcept, result) in evidence where result.attempted > 0 {
                        candidate.updateRecord(for: gradedConcept) {
                            Mastery.promote(&$0, evidence: result,
                                            viaBoss: viaBoss, now: now)
                        }
                    }
                }
            }
        }
    }

    @discardableResult
    func nextNodeQuestion(sessionID: String, afterOrdinal: Int,
                          expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let session = state.activeNodeSession,
              session.id == sessionID else { return false }
        if session.ordinal > afterOrdinal || session.phase == .finished { return true }
        guard session.ordinal == afterOrdinal, session.phase == .reveal else { return false }
        return commit { candidate in
            if afterOrdinal + 1 == session.scheduledConcepts.count {
                candidate.activeNodeSession?.phase = .finished
            } else {
                candidate.activeNodeSession?.ordinal += 1
                candidate.activeNodeSession?.phase = .question
            }
            candidate.activeNodeSession?.draft = nil
            candidate.activeNodeSession?.helpOrdinal = nil
        }
    }

    @discardableResult
    func dismissFinishedNodeSession(sessionID: String, expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let session = state.activeNodeSession,
              session.id == sessionID, session.phase == .finished else { return false }
        return commit { $0.activeNodeSession = nil }
    }

    /// Explicitly changing lessons retains all committed answers and their schedule.
    @discardableResult
    func abandonNodeSession(expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, state.activeNodeSession != nil else { return false }
        return commit { $0.activeNodeSession = nil }
    }

    @discardableResult
    func markIntroductionSeen(_ concept: Concept, expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch else { return false }
        if state.introducedConcepts.contains(concept.rawValue) { return true }
        return commit { $0.introducedConcepts.insert(concept.rawValue) }
    }

    @discardableResult
    func setPlacement(report: PlacementSelfReport?, answers: [String: String],
                      skipped: Bool, expectedEpoch: UUID, now: Date = Date()) -> Bool {
        guard expectedEpoch == epoch,
              answers.keys.allSatisfy({ PlacementGuide.questionIDs.contains($0) })
        else { return false }
        let recommendation = skipped ? nil : PlacementGuide.recommendation(
            report: report, answers: answers).rawValue
        return commit { candidate in
            candidate.placement = PlacementState(selfReport: report, answers: answers,
                                                 recommendedConcept: recommendation,
                                                 completedAt: now, skipped: skipped)
        }
    }

    // MARK: - four-seat practice

    @discardableResult
    func startTable(seed: UInt64, styles: [Archetype],
                    expectedEpoch: UUID, now: Date = Date()) throws -> Bool {
        guard expectedEpoch == epoch, state.tableState == nil, (1...3).contains(styles.count) else {
            return false
        }
        var table = PracticeTableState(seed: seed, styles: styles,
                                       handID: UUID().uuidString)
        try table.advanceBots()
        let observation = observationIfSettled(table, now: now)
        return commit { candidate in
            candidate.tableState = table
            if let observation { candidate.appendHandObservation(observation) }
        }
    }

    /// Bots and settlement are reduced before the one atomic write. A duplicate
    /// action ID reads the saved table and never adds a second observation.
    @discardableResult
    func applyTableAction(_ action: PracticeAction, actionID: String,
                          handID: String, now: Date = Date(),
                          expectedEpoch: UUID) throws -> Bool {
        guard expectedEpoch == epoch, !actionID.isEmpty,
              var table = state.tableState, table.handID == handID else { return false }
        if table.appliedActionIDs.contains(actionID) { return true }
        guard table.currentSeat == 0 else { throw PracticeTableError.wrongSeat }
        try table.apply(action, actionID: actionID)
        try table.advanceBots()
        let observation = observationIfSettled(table, now: now)
        return commit { candidate in
            candidate.tableState = table
            if let observation { candidate.appendHandObservation(observation) }
        }
    }

    @discardableResult
    func nextTableHand(handID: String, after previousHandID: String,
                       expectedEpoch: UUID, now: Date = Date()) throws -> Bool {
        guard expectedEpoch == epoch, !handID.isEmpty,
              var table = state.tableState else { return false }
        if table.handID == handID { return true }
        guard table.handID == previousHandID else { return false }
        try table.nextHand(handID: handID)
        try table.advanceBots()
        let observation = observationIfSettled(table, now: now)
        return commit { candidate in
            candidate.tableState = table
            if let observation { candidate.appendHandObservation(observation) }
        }
    }

    /// Only a settled hand may return to opponent choice. Finished-hand evidence
    /// and recent progress stay in the same saved transaction.
    @discardableResult
    func leaveFinishedTable(handID: String, expectedEpoch: UUID) -> Bool {
        guard expectedEpoch == epoch, let table = state.tableState,
              table.handID == handID, table.street == .finished else { return false }
        return commit { $0.tableState = nil }
    }

    func observedStyle(asOf now: Date = Date()) -> PracticeStyleReport {
        PracticeStyleAnalysis.report(state.recentHands, asOf: DayKey(now).raw)
    }

    private func observationIfSettled(_ table: PracticeTableState,
                                      now: Date) -> PracticeHandObservation? {
        guard let review = table.review else { return nil }
        return PracticeHandObservation(handID: review.handID, day: DayKey(now).raw,
                                       voluntarilyEntered: review.learnerEnteredVoluntarily,
                                       raisedPreflop: review.learnerRaisedPreflop)
    }

    // MARK: - recovery (spec §8.2)

    func exportData() throws -> Data {
        if unreadable != nil { return try store.exportData() }
        return try store.exportData(pendingState ?? state)
    }

    func importData(_ data: Data) throws {
        try replace(with: store.importData(data))
    }

    func importPrepared(_ prepared: PreparedProgressImport) throws {
        guard prepared.expectedEpoch == epoch,
              prepared.expectedRevision == state.revision,
              saveError == nil, pendingState == nil else {
            throw ProgressCommandError.staleImport
        }
        try replace(with: prepared.state)
    }

    /// Explicit "start over": replacement must preserve the old bytes and save
    /// successfully before either the displayed state or recovery screen changes.
    func resetProgress() throws { try replace(with: ProgressState()) }

    private func replace(with replacement: ProgressState) throws {
        try store.replace(with: replacement)
        state = replacement
        epoch = UUID()
        pendingState = nil
        unreadable = nil
        saveError = nil
    }

    func retrySave() {
        guard unreadable == nil else { return }
        guard let pendingState else { save(); return }
        do {
            try store.save(pendingState)
            state = pendingState
            self.pendingState = nil
            saveError = nil
        } catch {
            saveError = String(describing: error)
        }
    }

    @discardableResult
    private func commit(_ mutate: (inout ProgressState) -> Void) -> Bool {
        guard unreadable == nil, saveError == nil else { return false }
        var candidate = state
        mutate(&candidate)
        candidate.revision += 1
        if candidate.detailedTrackingStartedAt == nil {
            candidate.detailedTrackingStartedAt = Date()
        }
        do {
            try store.save(candidate)
            state = candidate
            return true
        } catch {
            pendingState = candidate
            saveError = String(describing: error)
            return false
        }
    }

    private func save() {
        guard unreadable == nil else { return }
        do {
            try store.save(state)
            saveError = nil
        } catch {
            saveError = String(describing: error)
        }
    }

    #if DEBUG
    /// Mid-path demo state: unit 1 cleared, unit 2 started, two concepts due for
    /// review, one stuck, and enough interval answers for a calibration readout.
    static func demoState() -> ProgressState {
        var s = ProgressState()
        let now = Date()

        func study(_ c: Concept, correct: Int, total: Int, tier: MasteryTier,
                   dueInDays: Double, misses: Int = 0) {
            let due = now.addingTimeInterval(86400 * dueInDays)
            // Due concepts still need a legal review chronology. The old fixed
            // `now - 2 days` value landed after the demo's three-days-overdue date,
            // so every answer save from a seeded screenshot state was rejected.
            let lastReview = min(now.addingTimeInterval(-86400 * 2),
                                 due.addingTimeInterval(-86400))
            s.updateRecord(for: c) {
                $0.correct = correct; $0.total = total; $0.tier = tier
                $0.consecutiveMisses = misses
                $0.proficientAt = tier >= .proficient ? now.addingTimeInterval(-86400 * 3) : nil
                $0.masteredAt = tier == .mastered ? now.addingTimeInterval(-86400 * 2) : nil
                $0.review = ReviewState(stability: 6, difficulty: 5,
                                        lastReview: lastReview, due: due,
                                        reps: 3)
            }
        }
        study(.showdown, correct: 18, total: 20, tier: .mastered, dueInDays: 6)
        study(.potMath, correct: 14, total: 16, tier: .proficient, dueInDays: 1)
        study(.position, correct: 11, total: 15, tier: .familiar, dueInDays: -1)
        study(.combos, correct: 9, total: 14, tier: .familiar, dueInDays: -2)
        // 8 misses, not 3: past shouldStopDrilling, so the sweep photographs 오늘's
        // 막힌 개념 panel too — at 3 the "stuck" state only ever reached 기록's row.
        study(.potOdds, correct: 4, total: 12, tier: .attempted, dueInDays: -3, misses: 8)
        study(.equitySense, correct: 6, total: 9, tier: .familiar, dueInDays: 2)

        for id in ["u1-showdown", "u1-potMath", "u1-position", "u1-combos", "u1-boss",
                   "u2-potOdds"] {
            s.nodes[id] = NodeRecord(cleared: true, clearedAt: now, attempts: 1)
        }

        // Deliberately overconfident: tight intervals that mostly miss, which is the
        // state the calibration copy is written for.
        let truths: [(Double, Double, Double)] = [
            (40, 5, 52), (30, 4, 31), (55, 6, 70), (25, 5, 26),
            (60, 5, 44), (35, 4, 36), (20, 3, 38), (48, 5, 62),
            (33, 4, 33), (44, 5, 58), (28, 4, 29), (52, 5, 66),
        ]
        for (i, t) in truths.enumerated() {
            let iv = IntervalAnswer(point: t.0, lo: t.0 - t.1, hi: t.0 + t.1, truth: t.2)
            s.append(AnswerRecord(concept: .equitySense,
                                  at: now.addingTimeInterval(-Double(i) * 3600),
                                  correct: iv.containsTruth, interval: iv))
        }

        // A spread of EV-graded answers, so 기록's 결정 card has something to average.
        // Mixed on purpose: two clean choices, a leak, and one real blunder.
        for (i, loss) in [0.0, 0.0, 0.3, 1.4, 0.0, 2.9].enumerated() {
            s.append(AnswerRecord(concept: .evLoss,
                                  at: now.addingTimeInterval(-Double(i) * 1800),
                                  correct: loss <= 0.5, evLoss: loss))
        }

        s.streak = StreakRecord(current: 12, longest: 12, lastSessionDay: DayKey(now),
                                freezesRemaining: 2, lastFreezeEarnedDay: DayKey(now))
        return s
    }
    #endif
}
