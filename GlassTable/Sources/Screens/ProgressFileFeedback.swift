// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Attach to the root and session sheets so a failed answer save stays visible
/// where the user is practicing, without dismissing their current question.
struct ProgressSaveNotice: ViewModifier {
    @Environment(ProgressionModel.self) private var model

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            if model.saveError != nil {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("기록을 저장하지 못했어요", systemImage: "exclamationmark.triangle")
                            .font(GT.semibold(13))
                        Spacer(minLength: 8)
                        Button("다시 저장") { model.retrySave() }
                            .font(GT.semibold(13))
                            .frame(minHeight: 44)
                    }
                    Text("최근 진행이 아직 저장되지 않았어요. 앱을 닫기 전에 다시 저장하거나 설정에서 백업을 만들어 주세요.")
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

    static let read = Self(message: "파일을 읽지 못했어요. 파일에 접근할 수 있는지 확인한 뒤 다시 시도해 주세요.")
    static let export = Self(message: "백업 파일을 저장하지 못했어요. 저장 공간과 저장 위치를 확인한 뒤 다시 시도해 주세요.")
    static let reset = Self(message: "기존 기록을 보관하거나 새 기록을 저장하지 못해 초기화하지 않았어요. 저장 공간을 확인한 뒤 다시 시도해 주세요.")

    static func importing(_ error: Error) -> Self {
        switch error as? StoreError {
        case .notDecodable:
            return Self(message: "Glass Table의 백업 만들기로 저장한 JSON 파일인지 확인해 주세요. 현재 기록은 바뀌지 않았어요.")
        case .unsupportedSchemaVersion:
            return Self(message: "더 새로운 버전에서 만든 백업이에요. 앱을 업데이트한 뒤 다시 불러와 주세요. 현재 기록은 바뀌지 않았어요.")
        case nil:
            return Self(message: "백업을 저장하지 못해 기록을 바꾸지 않았어요. 저장 공간을 확인한 뒤 다시 시도해 주세요.")
        }
    }
}
