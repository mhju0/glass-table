import XCTest
@testable import GlassTableDrills

/// Save-integrity plan step 2: how long one save takes once the unbounded parts of the
/// file (daily summaries, processed attempt IDs) have grown for years. Prints numbers
/// only; timing assertions would be flaky on shared runners. Runs only with
/// GT_MEASURE_SAVE set: `GT_MEASURE_SAVE=1 swift test -c release --package-path
/// GlassTableDrills --filter SaveLatencyMeasurementTests`.
final class SaveLatencyMeasurementTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: dir) }

    func testSaveAndLoadTimeWithYearsOfHistory() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["GT_MEASURE_SAVE"] == nil,
                      "set GT_MEASURE_SAVE to measure")
        let url = try XCTUnwrap(Bundle.module.url(forResource: "schema4-build35", withExtension: "json",
                                                  subdirectory: "Fixtures/Progression"))
        let store = ProgressionStore(url: dir.appendingPathComponent("progress.json"))
        try Data(contentsOf: url).write(to: store.url)
        guard case let .loaded(base) = store.load() else { return XCTFail("fixture must load") }

        // (days, summaries a day, graded answers a day)
        for (days, perDay, answersPerDay) in [(365, 10, 40), (365 * 3, 20, 60), (365 * 5, 30, 100)] {
            var state = base
            let start = Date(timeIntervalSince1970: 1_262_304_000)  // 2010, before any fixture date
            let concepts = Concept.allCases.map(\.rawValue)
            for d in 0..<days {
                let day = DayKey(start.addingTimeInterval(Double(d) * 86_400))
                for k in 0..<perDay {
                    var s = DailyPracticeSummary(key: DailyPracticeKey(
                        day: day, concept: concepts[k % concepts.count],
                        mode: (k / concepts.count / 3) % 2 == 0 ? "round" : "node",
                        formatVersion: 1, language: "ko", assisted: false,
                        level: [nil, 2, 3][(k / concepts.count) % 3]))
                    s.exact = 3; s.near = 1; s.miss = 1
                    s.eligibleCorrectSeconds = 12.5; s.eligibleCorrectCount = 3
                    state.dailySummaries.append(s)
                }
            }
            for _ in 0..<(days * answersPerDay) { state.processedAttemptIDs.insert(UUID().uuidString) }

            var saves: [Double] = []
            var loads: [Double] = []
            for _ in 0..<5 {
                var t = CFAbsoluteTimeGetCurrent()
                try store.save(state)
                saves.append(CFAbsoluteTimeGetCurrent() - t)
                t = CFAbsoluteTimeGetCurrent()
                guard case .loaded = store.load() else { return XCTFail("\(days) days must load") }
                loads.append(CFAbsoluteTimeGetCurrent() - t)
            }
            let bytes = try Data(contentsOf: store.url).count
            XCTAssertLessThan(bytes, ProgressionStore.maximumFileBytes)
            print(String(format: "save-latency days=%d summaries=%d attemptIDs=%d bytes=%d save_ms=%.0f load_ms=%.0f",
                         days, state.dailySummaries.count, state.processedAttemptIDs.count, bytes,
                         saves.sorted()[2] * 1000, loads.sorted()[2] * 1000))
        }
    }
}
