// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
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
        self.session = DrillSession(baseSeed: baseSeed, progress: store.load(),
                                    generate: generate, grade: grade)
        #if DEBUG
        // GT_DEMO_DRILL=<slug> + GT_DEMO_REVEAL=<n>: open at spot n's reveal for screenshots.
        let env = ProcessInfo.processInfo.environment
        if env["GT_DEMO_DRILL"] == slug, let n = env["GT_DEMO_REVEAL"], let idx = Int(n) {
            for _ in 0..<idx { session.next() }
            session.commit(demoAnswer)
        }
        #endif
    }

    var phase: DrillSession<Spot, Answer, Reveal>.Phase { session.phase }
    var streak: Int { session.progress.streak }

    func commit(_ answer: Answer) { session.commit(answer); store.save(session.progress) }
    func next() { session.next() }
}
