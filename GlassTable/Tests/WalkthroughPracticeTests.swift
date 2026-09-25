import XCTest
import GlassTableDrills
@testable import GlassTable

final class WalkthroughPracticeTests: XCTestCase {
    /// Every worked example asks the learner to reveal one value, so each concept's
    /// script must carry a value after its opening step, in both languages and on
    /// whatever spot the seed deals.
    func testEveryConceptExampleHasAStepToReveal() {
        for concept in Concept.allCases {
            for language in [LearningLanguage.korean, .english] {
                for seed: UInt64 in [0, 1, 0x7EAC, 0xBEEF, 12_345] {
                    let beats = Walkthrough.make(concept: concept, seed: seed, index: 0,
                                                 language: language).beats
                    XCTAssertNotNil(WalkthroughView.practiceIndex(in: beats),
                                    "\(concept) \(language) seed \(seed)")
                }
            }
        }
    }
}
