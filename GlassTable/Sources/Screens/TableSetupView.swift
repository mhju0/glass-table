import SwiftUI
import GlassTableDrills

/// Seats a free table: two to four players, one style per computer chosen in place,
/// then one start button at the bottom. The default seats three easygoing players, so the first table is
/// a friendly one; the published styles are a tap away.
struct TableSetupView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.dismiss) private var dismiss
    let epoch: UUID
    /// Presents the new table. Without it, setup just closes.
    var onStarted: (() -> Void)? = nil
    @State private var styles: [Archetype] = [.casual, .casual, .casual]
    @State private var players = 4
    /// A quick game is short-stacked and ends; a long table plays on.
    @State private var quick = true
    @State private var showGuide = false
    @State private var failure = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(language.text("테이블 만들기", "Set up the table")).font(GT.title(28))
                        Text(language.text("인원과 컴퓨터별 스타일을 골라요. 스타일은 난이도가 아니라 카드를 고르는 습관이에요.",
                                           "Pick the players and each computer's style. A style is a habit, not a difficulty level."))
                            .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                            .lineSpacing(GT.Typography.bodyLineSpacing)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(language.text("인원", "Players")).font(GT.semibold(15))
                        // App choice buttons rather than the system segmented control,
                        // whose grey selection nearly vanished on the dark page.
                        let countLayout = typeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
                        countLayout {
                            ForEach(2...4, id: \.self) { count in
                                GTChoiceButton(title: language.text("\(count)명", "\(count) players"),
                                               selected: players == count, minHeight: 44) {
                                    players = count
                                }
                                .accessibilityAddTraits(players == count ? .isSelected : [])
                                .accessibilityIdentifier("player-count-\(count)")
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("player-count")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(language.text("게임 길이", "Game length")).font(GT.semibold(15))
                        let lengthLayout = typeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
                        lengthLayout {
                            GTChoiceButton(title: language.text("빠른 게임", "Quick game"),
                                           selected: quick, minHeight: 44) { quick = true }
                                .accessibilityAddTraits(quick ? .isSelected : [])
                                .accessibilityIdentifier("game-length-quick")
                            GTChoiceButton(title: language.text("긴 테이블", "Long table"),
                                           selected: !quick, minHeight: 44) { quick = false }
                                .accessibilityAddTraits(!quick ? .isSelected : [])
                                .accessibilityIdentifier("game-length-long")
                        }
                        Text(quick
                             ? language.text("각자 \(Self.quickStack)칩 · \(Self.quickHands)핸드 뒤에 끝나요 · 블라인드 1·2칩",
                                             "\(Self.quickStack) chips each · ends after \(Self.quickHands) hands · blinds 1 and 2")
                             : language.text("각자 100칩 · 끝이 없어요 · 블라인드 1·2칩",
                                             "100 chips each · no ending · blinds 1 and 2"))
                            .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("game-length-detail")
                    }
                    VStack(spacing: 10) {
                        ForEach(0..<(players - 1), id: \.self) { seat in seatRow(seat) }
                    }
                    Button { showGuide = true } label: {
                        TapCardLabel(title: language.text("스타일 자세히 보기", "About the styles"),
                                     detail: language.text("다섯 스타일의 습관을 비교해요.",
                                                           "Compare the habits of all five styles."))
                    }
                    .buttonStyle(GTPress())
                    .accessibilityIdentifier("style-guide")
                }
                .padding(18)
            }
            PrimaryCTAButton(title: language.text("이 테이블로 시작", "Start this table")) { start() }
                .accessibilityIdentifier("table-start")
                .disabled(model.saveError != nil)
                .padding(.horizontal, GT.Space.edge).padding(.top, 10).padding(.bottom, 12)
        }
        .background(FeltBackground())
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showGuide) { StyleGuideView { showGuide = false } }
        .alert(language.text("테이블을 시작하지 못했어요", "Couldn't start the table"), isPresented: $failure) {
            Button(language.text("확인", "OK"), role: .cancel) {}
        }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_OPPONENT"] != nil { showGuide = true }
            #endif
        }
    }

    /// Twenty big blinds and ten hands: about five minutes at the table.
    static let quickStack = 40
    static let quickHands = 10

    private func seatRow(_ seat: Int) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            VStack(alignment: .leading, spacing: 4) {
                Text(FreeTableWords.seatName(seat + 1, language: language)).font(GT.semibold(16))
                Text(styles[seat].beginnerDescription(in: language))
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Menu {
                Picker(language.text("\(FreeTableWords.seatName(seat + 1, language: language)) 스타일",
                                     "\(FreeTableWords.seatName(seat + 1, language: language))'s style"),
                       selection: $styles[seat]) {
                    ForEach([.casual] + Archetype.allCases, id: \.self) { style in
                        Text(style.beginnerTitle(in: language)).tag(style)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(styles[seat].beginnerTitle(in: language)).font(GT.semibold(15))
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(GT.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(GT.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(GT.borderStrong, lineWidth: 1))
            }
            .accessibilityLabel(language.text("\(FreeTableWords.seatName(seat + 1, language: language)) 스타일, \(styles[seat].beginnerTitle(in: language))",
                                              "\(FreeTableWords.seatName(seat + 1, language: language))'s style, \(styles[seat].beginnerTitle(in: language))"))
            .accessibilityIdentifier("seat-style-\(seat + 1)")
        }
        .gtInset(GT.Space.card, firstText: .semibold(16))
        .gtPanel()
    }

    private func start() {
        do {
            if try model.startTable(seed: UInt64.random(in: 0..<UInt64.max),
                                    styles: Array(styles.prefix(players - 1)),
                                    startingStack: quick ? Self.quickStack : nil,
                                    handLimit: quick ? Self.quickHands : nil,
                                    expectedEpoch: epoch) {
                if let onStarted { onStarted() } else { dismiss() }
            } else if model.saveError == nil {
                failure = true
            }
        } catch { failure = true }
    }
}

/// Every style one tap away, for comparing before choosing. Picking stays on the setup
/// screen, so this guide only explains.
private struct StyleGuideView: View {
    @Environment(\.learningLanguage) private var language
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("스타일 자세히 보기", "About the styles")).font(GT.title(28))
                    Text(language.text("실력 순서는 아니에요. 카드를 고르는 습관이 달라요.",
                                       "These aren't difficulty levels. Each picks hands differently."))
                        .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    ForEach(Archetype.allCases, id: \.self) { style in
                        NavigationLink {
                            OpponentDetailView(opponent: style, pushed: true,
                                               onClose: onClose)
                                .gtSheetSurface()
                        } label: {
                            TapCardLabel(title: style.beginnerTitle(in: language),
                                         detail: style.beginnerDescription(in: language))
                        }
                        .buttonStyle(GTPress())
                        .accessibilityIdentifier("opponent-\(style.rawValue)")
                    }
                }
                .gtContentEdge()
            }
            .background(FeltBackground())
            .gtChrome(leading: { ChromeButton.close(onClose) })
            .gtSheetSurface()
            .navigationDestination(isPresented: demoDetail) {
                OpponentDetailView(opponent: demoStyle ?? .tag, pushed: true,
                                   onClose: onClose)
                    .gtSheetSurface()
            }
        }
        .presentationDetents([.large])
    }

    private var demoStyle: Archetype? {
        #if DEBUG
        ProcessInfo.processInfo.environment["GT_DEMO_OPPONENT"].flatMap(Archetype.init(rawValue:))
        #else
        nil
        #endif
    }

    @State private var showDemo = true
    private var demoDetail: Binding<Bool> {
        Binding(get: { demoStyle != nil && showDemo }, set: { showDemo = $0 })
    }
}
