// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// What a new player sees between full-screen steps: the opening, the basics, the
/// guided-hand invitation, the guided hand, a lesson, and the Play tab.
///
/// A screen can only appear once the one before it has finished leaving, so a step
/// that ends names what comes next and the next step waits in `queued` until the
/// closing screen reports `didDismiss()`. A close with nothing queued opens nothing,
/// which is what swiping a sheet away means.
public struct BeginnerJourney: Equatable, Sendable {
    public enum Step: Equatable, Sendable {
        /// The first lesson, resumed from Learn.
        case opening
        case basics
        /// Offers the guided hand; `lessonAfter` is the lesson "continue" opens.
        case invitation(lessonAfter: CurriculumNode?)
        case guidedHand
        case lesson(CurriculumNode)
        /// Switch to the Play tab. Never presented.
        case play
    }

    public private(set) var presented: Step?
    public private(set) var queued: Step?

    public init() {}

    /// Shows a step now, replacing whatever is shown and anything queued.
    public mutating func present(_ step: Step) {
        precondition(step != .play, "Play is a tab, not a presented step")
        presented = step
        queued = nil
    }

    /// Ends the shown step; `next` opens once it has left the screen.
    public mutating func close(then next: Step? = nil) {
        guard presented != nil else { return }
        presented = nil
        queued = next
    }

    /// For a presentation binding: closes only if `step` is still the one shown, so a
    /// late report from a screen already replaced or closed changes nothing.
    public mutating func close(ifShowing step: Step) {
        if presented == step { close() }
    }

    /// Call when any step's screen has finished leaving. Returns the step that follows;
    /// `.play` is returned but not presented.
    @discardableResult
    public mutating func didDismiss() -> Step? {
        guard presented == nil, let next = queued else { return nil }
        queued = nil
        if next != .play { presented = next }
        return next
    }
}
