import XCTest
@testable import GlassTable

@MainActor
final class AppFeedbackTests: XCTestCase {
    func testPreferencesControlActualFeedbackPolicy() {
        let defaults = UserDefaults.standard
        let oldSound = defaults.object(forKey: AppFeedback.soundKey)
        let oldHaptics = defaults.object(forKey: AppFeedback.hapticsKey)
        defer {
            defaults.set(oldSound, forKey: AppFeedback.soundKey)
            defaults.set(oldHaptics, forKey: AppFeedback.hapticsKey)
        }
        defaults.removeObject(forKey: AppFeedback.soundKey)
        defaults.removeObject(forKey: AppFeedback.hapticsKey)
        XCTAssertFalse(AppFeedback.soundEnabled)
        XCTAssertTrue(AppFeedback.hapticsEnabled)
        defaults.set(true, forKey: AppFeedback.soundKey)
        defaults.set(false, forKey: AppFeedback.hapticsKey)
        XCTAssertTrue(AppFeedback.soundEnabled)
        XCTAssertFalse(AppFeedback.hapticsEnabled)
    }

    func testEverySoundEffectHasPlayableBundledPCM() throws {
        let bundle = Bundle(for: ProgressionModel.self)
        for name in ["answer-confirm", "answer-review", "table-tick"] {
            let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "wav"))
            let data = try Data(contentsOf: url)
            XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "RIFF")
            XCTAssertGreaterThan(data.count, 44)
        }
    }
}
