// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit

/// Haptics for the free table. Each fires on the frame its cause appears: a chip moving,
/// a card landing, the turn arriving. Nothing buzzes twice for one event.
@MainActor enum TableHaptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() { light.prepare(); medium.prepare(); selection.prepare() }
    /// The learner's own button.
    static func commit() { medium.impactOccurred(intensity: 0.8) }
    /// A computer puts chips in.
    static func chips() { light.impactOccurred() }
    /// A computer checks or folds: something happened, no chips moved.
    static func pass() { selection.selectionChanged() }
    static func deal() { soft.impactOccurred(intensity: 0.6) }
    /// The turn comes back to the learner.
    static func yourTurn() { medium.impactOccurred() }
    static func won() { notification.notificationOccurred(.success) }
}
