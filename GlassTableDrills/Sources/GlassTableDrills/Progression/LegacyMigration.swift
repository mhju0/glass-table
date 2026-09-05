// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// One-time fold-in of the five M1 `<drill>-progress.json` files (spec §8.3).
///
/// Old files are read and retained for recovery. The current app never writes them.
public enum LegacyMigration {
    /// Keys are the drill slugs shipped in M1.
    /// `blockers` → `combos` is the rename from spec §3.2: the drill was always
    /// combinatorics, so its history belongs to 콤보.
    private static let drillKeyToConcept: [String: Concept] = [
        "outs": .outs,
        "potodds": .potOdds,
        "callfold": .callFold,
        "mdf": .mdf,
        "blockers": .combos,
    ]

    public static func migrate(from directory: URL, into state: ProgressState) -> ProgressState {
        var out = state
        var bestStreak = 0

        // Sorted so the migration is deterministic regardless of dictionary order.
        for (key, concept) in drillKeyToConcept.sorted(by: { $0.key < $1.key }) {
            let url = directory.appendingPathComponent("\(key)-progress.json")
            guard let data = try? Data(contentsOf: url),
                  let legacy = try? JSONDecoder().decode(LegacyProgress.self, from: data),
                  legacy.total > 0                       // never played → nothing to carry
            else { continue }
            bestStreak = max(bestStreak, legacy.streak)
            // Never clobber state the app has already written for this concept.
            guard out.concepts[concept.rawValue] == nil else { continue }
            out.updateRecord(for: concept) {
                $0.correct = legacy.correct
                $0.total = legacy.total
                // Accuracy maps onto the two *earnable-by-drilling* tiers only.
                // 능숙 needs a clean run and 숙달 needs a boss node (spec §4.3), and
                // neither can be inferred from a bare correct/total pair.
                $0.tier = Double(legacy.correct) / Double(legacy.total) >= 0.7 ? .familiar : .attempted
            }
        }

        out.streak.longest = max(out.streak.longest, bestStreak)
        return out
    }

    /// The historical wire format, kept only for decoding existing installations.
    private struct LegacyProgress: Decodable {
        let streak: Int
        let correct: Int
        let total: Int
    }
}
