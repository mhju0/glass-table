import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class PotMathCompatibilityTests: XCTestCase {
    // Captured from ed54c2f before the fix, including every indexed replay action.
    func testBuild35SharpQuestionsChoicesAndReplayIndexesStayIdentical() throws {
        var lines: [String] = []
        for seed: UInt64 in [0, 7, 0x9E37_79B9_7F4A_7C15] {
            for index in 0..<24 {
                let spot = PotMathSpotGenerator.spot(baseSeed: seed, index: index, level: .sharp)
                let replay = spot.replaySteps.map {
                    "\($0.actor)|\($0.kind)|\($0.addedChips)|\($0.totalContribution)"
                }.joined(separator: ";")
                lines.append("\(seed) \(index) \(spot) answer=\(spot.correctAnswer) choices=\(spot.answerChoices) replay=\(replay)")
            }
        }
        let url = try XCTUnwrap(Bundle.module.url(forResource: "build35-sharp-potmath", withExtension: "txt",
                                                   subdirectory: "Fixtures"))
        XCTAssertEqual(lines.joined(separator: "\n") + "\n", try String(contentsOf: url, encoding: .utf8))
    }

    func testBuild35SharpDraftAndRevealLoadRegradeAndKeepTheirPositions() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProgressionStore(url: dir.appendingPathComponent("progress.json"))
        for name in ["build35-sharp-potmath-draft", "build35-sharp-potmath-reveal"] {
            let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
            let bytes = try Data(contentsOf: url)
            let old = try JSONDecoder().decode(ProgressState.self, from: bytes)
            try bytes.write(to: store.url)
            guard case let .loaded(state) = store.load() else { return XCTFail("must load \(name)") }
            XCTAssertEqual(state, old)
            XCTAssertEqual(try store.importData(bytes), old, "imports regrade the old answer")
            try store.save(state)
            guard case let .loaded(back) = store.load() else { return XCTFail("must reload \(name)") }
            XCTAssertEqual(back, old)
            if let round = back.activeRound {
                XCTAssertEqual(round.ordinal, 1)
                XCTAssertEqual(round.draft?.input, .potReplay(stepIndex: 6))
                let spot = PotMathSpotGenerator.spot(baseSeed: round.seed, index: round.ordinal + 2, level: .sharp)
                XCTAssertEqual(spot.replaySteps[6].kind, .bet)
                XCTAssertEqual(spot.replaySteps[6].addedChips, 12)
                XCTAssertEqual(spot.replaySteps[6].flopTransition?.foldedActors, [.sb])
            }
            if let session = back.activeNodeSession {
                XCTAssertEqual(session.ordinal, 1)
                XCTAssertEqual(session.phase, .reveal)
                let shown = ConceptReveal(concept: .potMath, seed: session.seed, index: 3, level: .sharp,
                                          input: .integer(59), language: .english)
                XCTAssertEqual(shown?.correct, "59 chips")
                XCTAssertTrue(shown?.why.contains("SB folds") == true)
            }
        }
    }

    func testEverySharpFlopStartsAfterAllRemainingPlayersMatchTheRaise() throws {
        var sawLateSB = false, sawLateCaller = false, sawHeadsUp = false
        for seed: UInt64 in [0, 7, 91, 0x9E37_79B9_7F4A_7C15] {
            for index in 0..<100 {
                let spot = PotMathSpotGenerator.spot(baseSeed: seed, index: index, level: .sharp)
                let transition = try XCTUnwrap(spot.flopTransition)
                let stepIndex = try XCTUnwrap(spot.replaySteps.firstIndex { $0.flopTransition != nil })
                let before = Array(spot.replaySteps.prefix(stepIndex))
                var paid: [PotMathSpot.Actor: Int] = [:]
                var folded = spot.foldedActors
                for step in before { paid[step.actor, default: 0] += step.addedChips }
                folded.formUnion(transition.foldedActors)
                let live = spot.actors.filter { !folded.contains($0) }
                XCTAssertEqual(Set(live), [.bb, .opener])
                XCTAssertEqual(Set(live.map { paid[$0, default: 0] }).count, 1)
                XCTAssertEqual(spot.replaySteps[stepIndex].kind, .bet)
                XCTAssertEqual(spot.replaySteps[stepIndex].actor, .bb)
                XCTAssertEqual(spot.pot, spot.replaySteps.reduce(0) { $0 + $1.addedChips })
                if transition.foldedActors.contains(.sb) { sawLateSB = true }
                if transition.foldedActors.contains(.caller1) { sawLateCaller = true }
                if transition.foldedActors.isEmpty { sawHeadsUp = true }
            }
        }
        XCTAssertTrue(sawLateSB && sawLateCaller && sawHeadsUp)
    }

    func testFirstTwoStepsHaveNoFlopTransition() {
        for level in [DrillLevel.learn, .apply] {
            for index in 0..<24 {
                let spot = PotMathSpotGenerator.spot(baseSeed: 7, index: index, level: level)
                XCTAssertNil(spot.flopTransition)
                XCTAssertTrue(spot.replaySteps.allSatisfy { $0.flopTransition == nil })
            }
        }
    }
}
