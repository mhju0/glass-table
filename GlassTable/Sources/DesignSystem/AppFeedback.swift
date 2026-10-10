import SwiftUI
import UIKit
import AudioToolbox

/// Effects are local and optional; notification sound is controlled separately by iOS.
@MainActor
enum AppFeedback {
    static let soundKey = "glassTable.soundEffects"
    static let hapticsKey = "glassTable.hapticFeedback"
    static var hapticsEnabled: Bool {
        UserDefaults.standard.object(forKey: hapticsKey) as? Bool ?? true
    }
    static var soundEnabled: Bool { UserDefaults.standard.bool(forKey: soundKey) }
    private static var sounds: [String: SystemSoundID] = [:]

    static func answer(correct: Bool) {
        if hapticsEnabled {
            if correct {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UISelectionFeedbackGenerator().selectionChanged()
            }
        }
        play(correct ? "answer-confirm" : "answer-review")
    }

    static func table(kind: TableFeedbackKind) {
        switch kind {
        case .won: play("answer-confirm")
        case .commit, .yourTurn: play("table-tick")
        default: break
        }
    }

    private static func play(_ name: String) {
        guard soundEnabled else { return }
        if let sound = sounds[name] { AudioServicesPlaySystemSound(sound); return }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        var sound: SystemSoundID = 0
        guard AudioServicesCreateSystemSoundID(url as CFURL, &sound) == kAudioServicesNoError else { return }
        sounds[name] = sound
        AudioServicesPlaySystemSound(sound)
    }
}
