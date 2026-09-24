// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Attach to the root and session sheets so a failed answer save stays visible
/// where the user is practicing, without dismissing their current question.
struct ProgressSaveNotice: ViewModifier {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            if model.saveError != nil {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label(language.text("기록을 저장하지 못했어요", "Progress was not saved"),
                              systemImage: "exclamationmark.triangle")
                            .font(GT.semibold(13))
                        Spacer(minLength: 8)
                        Button { model.retrySave() } label: {
                            Text(language.text("다시 저장", "Retry save"))
                                .font(GT.semibold(13))
                                .padding(.horizontal, 12).frame(minHeight: 44)
                                .background(GT.surface, in: Capsule())
                                .overlay(Capsule().strokeBorder(GT.borderStrong, lineWidth: 1))
                        }
                        .buttonStyle(GTPress())
                    }
                    Text(language.text(
                        "최근 진행이 아직 저장되지 않았어요. 앱을 닫기 전에 다시 저장하거나 설정에서 백업을 만들어 주세요.",
                        "Recent progress is still unsaved. Retry before closing the app, or export a backup in Settings."))
                        .font(GT.body(12))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(GT.ink)
                .padding(.horizontal, 18).padding(.bottom, 12)
                .background(GT.glass)
            }
        }
    }
}

struct ProgressFileFailure: Identifiable {
    let id = UUID()
    let message: String
    let englishMessage: String

    func message(in language: LearningLanguage) -> String {
        language.text(message, englishMessage)
    }

    static let read = Self(
        message: "파일을 읽지 못했어요. 파일에 접근할 수 있는지 확인한 뒤 다시 시도해 주세요.",
        englishMessage: "The file could not be read. Check access to it and try again.")
    static let export = Self(
        message: "백업 파일을 저장하지 못했어요. 저장 공간과 저장 위치를 확인한 뒤 다시 시도해 주세요.",
        englishMessage: "The backup could not be saved. Check storage space and the destination, then retry.")
    static let reset = Self(
        message: "기존 기록을 보관하거나 새 기록을 저장하지 못해 초기화하지 않았어요. 저장 공간을 확인한 뒤 다시 시도해 주세요.",
        englishMessage: "Progress was not reset because the old record could not be preserved or the new record could not be saved. Check storage space and retry.")

    static func isCancellation(_ error: Error) -> Bool {
        let cocoa = error as NSError
        return error is CancellationError
            || (cocoa.domain == NSCocoaErrorDomain && cocoa.code == NSUserCancelledError)
    }

    static func importing(_ error: Error) -> Self {
        if case .staleImport = error as? ProgressCommandError {
            return Self(message: "백업을 확인하는 동안 기록이 바뀌었어요. 현재 기록은 그대로 두었어요. 파일을 다시 선택해 주세요.",
                        englishMessage: "Progress changed while the backup was being checked. Nothing was replaced. Select the file again.")
        }
        switch error as? StoreError {
        case .notDecodable:
            return Self(message: "Glass Table의 백업 만들기로 저장한 JSON 파일인지 확인해 주세요. 현재 기록은 바뀌지 않았어요.",
                        englishMessage: "Choose a JSON file exported by Glass Table. Your current progress has not changed.")
        case .unsupportedSchemaVersion:
            return Self(message: "더 새로운 버전에서 만든 백업이에요. 앱을 업데이트한 뒤 다시 불러와 주세요. 현재 기록은 바뀌지 않았어요.",
                        englishMessage: "This backup comes from a newer app version. Update the app before importing it. Your current progress has not changed.")
        case .invalidProgress:
            return Self(message: "백업 안의 기록 값이 올바르지 않아요. 다른 백업을 선택해 주세요. 현재 기록은 바뀌지 않았어요.",
                        englishMessage: "The backup contains invalid progress values. Choose another backup. Your current progress has not changed.")
        case let .fileTooLarge(maximumBytes):
            return Self(message: "백업 파일이 너무 커요. Glass Table 백업은 \(maximumBytes / 1_048_576)MB 이하여야 해요. 현재 기록은 바뀌지 않았어요.",
                        englishMessage: "The backup exceeds \(maximumBytes / 1_048_576) MB. Your current progress has not changed.")
        case nil:
            return Self(message: "백업을 저장하지 못해 기록을 바꾸지 않았어요. 저장 공간을 확인한 뒤 다시 시도해 주세요.",
                        englishMessage: "The backup could not be saved, so progress was not replaced. Check storage space and try again.")
        }
    }
}
