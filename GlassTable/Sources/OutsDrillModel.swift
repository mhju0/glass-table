// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import Observation
import GlassTableDrills

@Observable
final class OutsDrillModel {
    private var session: DrillSession
    private let store: ProgressStore

    init(baseSeed: UInt64 = 20260722, store: ProgressStore = .standard()) {
        self.store = store
        self.session = DrillSession(baseSeed: baseSeed, progress: store.load())
        #if DEBUG
        // Debug-only: open straight to a given spot's reveal for state screenshots/QA.
        if let n = ProcessInfo.processInfo.environment["GT_DEMO_REVEAL"], let idx = Int(n) {
            for _ in 0..<idx { session.next() }
            session.commit()
        }
        #endif
    }

    var phase: DrillSession.Phase { session.phase }
    var streak: Int { session.progress.streak }

    func adjust(_ delta: Int) { session.adjustEstimate(delta) }
    func commit() { session.commit(); store.save(session.progress) }
    func next() { session.next() }
}
