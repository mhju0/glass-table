import SwiftUI
import GlassTableDrills
import Darwin

@main
struct CapacityProbeApp: App {
    @State private var result = "Testing synthetic progress. Your Glass Table data is not used."
    var body: some Scene {
        WindowGroup {
            ScrollView { Text(result).font(.system(.body, design: .monospaced)).padding() }
                .task {
                    do {
                        let report = try await Task.detached { try CapacityProbe.run() }.value
                        result = report
                    } catch { result = "FAILED: \(error)" }
                    print(result)
                }
        }
    }
}

enum CapacityProbe {
    static func run() throws -> String {
        let megabytes = Int(ProcessInfo.processInfo.environment["GT_PROBE_MIB"] ?? "8") ?? 8
        precondition([8, 48].contains(megabytes))
        let target = megabytes * 1024 * 1024
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let store = ProgressionStore(url: directory.appendingPathComponent("synthetic-progress.json"))
        var state = ProgressState()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let base = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        let concepts = Concept.allCases
        var bytes = Data()
        var index = 0
        let reuse = ProcessInfo.processInfo.environment["GT_PROBE_REUSE"] == "1"
        if reuse {
            bytes = try ProgressionStore.readImportData(at: store.url)
        } else { repeat {
            for _ in 0..<2000 {
                let concept = concepts[index % concepts.count]
                let variant = index / concepts.count
                let day = DayKey(calendar.date(byAdding: .day, value: variant / 8, to: base)!, calendar: calendar)
                let key = DailyPracticeKey(day: day, concept: concept.rawValue,
                    mode: variant % 2 == 0 ? "practice" : "lesson", formatVersion: 1,
                    language: (variant / 2) % 2 == 0 ? "ko" : "en", assisted: (variant / 4) % 2 == 1)
                var summary = DailyPracticeSummary(key: key)
                summary.exact = 10; summary.near = 3; summary.miss = 2
                if !key.assisted {
                    summary.eligibleCorrectCount = 10
                    summary.eligibleCorrectSeconds = 43
                }
                state.dailySummaries.append(summary)
                index += 1
            }
            bytes = try JSONEncoder().encode(state)
        } while bytes.count < target }
        state = ProgressState()
        let baseline = footprint()
        let start = ContinuousClock.now
        let decoded = try store.importData(bytes)
        let decodeSeconds = seconds(start.duration(to: .now))
        let decodedFootprint = footprint()
        let saveStart = ContinuousClock.now
        try store.save(decoded)
        let saveSeconds = seconds(saveStart.duration(to: .now))
        let loadStart = ContinuousClock.now
        guard case let .loaded(reloaded) = store.load(),
              reloaded == decoded else {
            throw StoreError.invalidProgress
        }
        let loadSeconds = seconds(loadStart.duration(to: .now))
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        let report: [String: Any] = [
            "fixtureBytes": bytes.count, "summaryRows": decoded.dailySummaries.count,
            "reusedPreparedFixture": reuse,
            "decodeSeconds": decodeSeconds, "atomicSaveSeconds": saveSeconds,
            "reloadSeconds": loadSeconds, "baselineFootprintBytes": baseline,
            "decodedFootprintBytes": decodedFootprint, "peakResidentBytes": usage.ru_maxrss,
            "roundTripEqual": true, "system": ProcessInfo.processInfo.operatingSystemVersionString
        ]
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: directory.appendingPathComponent("capacity-\(megabytes).json"), options: .atomic)
        return String(decoding: data, as: UTF8.self)
    }

    private static func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }

    private static func footprint() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return status == KERN_SUCCESS ? info.phys_footprint : 0
    }
}
