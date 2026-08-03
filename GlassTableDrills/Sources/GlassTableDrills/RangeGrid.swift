// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Where each of the 169 classes sits in the 13×13 grid.
///
/// The convention is universal (`decisions.md` §B) and getting it backwards is both
/// easy and invisible until someone compares against another tool: **pairs on the
/// diagonal AA→22, suited ABOVE it (upper-right), offsuit BELOW (lower-left)**.
///
/// Rows and columns both run A→2. A cell above the diagonal has a column rank lower
/// than its row rank, so `suited` is `row > col` — the first draft had that inverted
/// and put every suited hand in the wrong triangle.
public enum RangeGrid {
    /// A first, matching how every chart is printed.
    public static let ranks: [Int] = Array((2...14).reversed())

    public static func classAt(row: Int, col: Int) -> HandClass {
        HandClass(high: max(row, col), low: min(row, col), suited: row > col)
            ?? HandClass(high: row, low: row, suited: false)!
    }
}
