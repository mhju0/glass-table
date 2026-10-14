// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// One seat on the shared table. Captions describe what is on the table now; they
/// never carry a calculated total the learner is being asked to work out.
struct TableSeat: Identifiable {
    enum Place { case topLeading, topTrailing, bottomLeading, bottomTrailing, bottomCenter }
    enum Hand: Equatable { case none, faceDown, faceUp([Card]) }
    enum Tone { case action, neutral }

    let id: String
    let place: Place
    let name: String
    /// A public fact about the seat, such as its stack in Play. Give it to every
    /// seat or none, so the seats keep one height.
    var detail: String?
    var status: String?
    var tone: Tone = .action
    var isActive = false
    var isFolded = false
    var isDealer = false
    var hand: Hand = .none
    var stack: Int?
    var committed: Int?
    var isHero = false
}

/// The middle of the table: shared cards above one fixed-size chip stack.
struct TableCenter {
    var board: [Card] = []
    /// Keeps the board's row in the layout before any card is dealt, so dealing the
    /// flop does not move the pot.
    var reservesBoard = false
    /// `nil` keeps the total hidden; the label then only names the pot.
    var potTotal: String?
    /// Spoken in place of "Pot, <potTotal>" when the visible text already names the pot.
    var potSpoken: String?
}

/// A part of the table a guide can point at.
enum TableSpot: Hashable { case seat(String), chips, board, pot }

/// The one table used wherever seats and actions matter: pot counting and Play.
///
/// Geometry is fixed so it reads as one object in every mode: a 3pt rail at a 32pt
/// radius, seats inset 10pt from its inner edge, and each seat's outward corner at
/// 32 - 3 - 10 = 19pt. Active and resting seats both draw a 2pt border, so the
/// highlight changes colour and never size. Seat captions reserve their line, so the
/// table keeps its bounds across question, answer and reveal.
struct TableSurface: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.learningLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @ScaledMetric(relativeTo: .body) private var nameLineHeight: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var statusLineHeight: CGFloat = 16

    let seats: [TableSeat]
    var center = TableCenter()
    /// A seat whose chip is travelling to the middle; `arrived` animates it there.
    var movingChip: (seatID: String, arrived: Bool)?
    /// Sends `movingChip` the other way: from the pot to the seat, as a payout.
    var chipFromPot = false
    var freeVisuals: FreeTableVisuals?
    var freeReduceMotion: Bool?
    var freeHoles: [[String]] = []
    var freeBoard: [String] = []
    /// The free table lets the felt take the height above its dock, with a larger board.
    var fillsHeight = false
    /// A guided spotlight: every part not named here is dimmed. `nil` dims nothing.
    var spotlight: Set<TableSpot>?
    /// Parts drawn with a gold outline, to say "look here" without dimming the rest.
    var ringed: Set<TableSpot> = []
    private var boardHeight: CGFloat { fillsHeight ? 46 : TableCard.height }
    @State private var freeAnchors: [FreeTableFlight.Anchor: CGPoint] = [:]
    private var reduceMotion: Bool { freeReduceMotion ?? systemReduceMotion }

    private func dim(_ spot: TableSpot) -> Double {
        spotlight.map { $0.contains(spot) ? 1 : 0.28 } ?? 1
    }

    @ViewBuilder private func ring(_ spot: TableSpot) -> some View {
        if ringed.contains(spot) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(GT.tableSeatActive, lineWidth: 2).padding(-6)
        }
    }

    static let radius: CGFloat = GT.Radius.control
    static let rail: CGFloat = 3
    static let inset: CGFloat = 10
    static let seatGap: CGFloat = 16

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize { stackedLayout } else { tableLayout }
        }
        .coordinateSpace(.named(TableSurfaceSpace.name))
        .onPreferenceChange(FreeTableAnchorsKey.self) { freeAnchors = $0 }
        .onPreferenceChange(SeatCentersKey.self) { seatCenters = $0 }
        .overlay { freeFlights }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(language.text("포커 테이블", "Poker table"))
    }

    // MARK: Layouts

    private var tableLayout: some View {
        VStack(spacing: 0) {
            row(leading: seat(at: .topLeading), trailing: seat(at: .topTrailing))
            if fillsHeight {
                Spacer(minLength: centerHeight + 32)
            } else if seats.contains(where: { $0.stack != nil }) {
                Color.clear.frame(height: centerHeight + 32).accessibilityHidden(true)
            } else {
                Spacer(minLength: centerHeight + 16)
            }
            if let middle = seat(at: .bottomCenter) {
                HStack(spacing: Self.seatGap) {
                    Color.clear.frame(maxWidth: .infinity).accessibilityHidden(true)
                    seatView(middle, place: .bottomCenter)
                    Color.clear.frame(maxWidth: .infinity).accessibilityHidden(true)
                }
                .fixedSize(horizontal: false, vertical: true)
            } else {
                row(leading: seat(at: .bottomLeading), trailing: seat(at: .bottomTrailing))
            }
        }
        .padding(Self.rail + Self.inset)
        .frame(maxWidth: .infinity, minHeight: typeSize >= .xLarge ? 280 : 240,
               maxHeight: fillsHeight ? .infinity : nil)
        .background { felt }
        .overlay { centerGroup }
        .overlay { chipInFlight }
        .coordinateSpace(.named(TableSurfaceSpace.name))
        .onPreferenceChange(SeatCentersKey.self) { seatCenters = $0 }
    }

    /// Accessibility sizes: one column inside the felt instead of shrinking names.
    private var stackedLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(seats) { seat in
                VStack(spacing: 4) {
                    seatView(seat, place: nil)
                    if let committed = seat.committed, committed > 0 {
                        committedLabel(committed).opacity(dim(.chips))
                    }
                }
            }
            centerGroup.frame(maxWidth: .infinity).padding(.vertical, 8)
        }
        .padding(Self.rail + Self.inset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { felt }
    }

    private var felt: some View {
        RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
            .fill(GT.tableFelt)
            .overlay {
                RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
                    .strokeBorder(GT.tableRail, lineWidth: Self.rail)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Self.radius - Self.rail, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                    .padding(Self.rail)
            }
            .accessibilityHidden(true)
    }

    private func row(leading: TableSeat?, trailing: TableSeat?) -> some View {
        HStack(spacing: Self.seatGap) {
            if let leading { seatView(leading, place: leading.place) }
            else { Color.clear.frame(maxWidth: .infinity).accessibilityHidden(true) }
            if let trailing { seatView(trailing, place: trailing.place) }
            else { Color.clear.frame(maxWidth: .infinity).accessibilityHidden(true) }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func seat(at place: TableSeat.Place) -> TableSeat? {
        seats.first { $0.place == place }
    }

    // MARK: Seat

    @State private var seatCenters: [String: CGPoint] = [:]

    @ViewBuilder
    private func seatView(_ seat: TableSeat, place: TableSeat.Place?) -> some View {
        if seat.stack != nil { practiceSeat(seat, place: place) }
        else { legacySeat(seat, place: place) }
    }

    private func legacySeat(_ seat: TableSeat, place: TableSeat.Place?) -> some View {
        let shape = seatShape
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                seatDetail(seat)
                Spacer(minLength: 0)
                cards(seat)
            }
            VStack(alignment: .leading, spacing: 6) {
                seatDetail(seat)
                cards(seat)
            }
        }
        .gtInset(GT.Space.seat, firstText: .semibold(14))
        .frame(maxWidth: .infinity, minHeight: 60, maxHeight: .infinity, alignment: .leading)
        .background(GT.tableSeat, in: shape)
        .overlay {
            shape.strokeBorder(seat.isActive ? GT.tableSeatActive : GT.tableSeatLine, lineWidth: 2)
        }
        .background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: SeatCentersKey.self,
                    value: [seat.id: CGPoint(
                        x: proxy.frame(in: .named(TableSurfaceSpace.name)).midX,
                        y: proxy.frame(in: .named(TableSurfaceSpace.name)).midY)])
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel(seat))
        .accessibilityAddTraits(seat.isActive ? .isSelected : [])
    }

    private func practiceSeat(_ seat: TableSeat, place: TableSeat.Place?) -> some View {
        let shape = seatShape
        let ink = seat.isHero ? Color(hex: 0x1D221F) : GT.onTable
        let secondary = seat.isHero ? Color(hex: 0x5D625B) : GT.tableStatus
        let actionInk = seat.isHero ? Color(hex: 0x88600F) : GT.tableSeatActive
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(seat.name).font(GT.semibold(14)).foregroundStyle(ink)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                    .fixedSize(horizontal: false, vertical: true)
                if seat.isDealer { DealerDisc() }
            }
            .frame(minHeight: nameLineHeight, alignment: .topLeading)
            Text(seat.status ?? " ")
                .font(seat.tone == .action ? GT.semibold(13) : GT.body(13))
                .foregroundStyle(seat.tone == .action ? actionInk : secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                .frame(minHeight: statusLineHeight, alignment: .topLeading)
                .scaleEffect(reduceMotion ? 1 : 1 + 0.12 * sin(.pi * (freeVisuals?.checkProgress[Int(seat.id.replacingOccurrences(of: "practice-", with: "")) ?? -1] ?? 0)))
                .id(seat.status)
                .transition(.opacity)
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    practiceCards(seat).frame(height: 43, alignment: .bottom)
                    stackLabel(seat, ink: ink).frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .bottom, spacing: 4) {
                        practiceCards(seat).frame(height: 43, alignment: .bottom)
                        Spacer(minLength: 0)
                        stackLabel(seat, ink: ink)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        practiceCards(seat).frame(height: 43, alignment: .bottom)
                        stackLabel(seat, ink: ink).frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
        .gtInset(GT.Space.seat, firstText: .semibold(14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(seat.isHero ? Color(hex: 0xF3EDE0) : GT.tableSeat, in: shape)
        .overlay {
            shape.strokeBorder(seat.isActive ? GT.tableSeatActive
                : seat.isHero ? Color(hex: 0xE5DCC8) : GT.tableSeatLine, lineWidth: 2)
        }
        .opacity(dim(.seat(seat.id)))
        .overlay(alignment: place == .bottomLeading || place == .bottomTrailing ? .top : .bottom) {
            if !typeSize.isAccessibilitySize, let committed = seat.committed, committed > 0 {
                committedLabel(committed)
                .offset(y: place == .bottomLeading || place == .bottomTrailing ? -20 : 20)
                .opacity(dim(.chips))
                .accessibilityHidden(true)
            }
        }
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: SeatCentersKey.self, value: [seat.id: CGPoint(
                    x: proxy.frame(in: .named(TableSurfaceSpace.name)).midX,
                    y: proxy.frame(in: .named(TableSurfaceSpace.name)).midY)])
            }
        }
        .animation(GT.Motion.fade, value: seat.status)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel(seat))
        .accessibilityIdentifier(seat.id)
        .accessibilityAddTraits(seat.isActive ? .isSelected : [])
    }

    @ViewBuilder
    private func practiceCards(_ seat: TableSeat) -> some View {
        if let visuals = freeVisuals, let index = Int(seat.id.replacingOccurrences(of: "practice-", with: "")),
                visuals.arrived.indices.contains(index) {
            HStack(spacing: 3) {
                ForEach(0..<2) { slot in
                    let size: CGFloat = seat.isHero ? 43 : 36
                    let arrived = slot < visuals.arrived[index]
                    let flip = visuals.flipping[index] ?? (visuals.exposed.contains(index) ? 1 : 0)
                    let cards: [Card] = if case let .faceUp(cards) = seat.hand { cards } else { [] }
                    let actual = cards.indices.contains(slot) ? cards[slot]
                        : freeHoles.indices.contains(index) && freeHoles[index].indices.contains(slot)
                            ? Card(freeHoles[index][slot]) : nil
                    PlayingCardView(card: actual ?? Card(rank: 2, suit: 0), size: size,
                                    faceDown: flip < 0.5 && cards.isEmpty)
                        .rotation3DEffect(.degrees(reduceMotion ? 0 : flip < 0.5 ? -180 * flip : 180 * (1 - flip)), axis: (x: 0, y: 1, z: 0))
                        .opacity(arrived ? (reduceMotion && flip > 0 && flip < 1 ? flip : 1) : 0)
                        .modifier(FreeWinnerCardModifier(card: actual, visuals: visuals, reduceMotion: reduceMotion))
                        .background { anchorProbe(.hole(index, slot)) }
                }
            }
            .opacity(1 - 0.55 * (visuals.foldProgress[index] ?? (seat.isFolded ? 1 : 0)))
            .offset(y: reduceMotion ? 0 : (seat.place == .bottomLeading || seat.place == .bottomTrailing ? -2 : 2) * (visuals.foldProgress[index] ?? 0))
            .opacity(1 - visuals.clearProgress)
        }
        else { cards(seat) }
    }

    private func committedLabel(_ amount: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "circle.fill").font(.system(size: 7))
            Text("\(amount)").font(GT.semibold(12)).monospacedDigit()
        }
        .foregroundStyle(GT.onTable)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func stackLabel(_ seat: TableSeat, ink: Color) -> some View {
        if let stack = seat.stack {
            HStack(spacing: 3) {
                Image(systemName: "circle.fill").font(.system(size: 7))
                Text(stack == 0 ? language.text("올인", "All in") : "\(stack)")
                    .font(GT.semibold(13)).monospacedDigit().fixedSize()
            }
            .foregroundStyle(stack == 0 ? (seat.isHero ? Color(hex: 0x88600F) : GT.tableSeatActive) : ink)
        }
    }

    private func seatDetail(_ seat: TableSeat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(seat.name)
                    .font(GT.semibold(14))
                    .foregroundStyle(GT.onTable)
                    .fixedSize(horizontal: false, vertical: true)
                if seat.isDealer { DealerDisc() }
            }
            if let detail = seat.detail {
                Text(detail)
                    .font(GT.body(13))
                    .monospacedDigit()
                    .foregroundStyle(GT.tableStatus)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // A reserved line: a seat never grows when its caption appears.
            Text(seat.status ?? " ")
                .font(seat.tone == .action ? GT.semibold(13) : GT.body(13))
                .foregroundStyle(seat.tone == .action ? GT.tableSeatActive : GT.tableStatus)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func cards(_ seat: TableSeat) -> some View {
        switch seat.hand {
        case .none:
            EmptyView()
        case .faceDown:
            HStack(spacing: 3) {
                PlayingCardView(card: Card(rank: 2, suit: 0), size: 36, faceDown: true)
                PlayingCardView(card: Card(rank: 2, suit: 0), size: 36, faceDown: true)
            }
                .opacity(seat.isFolded ? 0.45 : 1)
        case let .faceUp(cards):
            HStack(spacing: 3) {
                ForEach(cards, id: \.self) { PlayingCardView(card: $0, size: seat.isHero ? 43 : 36) }
            }
            .opacity(seat.isFolded ? 0.45 : 1)
        }
    }

    private var seatShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
    }

    private func spokenLabel(_ seat: TableSeat) -> String {
        var parts = [seat.name]
        if seat.isDealer { parts.append(language.text("딜러 버튼", "dealer button")) }
        if let status = seat.status { parts.append(status) }
        if let detail = seat.detail { parts.append(detail) }
        if let stack = seat.stack { parts.append(language.text("남은 칩 \(stack)", "\(stack) chips left")) }
        if let committed = seat.committed, committed > 0 {
            parts.append(language.text("낸 칩 \(committed)", "\(committed) committed"))
        }
        if seat.isFolded, seat.status == nil { parts.append(language.text("폴드", "folded")) }
        switch seat.hand {
        case .none: break
        case .faceDown:
            let index = Int(seat.id.replacingOccurrences(of: "practice-", with: ""))
            let count = index.flatMap { freeVisuals?.arrived.indices.contains($0) == true ? freeVisuals?.arrived[$0] : nil } ?? 2
            if count > 0 { parts.append(language.text("뒷면 카드 \(count)장", "\(count) face-down cards")) }
        case let .faceUp(cards): parts.append(cards.map { $0.spoken(in: language) }.joined(separator: ", "))
        }
        return parts.joined(separator: ", ")
    }

    // MARK: Center

    private var centerHeight: CGFloat {
        (center.reservesBoard || !center.board.isEmpty) ? boardHeight + 8 + ChipStack.height
            : ChipStack.height
    }

    private var centerGroup: some View {
        VStack(spacing: 8) {
            if center.reservesBoard || !center.board.isEmpty {
                HStack(spacing: 4) {
                    if let visuals = freeVisuals {
                        ForEach(0..<5) { index in
                            let actual = freeBoard.indices.contains(index) ? Card(freeBoard[index]) : nil
                            let flip = visuals.boardFlips[index] ?? (index < center.board.count ? 1 : 0)
                            PlayingCardView(card: actual ?? Card(rank: 2, suit: 0), size: boardHeight, faceDown: flip < 0.5)
                                .rotation3DEffect(.degrees(reduceMotion ? 0 : flip < 0.5 ? -180 * flip : 180 * (1 - flip)), axis: (x: 0, y: 1, z: 0))
                                .opacity(index < max(visuals.boardArrived, center.board.count) ? 1 - visuals.clearProgress : 0)
                                .modifier(FreeWinnerCardModifier(card: actual, visuals: visuals, reduceMotion: reduceMotion))
                                .background { anchorProbe(.board(index)) }
                        }
                    } else {
                    ForEach(center.board, id: \.self) {
                        TableCard(card: $0)
                            .transition(.asymmetric(insertion: .scale(scale: 0.6).combined(with: .opacity),
                                                    removal: .opacity))
                    }
                    }
                }
                .frame(height: boardHeight)
                .overlay { ring(.board) }
                .opacity(dim(.board))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(center.board.isEmpty
                    ? language.text("아직 공용 카드가 없어요", "No shared cards yet")
                    : language.text("공용 카드: ", "Shared cards: ")
                        + center.board.map { $0.spoken(in: language) }.joined(separator: ", "))
            }
            HStack(spacing: 6) {
                ChipStack()
                Text(center.potTotal ?? language.text("팟", "Pot"))
                    .font(center.potTotal == nil ? GT.semibold(13) : GT.title(14))
                    .monospacedDigit()
                    .foregroundStyle(GT.onTable)
                    .lineLimit(freeVisuals == nil ? 1 : 2)
                    .fixedSize(horizontal: freeVisuals == nil, vertical: true)
                    .contentTransition(.numericText())
            }
            .background { anchorProbe(.pot) }
            .overlay { ring(.pot) }
            .opacity(dim(.pot))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(center.potSpoken
                ?? center.potTotal.map { language.text("팟 \($0)", "Pot, \($0)") }
                ?? language.text("가운데 칩. 팟 총액은 아직 숨겨져 있어요",
                                 "Center chips. The pot total is hidden for now"))
            .accessibilityIdentifier("table-pot")
        }
    }

    @ViewBuilder
    private var chipInFlight: some View {
        if let movingChip, let start = seatCenters[movingChip.seatID] {
            GeometryReader { proxy in
                let pot = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                let (from, end) = chipFromPot ? (pot, start) : (start, pot)
                Circle()
                    .fill(GT.chipTop)
                    .overlay(Circle().strokeBorder(GT.chipEdge, style: StrokeStyle(lineWidth: 1.2, dash: [2.2, 1.8])))
                    .frame(width: 14, height: 14)
                    .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                    .position(movingChip.arrived ? end : from)
                    .opacity(movingChip.arrived ? 0.35 : 1)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func anchorProbe(_ anchor: FreeTableFlight.Anchor) -> some View {
        GeometryReader { proxy in
            Color.clear.preference(key: FreeTableAnchorsKey.self, value: [anchor: CGPoint(
                x: proxy.frame(in: .named(TableSurfaceSpace.name)).midX,
                y: proxy.frame(in: .named(TableSurfaceSpace.name)).midY)])
        }
    }

    private func flightPoint(_ anchor: FreeTableFlight.Anchor, pot: CGPoint) -> CGPoint {
        if let point = freeAnchors[anchor] { return point }
        switch anchor {
        case .pot, .board: return pot
        case let .seat(seat), let .hole(seat, _): return seatCenters["practice-\(seat)"] ?? pot
        case let .street(seat):
            let origin = seatCenters["practice-\(seat)"] ?? pot
            return CGPoint(x: origin.x + (pot.x - origin.x) * 0.4, y: origin.y + (pot.y - origin.y) * 0.4)
        }
    }

    @ViewBuilder private var freeFlights: some View {
        if let visuals = freeVisuals, !reduceMotion {
            GeometryReader { proxy in
                let pot = freeAnchors[.pot] ?? CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                ForEach(visuals.flights) { flight in
                    let from = flightPoint(flight.from, pot: pot), to = flightPoint(flight.to, pot: pot)
                    let t = flight.progress
                    let eased = flight.cargo == .dealer ? t : t * t * (3 - 2 * t)
                    Group {
                        switch flight.cargo {
                        case .card: PlayingCardView(card: Card(rank: 2, suit: 0), size: 36, faceDown: true)
                        case .dealer: DealerDisc()
                        case let .chips(amount):
                            VStack(spacing: 1) {
                                ChipStack()
                                Text("\(amount)").font(GT.fixed(11)).foregroundStyle(GT.onTable)
                            }
                        }
                    }
                    .position(x: from.x + (to.x - from.x) * eased, y: from.y + (to.y - from.y) * eased)
                }
            }.allowsHitTesting(false).accessibilityHidden(true)
        }
    }
}

private struct FreeWinnerCardModifier: ViewModifier {
    let card: Card?
    let visuals: FreeTableVisuals
    let reduceMotion: Bool
    func body(content: Content) -> some View {
        let wins = card.map { visuals.winnerCards.contains($0) } ?? false
        content
            .opacity(visuals.winnerCards.isEmpty || wins ? 1 : 0.45)
            .overlay {
                if wins { RoundedRectangle(cornerRadius: 3).strokeBorder(GT.tableSeatActive, lineWidth: 1.5) }
            }
            .offset(y: wins && !reduceMotion ? -5 * visuals.winnerProgress : 0)
    }
}

private struct FreeTableAnchorsKey: PreferenceKey {
    static let defaultValue: [FreeTableFlight.Anchor: CGPoint] = [:]
    static func reduce(value: inout [FreeTableFlight.Anchor: CGPoint], nextValue: () -> [FreeTableFlight.Anchor: CGPoint]) {
        value.merge(nextValue()) { $1 }
    }
}

private enum TableSurfaceSpace { static let name = "table-surface" }

private struct SeatCentersKey: PreferenceKey {
    static let defaultValue: [String: CGPoint] = [:]
    static func reduce(value: inout [String: CGPoint], nextValue: () -> [String: CGPoint]) {
        value.merge(nextValue()) { $1 }
    }
}

/// A table card, 26 x 36 for hands and the board alike, lifted by a small shadow.
struct TableCard: View {
    static let height: CGFloat = 36
    let card: Card

    var body: some View {
        PlayingCardView(card: card, size: Self.height)
            .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
    }
}

/// Fixed-size disc beside the seat name.
struct DealerDisc: View {
    var body: some View {
        Text("D")
            .font(GT.fixed(11))
            .foregroundStyle(GT.chipEdge)
            .frame(width: 18, height: 18)
            .background(GT.chipTop, in: Circle())
            .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
            .accessibilityHidden(true)
    }
}

/// Three ivory chips with slate edge marks. One size in every state, so the stack
/// never hints at how large the pot is.
struct ChipStack: View {
    static let height: CGFloat = 27

    var body: some View {
        Canvas { context, _ in
            context.fill(Path(ellipseIn: CGRect(x: 1, y: 20.6, width: 30, height: 6)),
                         with: .color(.black.opacity(0.3)))
            for top in [15.0, 10.5, 6.0] {
                // The chip's side: its top face lowered 4pt, joined to the top face.
                var side = Path(CGRect(x: 2, y: top, width: 28, height: 4))
                side.addEllipse(in: CGRect(x: 2, y: top - 1, width: 28, height: 10))
                context.fill(side, with: .color(GT.chipSide))
                var marks = Path()
                for x in [7.0, 16.0, 25.0] {
                    let edge = top + 5 * (1 - pow((x - 16) / 14, 2)).squareRoot()
                    marks.move(to: CGPoint(x: x, y: edge))
                    marks.addLine(to: CGPoint(x: x, y: edge + 4))
                }
                context.stroke(marks, with: .color(GT.chipEdge), lineWidth: 2.4)
                context.fill(Path(ellipseIn: CGRect(x: 2, y: top - 5, width: 28, height: 10)),
                             with: .color(GT.chipTop))
            }
            context.stroke(Path(ellipseIn: CGRect(x: 7.5, y: 3, width: 17, height: 6)),
                           with: .color(GT.chipEdge),
                           style: StrokeStyle(lineWidth: 0.9, dash: [2.2, 1.8]))
        }
        .frame(width: 32, height: Self.height)
        .accessibilityHidden(true)
    }
}
