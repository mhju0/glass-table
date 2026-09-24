// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

extension Text {
    /// Draws every `Text(someString)` through `KO.wordJoined`, so a line never breaks
    /// inside "100핸드" or "9%를".
    ///
    /// Like SwiftUI's own `StringProtocol` initializer this is disfavoured, so string
    /// literals still use the localized `LocalizedStringKey` initializer; among the
    /// disfavoured pair, `String` is more specific and wins. VoiceOver and UI tests read
    /// the original string, without the invisible joiner.
    @_disfavoredOverload
    init(_ content: String) {
        let joined = KO.wordJoined(content)
        self = joined == content ? Text(verbatim: content) : Text(verbatim: joined).accessibilityLabel(content)
    }
}
