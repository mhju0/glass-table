// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// Only unsaved guides rotate; persisted sessions always use their recorded seed.
enum GuideExampleRotation {
    static func next(_ guide: String) -> UInt64 {
        var key = "glassTable.guideRotation." + guide
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["GT_DEMO_FIRST_LESSON"] != nil { return 0 }
        if let storeID = environment["GT_TEST_STORE_ID"] { key += "." + storeID }
        #endif
        let value = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(value == Int.max ? 0 : value + 1, forKey: key)
        return UInt64(max(0, value))
    }
}
