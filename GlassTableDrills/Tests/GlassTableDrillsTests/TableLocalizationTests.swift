// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class TableLocalizationTests: XCTestCase {
    func testHistoryFactsRenderInEitherLanguageWithoutChangingHand() throws {
        var hand = TableDealer.deal(baseSeed: 0x5EED, index: 0, villain: .tag)
        let original = hand
        XCTAssertEqual(hand.history, hand.events.map { $0.text(in: .korean) })
        XCTAssertTrue(hand.events[0].text(in: .english).contains("opens to 3bb"))
        XCTAssertEqual(hand, original)
        let seat = try XCTUnwrap(hand.events[0].position)
        let plain = hand.events[0].text(in: .english, plain: true)
        XCTAssertTrue(plain.contains(seat.rawValue), plain)
        XCTAssertTrue(plain.contains(seat.seatName(in: .english).replacingOccurrences(of: "\n", with: " ")), plain)
        XCTAssertTrue(plain.contains("raises first to 3bb"), plain)
        XCTAssertTrue(plain.contains("(open)"), plain)
        XCTAssertTrue(hand.events[0].text(in: .korean, plain: true).contains("3bb로 먼저 올림"))

        hand.play(.call)
        XCTAssertTrue(hand.events.contains { $0.actor == .hero && $0.action == .call })
        XCTAssertEqual(hand.history, hand.events.map { $0.text(in: .korean) })
        XCTAssertTrue(hand.events.map { $0.text(in: .english) }.contains { $0.contains("You call") })
    }

    func testExplainedThreeBetRetainsTheTermAmountAndSeat() {
        for actor in [TableEvent.Actor.hero, .villain] {
            let event = TableEvent(street: 0, actor: actor, action: .threeBet, amount: 9, position: .co, opponent: .tag)
            let english = event.text(in: .english, plain: true)
            XCTAssertTrue(english.contains("9bb"), english)
            XCTAssertTrue(english.contains("(3-bet)"), english)
            XCTAssertTrue(english.contains("again"), english)
            if actor == .villain { XCTAssertTrue(english.contains("CO"), english) }
            let korean = event.text(in: .korean, plain: true)
            XCTAssertTrue(korean.contains("다시 올림(3벳)"), korean)
        }
    }

    func testGradedOptionAmountDoesNotDependOnKoreanLabel() {
        let option = GradedOption(choice: .call, label: "arbitrary display copy", ev: 1.0, amount: 4.5)
        XCTAssertEqual(option.label(in: .korean), "콜 4.5bb")
        XCTAssertEqual(option.label(in: .english), "Call 4.5bb")
        XCTAssertEqual(option.amount, 4.5)
    }
}
