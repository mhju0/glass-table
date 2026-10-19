import XCTest
import GlassTableDrills
@testable import GlassTable

@MainActor
final class LearningReferenceContentTests: XCTestCase {
    func testBilingualAliasesResolveToStableEntries() {
        XCTAssertEqual(GlossaryCatalog.entry(for: "에 퀴 티")?.id, "equity")
        XCTAssertEqual(GlossaryCatalog.entry(for: "EQUITY")?.id, "equity")
        XCTAssertEqual(GlossaryCatalog.entry(for: "3bet")?.id, "three-bet")
        XCTAssertEqual(GlossaryCatalog.entry(for: "3-BET")?.id, "three-bet")
        XCTAssertEqual(GlossaryCatalog.entry(for: "다시 올리기")?.id, "three-bet")
        XCTAssertEqual(GlossaryCatalog.entry(for: "EV")?.id, "ev")
        XCTAssertEqual(GlossaryCatalog.entry(for: "expected value")?.id, "ev")
        XCTAssertEqual(GlossaryCatalog.entry(for: "첸 점수")?.id, "chen-score")
        XCTAssertEqual(GlossaryCatalog.entry(for: "BB")?.id, "big-blind")
        XCTAssertEqual(GlossaryCatalog.entry(for: "diamonds")?.id, "suits")
        XCTAssertEqual(GlossaryCatalog.entry(for: "스페이드")?.id, "suits")
        XCTAssertNil(GlossaryCatalog.entry(for: "an unknown term"))
    }

    func testSearchHandlesPartialNamesSpacingAndEmptyResults() {
        XCTAssertTrue(GlossaryCatalog.search("필요에").contains { $0.id == "required-equity" })
        XCTAssertTrue(GlossaryCatalog.search("potodds").contains { $0.id == "pot-odds" })
        XCTAssertTrue(GlossaryCatalog.search("vPiP").contains { $0.id == "vpip" })
        XCTAssertTrue(GlossaryCatalog.search("3 bet").contains { $0.id == "three-bet" })
        XCTAssertEqual(GlossaryCatalog.search(" \n "), GlossaryCatalog.entries)
        XCTAssertTrue(GlossaryCatalog.search("not-a-poker-term-987").isEmpty)
        XCTAssertTrue(GlossaryCatalog.search("?!").isEmpty)
    }

    func testEveryVisibleSeatCodeResolvesAndIsSearchable() throws {
        for seat in Position.allCases {
            let entry = try XCTUnwrap(GlossaryCatalog.entry(for: seat.rawValue), seat.rawValue)
            XCTAssertTrue(GlossaryCatalog.search(seat.rawValue).contains(entry), seat.rawValue)
        }
        for alias in ["LJ", "lojack", "UTG+1", "UTG1", "under-the-gun+1"] {
            XCTAssertEqual(GlossaryCatalog.entry(for: alias)?.id, "position", alias)
            XCTAssertTrue(GlossaryCatalog.search(alias).contains { $0.id == "position" }, alias)
        }
    }

    func testEveryContextualAndGuideLinkResolvesWithoutDependingOnLanguage() throws {
        XCTAssertEqual(Set(GlossaryCatalog.entries.map(\.id)).count, GlossaryCatalog.entries.count)
        for concept in Concept.allCases {
            let target = try XCTUnwrap(ConceptDrillView.glossaryTerm(for: concept), "Missing lookup for \(concept)")
            let entry = try XCTUnwrap(GlossaryCatalog.entry(for: target), "Unknown lookup: \(target)")
            XCTAssertEqual(GlossaryCatalog.entry(for: entry.id), entry)
            XCTAssertEqual(GlossaryView.displayName(for: entry.id, language: .korean), entry.name.korean)
            XCTAssertEqual(GlossaryView.displayName(for: entry.id, language: .english), entry.name.english)
        }
        for topic in LearningGuideContent.topics {
            for target in topic.termIDs {
                XCTAssertNotNil(GlossaryCatalog.entry(for: target), "Broken guide link: \(topic.id)/\(target)")
            }
        }
    }
}
