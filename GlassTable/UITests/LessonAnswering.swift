// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

extension XCUIApplication {
    /// Below the top level a lesson question is answered with one tap on a choice;
    /// there is no separate Check button.
    var firstLessonChoice: XCUIElement {
        buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@ OR identifier BEGINSWITH %@",
            "lesson-choice-", "lesson-estimate-choice-")).firstMatch
    }
}
