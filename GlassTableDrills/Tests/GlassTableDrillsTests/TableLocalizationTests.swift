// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class TableLocalizationTests: XCTestCase {
    func testHistoryFactsRenderInEitherLanguageWithoutChangingHand() {
        var hand = TableDealer.deal(baseSeed: 0x5EED, index: 0, villain: .tag)
        let original = hand
        XCTAssertEqual(hand.history, hand.events.map { $0.text(in: .korean) })
        XCTAssertTrue(hand.events[0].text(in: .english).contains("opens to 3bb"))
        XCTAssertEqual(hand, original)

        hand.play(.call)
        XCTAssertTrue(hand.events.contains { $0.actor == .hero && $0.action == .call })
        XCTAssertEqual(hand.history, hand.events.map { $0.text(in: .korean) })
        XCTAssertTrue(hand.events.map { $0.text(in: .english) }.contains { $0.contains("You call") })
    }

    func testGradedOptionAmountDoesNotDependOnKoreanLabel() {
        let option = GradedOption(choice: .call, label: "arbitrary display copy", ev: 1.0, amount: 4.5)
        XCTAssertEqual(option.label(in: .korean), "콜 4.5bb")
        XCTAssertEqual(option.label(in: .english), "Call 4.5bb")
        XCTAssertEqual(option.amount, 4.5)
    }
}
