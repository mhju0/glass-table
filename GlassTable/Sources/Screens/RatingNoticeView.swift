// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// GRAC's launch-screen notice for App Store Korea: descriptor and rating marks in the
/// top right, the 19+ warning in the middle, on white in every appearance (D59).
struct RatingLaunchNotice: View {
    @Environment(\.learningLanguage) private var language

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Spacer(minLength: 0)
                    RatingMarks(markWidth: max(64, proxy.size.width * 0.2))
                }
                Spacer(minLength: 24)
                ViewThatFits(in: .vertical) {
                    message(withNote: true)
                    message(withNote: false)
                }
                Spacer(minLength: 24)
                Text("Glass Table").font(GT.title(17)).foregroundStyle(Color.black.opacity(0.75))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 24).padding(.vertical, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white.ignoresSafeArea())
        .environment(\.colorScheme, .light)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(KoreanRating.warning(in: language))
        .accessibilityIdentifier("rating-notice")
        .accessibilityAddTraits(.isModal)
    }

    private func message(withNote: Bool) -> some View {
        VStack(spacing: 16) {
            // Broken by meaning so no word is left alone on a line, down to the SE's width.
            // GRAC recommends the warning span at least half the screen width.
            Text(language.text("이 게임물은\n청소년이용불가 게임물로\n19세 미만의 청소년은\n이용할 수 없습니다.",
                               "This game is rated 19.\nThose under 19 years old\nare prohibited\nfrom playing."))
                .font(GT.title(26)).foregroundStyle(Color.black)
            if withNote {
                Text(language.text("베팅과 배당을 모사하는\n홀덤 연습이 포함되어 있습니다.\n실제 돈이나 경품은 걸지 않습니다.",
                                   KoreanRating.descriptorNote(in: language)))
                    .font(GT.body(16)).foregroundStyle(Color.black.opacity(0.7))
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// The official GRAC marks: content descriptor first, then the rating, as in GRAC's example.
private struct RatingMarks: View {
    @Environment(\.learningLanguage) private var language
    let markWidth: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image("descriptor-gambling").resizable().scaledToFit()
                .frame(width: markWidth * 99 / 113)
                .accessibilityLabel(language.text("내용정보: 사행성", "Content: gambling"))
            Image("rating-19").resizable().scaledToFit()
                .frame(width: markWidth)
                .accessibilityLabel(language.text("청소년이용불가", "Rated 19"))
        }
    }
}

/// GRAC's trade-name and production table, shown from Settings to App Store Korea users.
struct RatingInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.learningLanguage) private var language

    private var rows: [(String, String)] {
        [(language.text("제명", "Title"), "Glass Table"),
         (language.text("상호", "Trade name"), "-"),
         (language.text("이용등급", "Rating"), language.text("청소년이용불가", "Rated 19")),
         (language.text("등급분류번호", "Rating number"), KoreanRating.classificationNumber),
         (language.text("등급분류일자", "Rating date"), KoreanRating.decisionDate),
         (language.text("제작·배급업 등록(신고)번호", "Producer registration number"), "-"),
         (language.text("내용정보", "Content"), language.text("사행성", "Gambling"))]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(language.text("등급 정보", "Rating information"))
                    .font(GT.title(26)).foregroundStyle(Color.black)
                Text(language.text("게임물관리위원회 등급분류 결과", "Game Rating and Administration Committee (GRAC)"))
                    .font(GT.body(15)).foregroundStyle(Color.black.opacity(0.7))
                RatingMarks(markWidth: 72).frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 0) {
                    ForEach(rows, id: \.0) { row in
                        HStack(alignment: .top, spacing: 0) {
                            Text(row.0).font(GT.semibold(14)).foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10).background(Self.red)
                            Text(row.1).font(GT.body(14)).foregroundStyle(Color.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .overlay(Rectangle().stroke(Self.red.opacity(0.6), lineWidth: 1))
                        .accessibilityElement(children: .combine)
                    }
                }
                .accessibilityIdentifier("rating-table")
                Text(KoreanRating.warning(in: language))
                    .font(GT.body(14)).foregroundStyle(Color.black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .background(Color.white.ignoresSafeArea())
        .environment(\.colorScheme, .light)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(language.text("닫기", "Close")) { dismiss() }
            }
        }
    }

    /// GRAC's 청소년이용불가 red (#A31639).
    private static let red = Color(red: 163 / 255, green: 22 / 255, blue: 57 / 255)
}
