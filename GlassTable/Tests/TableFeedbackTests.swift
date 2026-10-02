import Testing
@testable import GlassTable

struct TableFeedbackTests {
    @Test func windowRetainsHighestPriorityAndDoesNotEmitEarly() {
        var c = TableFeedbackCoalescer()
        let kinds: [TableFeedbackKind] = [.tick, .chip(allIn: false), .card, .won, .commit(allIn: false), .yourTurn]
        for (index, kind) in kinds.enumerated() { c.request(kind, at: Double(index * 20)) }
        #expect(c.emit(at: 149, generation: 0) == nil)
        #expect(c.emit(at: 150, generation: 0)?.kind == .yourTurn)
        #expect(c.emit(at: 300, generation: 0) == nil)
    }
    @Test func strongerVariantWinsAndDelayedActualEmissionControlsNextDeadline() {
        var c = TableFeedbackCoalescer()
        c.request(.commit(allIn: false), at: 0)
        c.request(.commit(allIn: true), at: 50)
        #expect(c.emit(at: 1000, generation: 0)?.kind == .commit(allIn: true))
        c.request(.card, at: 1001)
        #expect(c.emit(at: 1150, generation: 0) == nil)
        #expect(c.emit(at: 1151, generation: 0)?.kind == .card)
    }
    @Test func inactiveGenerationCannotFlushOnResume() {
        var c = TableFeedbackCoalescer()
        c.request(.yourTurn, at: 0)
        c.invalidate()
        #expect(c.emit(at: 150, generation: 0) == nil)
        #expect(c.emit(at: 200, generation: 1) == nil)
        c.request(.tick, at: 300)
        #expect(c.emit(at: 500, generation: 0) == nil)
        #expect(c.emit(at: 500, generation: 1)?.kind == .tick)
    }
    @Test func staggeredCardRequestsShareTheSameWindow() {
        var c = TableFeedbackCoalescer()
        for time in [0.0, 60, 90] { c.request(.card, at: time) }
        #expect(c.deadline == 150)
        #expect(c.emit(at: 150, generation: 0)?.kind == .card)
        #expect(c.emit(at: 300, generation: 0) == nil)
    }
}
