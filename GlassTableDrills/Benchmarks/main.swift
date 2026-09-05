import Foundation
import GlassTableEngine
import GlassTableDrills

// Run with: swift run -c release --package-path GlassTableDrills DrillBenchmarks
// --snapshot emits deterministic results for before/after comparisons. Timings
// are medians of five warmed batches, not CI thresholds tied to a particular Mac.
let tendencies = RangeTendency.allCases
let rivers: [TableHand] = Archetype.allCases.flatMap { archetype in
    (0..<8).compactMap { index -> TableHand? in
        var hand = TableDealer.deal(baseSeed: 9, index: index, villain: archetype)
        while hand.street < 5 {
            guard case let .hero(facing) = hand.phase else { return nil }
            if case .checkedTo = facing { hand.play(.check) }
            else { hand.play(.call) }
        }
        guard case .hero = hand.phase else { return nil }
        return hand
    }
}
precondition(!rivers.isEmpty)

if CommandLine.arguments.dropFirst() == ["--snapshot"] {
    var ranges: [[String]] = []
    for mask in 0..<(1 << tendencies.count) {
        let selected = Set(tendencies.enumerated().compactMap { index, t in
            mask & (1 << index) != 0 ? t : nil
        })
        for width in 0...100 {
            ranges.append(HandRange.shaped(width: Double(width), tendencies: selected)
                .classes.map(\.description))
        }
    }
    let result: [String: Any] = [
        "ranges": ranges,
        "riverEVs": rivers.map { $0.gradedOptions().map(\.ev) },
    ]
    let data = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
    FileHandle.standardOutput.write(data)
} else {
    guard CommandLine.arguments.count == 1 else {
        fatalError("usage: DrillBenchmarks [--snapshot]")
    }
    func measure(_ name: String, iterations: Int, _ work: (Int) -> Double) {
        var checksum = work(0)
        var samples: [Double] = []
        for _ in 0..<5 {
            let start = DispatchTime.now().uptimeNanoseconds
            for i in 0..<iterations { checksum += work(i) }
            let elapsed = DispatchTime.now().uptimeNanoseconds - start
            samples.append(Double(elapsed) / Double(iterations) / 1_000)
        }
        print(String(format: "%@: %.2f µs/op (checksum %.6f)",
                     name, samples.sorted()[2], checksum))
    }
    measure("range/plain", iterations: 2_000) { i in
        HandRange.shaped(width: Double(i % 100)).comboCount
    }
    measure("range/shaped", iterations: 2_000) { i in
        HandRange.shaped(width: Double(i % 100), tendencies: [.suited, .connectors]).comboCount
    }
    measure("table/river-options", iterations: 100) { i in
        rivers[i % rivers.count].gradedOptions().reduce(0) { $0 + $1.ev }
    }
}
