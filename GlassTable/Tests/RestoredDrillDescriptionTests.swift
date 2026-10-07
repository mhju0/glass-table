// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableDrills
@testable import GlassTable

final class RestoredDrillDescriptionTests: XCTestCase {
    /// A learner who was never shown the 90% range must not be told how it did.
    func testEstimateRevealLeavesTheRangeOutWhenItWasNotAsked() throws {
        for language in [LearningLanguage.korean, .english] {
            let asked = try XCTUnwrap(RestoredDrillDescription.make(
                concept: .actionRead, seed: 7, index: 0,
                input: .interval(point: 60, lo: 48, hi: 72), stored: nil, language: language, namesRange: true))
            let plain = try XCTUnwrap(RestoredDrillDescription.make(
                concept: .actionRead, seed: 7, index: 0,
                input: .interval(point: 60, lo: 48, hi: 72), stored: nil, language: language,
                namesRange: false))
            let marker = language == .korean ? "구간" : "90% range"
            XCTAssertTrue(asked.why.contains(marker))
            XCTAssertFalse(plain.why.contains(marker))
            XCTAssertTrue(asked.why.hasPrefix(plain.why))
            let unknown = try XCTUnwrap(RestoredDrillDescription.make(
                concept: .actionRead, seed: 7, index: 0,
                input: .interval(point: 60, lo: 48, hi: 72), stored: nil, language: language))
            XCTAssertEqual(unknown.why, plain.why, "Changing level must not invent confidence provenance.")
        }
    }
}
