import XCTest
@testable import GlassTableEngine

final class DrillTests: XCTestCase {
    func testEstimateBands() {
        // equity estimate: spot-on within 2%, close within 5%.
        XCTAssertEqual(gradeEstimate(user: 31, correct: 30, closeWithin: 5, spotOnWithin: 2), .spotOn)
        XCTAssertEqual(gradeEstimate(user: 34, correct: 30, closeWithin: 5, spotOnWithin: 2), .close)
        XCTAssertEqual(gradeEstimate(user: 42, correct: 30, closeWithin: 5, spotOnWithin: 2), .off)
    }

    func testBinaryGrade() {
        XCTAssertEqual(gradeBinary(userChose: true, correct: true), .spotOn)
        XCTAssertEqual(gradeBinary(userChose: false, correct: true), .off)
    }
}
