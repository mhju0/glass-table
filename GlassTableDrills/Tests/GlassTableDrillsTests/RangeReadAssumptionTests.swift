import XCTest
@testable import GlassTableDrills

final class RangeReadAssumptionTests: XCTestCase {
    func testAnIdenticalCallNeedsItsDeclaredOpponentModel() {
        let action = RangeReadSpot.Action.called(seat: .co, opener: .utg)
        let nit = RangeReadSpot(archetype: .nit, action: action, archetypeShown: false)
        let station = RangeReadSpot(archetype: .station, action: action, archetypeShown: false)
        XCTAssertEqual(nit.actionLines, station.actionLines)
        XCTAssertGreaterThan(station.trueRange.percent - nit.trueRange.percent, 25)
        for language in [LearningLanguage.korean, .english] {
            XCTAssertNotEqual(nit.gradingAssumption(in: language), station.gradingAssumption(in: language))
            for spot in [nit, station] {
                XCTAssertTrue(spot.gradingAssumption(in: language).contains(spot.archetype.beginnerTitle(in: language)))
                for level in [DrillLevel.learn, .apply, .sharp] {
                    let choices = RangeReadChoices.estimates(spot: spot, seed: 7, level: level)
                    XCTAssertEqual(choices.filter { gradeRangeRead(estimate: $0, spot: spot).band == .spotOn }.count, 1)
                }
            }
        }
    }
}
