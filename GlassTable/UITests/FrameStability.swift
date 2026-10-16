// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

extension XCUIElement {
    /// Waits until the frame reads the same on two polls in a row, so a measurement or
    /// tap never lands while a scroll is still decelerating.
    func waitForStableFrame(timeout: TimeInterval = 3) {
        var last = frame
        var stableReads = 0
        let deadline = Date().addingTimeInterval(timeout)
        while stableReads < 2, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
            let now = frame
            let same = abs(now.minX - last.minX) < 0.5 && abs(now.minY - last.minY) < 0.5
                && abs(now.width - last.width) < 0.5 && abs(now.height - last.height) < 0.5
            stableReads = same ? stableReads + 1 : 0
            last = now
        }
    }
}

extension XCUICoordinate {
    /// A press-drag-hold that moves content by `offset` without a fling, so the travel is
    /// the drag distance rather than whatever momentum the runner's timing produces.
    func slowDrag(by offset: CGVector) {
        press(forDuration: 0.1, thenDragTo: withOffset(offset), withVelocity: .slow, thenHoldForDuration: 0.3)
    }
}
