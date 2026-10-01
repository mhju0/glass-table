import SwiftUI
import GlassTableDrills
import GlassTableEngine

struct PlayView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    @State private var failure = false
    @State private var epoch: UUID?
    @State private var showSetup = false
    @State private var showGraded = false
    @State private var showTable = false
    /// A table just dealt from setup replays its blinds and the computers' first moves.
    @State private var replayFromStart = false
    /// Leaving a finished table lands on setup, not back here.
    @State private var setupAfterTable = false

    var body: some View {
        Group {
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_TABLE"] != nil { TableView() }
            else if ProcessInfo.processInfo.environment["GT_DEMO_PLAY_SETUP"] != nil {
                TableSetupView(epoch: model.epoch)
            }
            else { playContent }
            #else
            playContent
            #endif
        }
    }

    private var playContent: some View {
        GeometryReader { viewport in
            ScrollView {
                // The screen's midline falls in the gap between the two choices.
                // Content is padded 18 inside a viewport that starts below the top
                // safe area, so the midline is converted into this layout's space.
                let screenHeight = viewport.safeAreaInsets.top + viewport.size.height
                    + viewport.safeAreaInsets.bottom
                MidlineSplitLayout(splitY: screenHeight / 2 - viewport.safeAreaInsets.top - 18,
                                   spacing: 22, gap: 12) {
                    playTitle
                    Text(language.text("컴퓨터와 한 판씩 연습해요.",
                                       "Practice against computers."))
                        .font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
                    freeCard
                    gradedCard
                }
                .padding(18)
                .frame(minHeight: viewport.size.height, alignment: .top)
            }
        }
        .background(FeltBackground())
        // Page ground behind the status bar, so nothing scrolls under the clock bare.
        .safeAreaInset(edge: .top, spacing: 0) {
            GT.felt.frame(height: 0).ignoresSafeArea(edges: .top)
        }
        .gtTabBarClearance()
        .navigationDestination(isPresented: $showSetup) {
            TableSetupView(epoch: epoch ?? model.epoch) {
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { showSetup = false }
                replayFromStart = true
                showTable = true
            }
        }
        .navigationDestination(isPresented: $showGraded) { TableView() }
        .fullScreenCover(isPresented: $showTable, onDismiss: {
            replayFromStart = false
            if setupAfterTable { setupAfterTable = false; showSetup = true }
        }) {
            FreeTableView(epoch: epoch ?? model.epoch, replayFromStart: replayFromStart,
                          onClose: { showTable = false },
                          onNewTable: { setupAfterTable = true; showTable = false })
        }
        .modifier(ProgressSaveNotice())
        .onAppear {
            if epoch == nil { epoch = model.epoch }
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_PRACTICE"] != nil {
                if model.state.tableState == nil {
                    let players = ProcessInfo.processInfo.environment["GT_DEMO_PLAYERS"].flatMap(Int.init) ?? 4
                    let styles = Array([Archetype.tag, .station, .lag].prefix(max(1, min(3, players - 1))))
                    perform { try model.startTable(seed: 97, styles: styles, expectedEpoch: model.epoch) }
                }
                showTable = model.state.tableState != nil
            }
            #endif
        }
        .onChange(of: model.epoch) { _, value in epoch = value }
        .alert(language.text("테이블을 시작하지 못했어요", "Couldn't start the table"), isPresented: $failure) {
            Button(language.text("확인", "OK"), role: .cancel) {}
        }
    }

    /// Opens the table in progress, or sets up a new one.
    private var freeCard: some View {
        Button {
            if model.state.tableState != nil { showTable = true } else { showSetup = true }
        } label: {
            if let table = model.state.tableState {
                TapCardLabel(title: language.text("자유 대전 이어서", "Continue the free table"),
                             detail: language.text("\(table.seatCount)명 테이블 · \(table.handNumber + 1)번째 핸드. 여기서는 채점하지 않아요.",
                                                   "\(table.seatCount)-player table · hand \(table.handNumber + 1). No grading here."),
                             emphasized: true)
            } else {
                TapCardLabel(title: language.text("자유 대전", "Free table"),
                             detail: language.text("컴퓨터 한 명에서 세 명과 한 판을 끝까지 쳐요. 여기서는 채점하지 않아요.",
                                                   "Play whole hands against one to three computers. No grading here."),
                             emphasized: true)
            }
        }
        .buttonStyle(GTPress())
        .accessibilityIdentifier("play-free")
        .disabled(model.saveError != nil)
    }

    /// The graded 1:1 exercise lives in Play as its own mode, beside the free table.
    private var playTitle: some View {
        Text(language.text("플레이", "Play")).font(GT.title(30))
    }

    private var gradedCard: some View {
        Button { showGraded = true } label: {
            TapCardLabel(title: language.text("1:1 채점 연습", "Graded 1:1 practice"),
                         detail: language.text("상대 한 명과 쳐요. 판단마다 공개된 차트와 평균값으로 채점해요.",
                                               "One opponent. Each decision is graded by a published chart and EV."))
        }
        .buttonStyle(GTPress())
        .accessibilityIdentifier("play-graded")
    }

    private func perform(_ operation: () throws -> Bool) {
        do { if try !operation(), model.saveError == nil { failure = true } }
        catch { failure = true }
    }
}

/// The first table explains itself once; the info button reopens it.
enum PlayTableGuide {
    private static var key: String {
        #if DEBUG
        let suffix = ProcessInfo.processInfo.environment["GT_TEST_STORE_ID"] ?? "shared"
        #else
        let suffix = "shared"
        #endif
        return "play.tableGuideSeen.v1.\(suffix)"
    }

    static var seen: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

/// What each part of the free table shows, in the order a new player looks at it.
struct PlayTableGuideList: View {
    @Environment(\.learningLanguage) private var language

    private var items: [(symbol: String, title: String, detail: String)] {
        [
            ("person.crop.square", language.text("내 카드", "Your cards"),
             language.text("오른쪽 아래 자리가 나예요. 내 카드 두 장은 나만 볼 수 있고, 상대는 못 봐요.",
                           "You sit bottom right. Only you can see your two cards; others can't.")),
            ("rectangle.on.rectangle", language.text("상대 카드", "Opponents' cards"),
             language.text("상대 카드는 뒤집혀 있어요. 끝까지 간 핸드는 끝날 때 공개돼요.",
                           "Opponents' cards stay face down. Hands that reach a showdown are shown at the end.")),
            ("square.grid.3x1.below.line.grid.1x2", language.text("공용 카드", "Shared cards"),
             language.text("가운데 카드는 모두가 함께 써요. 세 장, 한 장, 다시 한 장 순서로 펼쳐져요.",
                           "Everyone uses the middle cards. They come out three, one, one.")),
            ("circle.grid.cross", language.text("팟", "The pot"),
             language.text("가운데 숫자는 이번 핸드에 모인 칩이에요. 이긴 사람이 모두 가져가요.",
                           "The middle number is every chip bet this hand. The winner takes it.")),
            ("hand.point.right", language.text("차례", "Whose turn"),
             language.text("밝게 표시된 자리가 행동할 차례예요. 컴퓨터는 한 명씩 차례로 움직이고, 내 차례가 오면 버튼이 열려요.",
                           "The highlighted seat acts next. Computers move one at a time; your buttons open when the turn reaches you.")),
            ("arrow.up.arrow.down", language.text("행동의 가격", "What each action costs"),
             language.text("폴드는 무료로 핸드를 떠나요. 콜은 버튼에 적힌 칩을 내고, 레이즈는 가격을 더 올려요.",
                           "Folding leaves the hand for free. Calling pays the chips on the button; raising sets a higher price.")),
            ("lightbulb", language.text("힌트", "Hint"),
             language.text("힌트 버튼은 필요할 때만 열어요. 내 핸드와 콜 가격 같은 사실을 보여 주고, 무엇을 고를지는 정해 주지 않아요.",
                           "Open Hint only when you want it. It shows facts like your hand and the price to call, never a pick.")),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(items, id: \.title) { item in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(GT.inkSecondary)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(GT.semibold(16)).foregroundStyle(GT.ink)
                        Text(item.detail).font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                            .lineSpacing(GT.Typography.bodyLineSpacing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .gtPanel()
                .accessibilityElement(children: .combine)
            }
        }
    }
}

struct PlayTableGuideView: View {
    @Environment(\.learningLanguage) private var language
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(language.text("테이블 보는 법", "How to read the table"))
                        .font(GT.title(26)).foregroundStyle(GT.ink)
                    PlayTableGuideList()
                    FeltCTAButton(title: language.text("테이블로 가기", "Go to the table"), action: onClose)
                        .accessibilityIdentifier("play-table-guide-close")
                }
                .gtContentEdge()
            }
            .background(FeltBackground())
            .gtChrome(leading: { ChromeButton.close(onClose) })
            .gtSheetSurface()
        }
        .accessibilityIdentifier("play-table-guide-sheet")
    }
}

/// Stacks a header, then two cards whose shared gap sits at `splitY`. When the header
/// is too tall for that (large text), the cards simply follow it.
private struct MidlineSplitLayout: Layout {
    let splitY: CGFloat
    let spacing: CGFloat
    let gap: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        return CGSize(width: width, height: frames(width: width, subviews: subviews).last?.maxY ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews,
                       cache: inout ()) {
        for (subview, frame) in zip(subviews, frames(width: bounds.width, subviews: subviews)) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                          proposal: ProposedViewSize(frame.size))
        }
    }

    private func frames(width: CGFloat, subviews: Subviews) -> [CGRect] {
        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)) }
        guard sizes.count >= 2 else { return [] }
        var frames: [CGRect] = []
        var y: CGFloat = 0
        for size in sizes.dropLast(2) {
            frames.append(CGRect(x: 0, y: y, width: width, height: size.height))
            y += size.height + spacing
        }
        let first = sizes[sizes.count - 2], second = sizes[sizes.count - 1]
        let firstY = max(y, splitY - gap / 2 - first.height)
        frames.append(CGRect(x: 0, y: firstY, width: width, height: first.height))
        frames.append(CGRect(x: 0, y: firstY + first.height + gap, width: width, height: second.height))
        return frames
    }
}
