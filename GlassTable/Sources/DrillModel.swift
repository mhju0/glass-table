// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import Observation
import GlassTableDrills

@Observable
final class DrillModel<Spot: Equatable, Answer, Reveal: GradedReveal> {
    private var session: DrillSession<Spot, Answer, Reveal>
    private let store: ProgressStore

    /// `demoAnswer` is what the debug screenshot hook commits (GT_DEMO_*).
    init(slug: String, baseSeed: UInt64 = 20260722,
         generate: @escaping (UInt64, Int) -> Spot,
         grade: @escaping (Answer, Spot) -> Reveal,
         demoAnswer: Answer) {
        let store = ProgressStore.standard(drill: slug)
        self.store = store
        let progress = store.load()
        // Resume at progress.total so answered spots never repeat across launches/re-entries.
        self.session = DrillSession(baseSeed: baseSeed, progress: progress,
                                    startIndex: progress.total,
                                    generate: generate, grade: grade)
        #if DEBUG
        // GT_DEMO_DRILL=<slug> + GT_DEMO_REVEAL=<n>: open at spot n's reveal for screenshots.
        // Rebuilt from startIndex 0 so <n> stays an absolute spot index (demoAnswer is
        // tuned to spot n) even though normal sessions resume at progress.total.
        let env = ProcessInfo.processInfo.environment
        if env["GT_DEMO_DRILL"] == slug, let n = env["GT_DEMO_REVEAL"], let idx = Int(n) {
            session = DrillSession(baseSeed: baseSeed, progress: progress,
                                   startIndex: 0, generate: generate, grade: grade)
            for _ in 0..<idx { session.next() }
            session.commit(demoAnswer)
            store.save(session.progress)
        }
        #endif
    }

    var phase: DrillSession<Spot, Answer, Reveal>.Phase { session.phase }
    var streak: Int { session.progress.streak }

    func commit(_ answer: Answer) {
        withAnimation(.easeOut(duration: 0.22)) { session.commit(answer) }
        store.save(session.progress)
        if case let .revealed(_, reveal) = session.phase {
            let haptic = UINotificationFeedbackGenerator()
            switch reveal.band {
            case .spotOn: haptic.notificationOccurred(.success)
            case .close:  haptic.notificationOccurred(.warning)
            case .off:    haptic.notificationOccurred(.error)
            }
        }
    }
    func next() { withAnimation(.easeOut(duration: 0.22)) { session.next() } }
}
