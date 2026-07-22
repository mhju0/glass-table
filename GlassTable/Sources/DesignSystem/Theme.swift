// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

/// Toss-inspired tokens. Green content zone + white action sheet, borderless.
enum GT {
    static let green         = Color(hex: 0x157A47)
    static let cta           = Color(hex: 0x0FA968)
    static let ink           = Color(hex: 0x191F28)
    static let inkSecondary  = Color(hex: 0x4E5968)
    static let inkMuted      = Color(hex: 0x8B95A1)
    static let surface       = Color(hex: 0xF2F4F6)
    static let suitRed       = Color(hex: 0xE5484D)

    static func title(_ s: CGFloat) -> Font    { .custom("Pretendard-Bold", size: s) }
    static func semibold(_ s: CGFloat) -> Font { .custom("Pretendard-SemiBold", size: s) }
    static func body(_ s: CGFloat) -> Font     { .custom("Pretendard-Regular", size: s) }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8)  & 0xff) / 255,
                  blue:  Double( hex        & 0xff) / 255)
    }
}
