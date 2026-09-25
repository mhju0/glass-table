import XCTest
import Foundation
@testable import GlassTableEngine

final class HandFrequencyTests: XCTestCase {
    /// Recounts every seven-card set with the engine's own evaluator. The published
    /// table must be what this app's rules produce, not a number copied from the web.
    func testPublishedCountsMatchFullEnumeration() {
        let deck = Deck.all
        let lock = NSLock()
        var counts = [Int](repeating: 0, count: 9)
        var royal = 0

        // One work item per first card; each walks the remaining six-card tails.
        DispatchQueue.concurrentPerform(iterations: 46) { a in
            var local = [Int](repeating: 0, count: 9)
            var localRoyal = 0
            var hand = [Card](repeating: deck[0], count: 7)
            hand[0] = deck[a]
            for b in (a + 1)..<47 { hand[1] = deck[b]
            for c in (b + 1)..<48 { hand[2] = deck[c]
            for d in (c + 1)..<49 { hand[3] = deck[d]
            for e in (d + 1)..<50 { hand[4] = deck[e]
            for f in (e + 1)..<51 { hand[5] = deck[f]
            for g in (f + 1)..<52 { hand[6] = deck[g]
                let key = evaluate7(hand)
                let category = key >> 20
                local[category] += 1
                if category == 8 && (key >> 16) & 0xF == 14 { localRoyal += 1 }
            } } } } } }
            lock.lock()
            for i in 0..<9 { counts[i] += local[i] }
            royal += localRoyal
            lock.unlock()
        }

        XCTAssertEqual(counts.reduce(0, +), HandFrequency.sevenCardTotal)
        XCTAssertEqual(counts, HandFrequency.sevenCardCounts)
        XCTAssertEqual(royal, HandFrequency.royalFlushCount)
    }

    func testSharesSumToOne() {
        let total = (0...8).map(HandFrequency.share(ofCategory:)).reduce(0, +)
        XCTAssertEqual(total, 1, accuracy: 1e-12)
        XCTAssertEqual(HandFrequency.royalFlushShare + HandFrequency.straightFlushWithoutRoyalShare,
                       HandFrequency.share(ofCategory: 8), accuracy: 1e-15)
    }
}
