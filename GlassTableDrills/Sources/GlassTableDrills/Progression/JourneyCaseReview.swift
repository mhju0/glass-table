// Copyright (c) 2026 Michael Ju (github.com/mhju0)

extension JourneyCaseContent {
    static func skill(for activityID: String) -> CourseReviewSkill? {
        switch activityID.suffix(2) {
        case "01": .journeyPosition
        case "02", "03": .journeyRange
        case "04", "05": .journeyPrice
        case "06": .journeyShowdown
        default: nil
        }
    }

    static let review: [CourseReviewSkill: [TableCourseActivity]] = [
        .journeyPosition: [
            early("JR-order-01", .init("", "", "KhTh", "AdAs", "Kc8d3s4s2h", button: true, open: 7, flop: 0, shove: 12, task: .position)),
            early("JR-order-02", .init("", "", "AsJc", "7h7s", "KcJd6d3c2s", button: false, open: 9, flop: 4, shove: 13, task: .match)),
        ],
        .journeyRange: [
            range("JR-range-01", .init("", "", "KcTd", "9s9d", "Qc7h6s4h2d", button: true, open: 7, flop: 0, shove: 12, task: .match)),
            boardChange("JR-range-02", .init("", "", "QcJc", "AsAh", "Js9s2d2s7h", button: false, open: 9, flop: 4, shove: 13, task: .match)),
        ],
        .journeyPrice: [
            price("JR-price-01", .init("", "", "8h7h", "AdAc", "9dTh3h2s6d", button: true, open: 8, flop: 6, shove: 21, task: .match)),
            decision("JR-price-02", .init("", "", "Ah4h", "KsKc", "Th7h2d4c8s", button: false, open: 9, flop: 3, shove: 14, task: .match)),
        ],
        .journeyShowdown: [
            showdown("JR-showdown-01", .init("", "", "KdJh", "KhTc", "Ks9d7h3c2s", button: true, open: 7, flop: 0, shove: 12, task: .match)),
            showdown("JR-showdown-02", .init("", "", "Ad9c", "Tc4s", "AhKcQdJdTs", button: false, open: 9, flop: 4, shove: 13, task: .match)),
        ],
    ]
}
