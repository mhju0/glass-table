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
    var status: String?
    var tone: Tone = .action
    var isActive = false
    var isFolded = false
    var isDealer = false
    var hand: Hand = .none
}

/// The middle of the table: shared cards above one fixed-size chip stack.
struct TableCenter {
    var board: [Card] = []
    /// Keeps the board's row in the layout before any card is dealt, so dealing the
    /// flop does not move the pot.
    var reservesBoard = false
    /// `nil` keeps the total hidden; the label then only names the pot.
    var potTotal: String?
}

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

    let seats: [TableSeat]
    var center = TableCenter()
    /// A seat whose chip is travelling to the middle; `arrived` animates it there.
    var movingChip: (seatID: String, arrived: Bool)?

    static let radius: CGFloat = 32
    static let rail: CGFloat = 3
    static let inset: CGFloat = 10
    static let seatGap: CGFloat = 16
    static var seatOuterRadius: CGFloat { radius - rail - inset }

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize { stackedLayout } else { tableLayout }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(language.text("포커 테이블", "Poker table"))
    }

    // MARK: Layouts

    private var tableLayout: some View {
        VStack(spacing: 0) {
            row(leading: seat(at: .topLeading), trailing: seat(at: .topTrailing))
            Spacer(minLength: centerHeight + 16)
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
        .frame(maxWidth: .infinity, minHeight: typeSize >= .xLarge ? 280 : 240)
        .background { felt }
        .overlay { centerGroup }
        .overlay { chipInFlight }
        .coordinateSpace(.named(TableSurfaceSpace.name))
        .onPreferenceChange(SeatCentersKey.self) { seatCenters = $0 }
    }

    /// Accessibility sizes: one column inside the felt instead of shrinking names.
    private var stackedLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(seats) { seat in seatView(seat, place: nil) }
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

    private func seatView(_ seat: TableSeat, place: TableSeat.Place?) -> some View {
        let shape = seatShape(place)
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
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

    private func seatDetail(_ seat: TableSeat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(seat.name)
                    .font(GT.semibold(14))
                    .foregroundStyle(GT.onTable)
                    .fixedSize(horizontal: false, vertical: true)
                if seat.isDealer { DealerDisc() }
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
            HStack(spacing: 3) { TableCardBack(); TableCardBack() }
                .opacity(seat.isFolded ? 0.45 : 1)
        case let .faceUp(cards):
            HStack(spacing: 3) {
                ForEach(cards, id: \.self) { TableCard(card: $0) }
            }
            .opacity(seat.isFolded ? 0.45 : 1)
        }
    }

    private func seatShape(_ place: TableSeat.Place?) -> UnevenRoundedRectangle {
        let outer = Self.seatOuterRadius, inner: CGFloat = 10
        switch place {
        case .topLeading?:
            return UnevenRoundedRectangle(topLeadingRadius: outer, bottomLeadingRadius: inner,
                                          bottomTrailingRadius: inner, topTrailingRadius: inner,
                                          style: .continuous)
        case .topTrailing?:
            return UnevenRoundedRectangle(topLeadingRadius: inner, bottomLeadingRadius: inner,
                                          bottomTrailingRadius: inner, topTrailingRadius: outer,
                                          style: .continuous)
        case .bottomLeading?:
            return UnevenRoundedRectangle(topLeadingRadius: inner, bottomLeadingRadius: outer,
                                          bottomTrailingRadius: inner, topTrailingRadius: inner,
                                          style: .continuous)
        case .bottomTrailing?:
            return UnevenRoundedRectangle(topLeadingRadius: inner, bottomLeadingRadius: inner,
                                          bottomTrailingRadius: outer, topTrailingRadius: inner,
                                          style: .continuous)
        case .bottomCenter?, nil:
            return UnevenRoundedRectangle(topLeadingRadius: inner, bottomLeadingRadius: inner,
                                          bottomTrailingRadius: inner, topTrailingRadius: inner,
                                          style: .continuous)
        }
    }

    private func spokenLabel(_ seat: TableSeat) -> String {
        var parts = [seat.name]
        if seat.isDealer { parts.append(language.text("딜러 버튼", "dealer button")) }
        if seat.isFolded, seat.status == nil { parts.append(language.text("폴드", "folded")) }
        if let status = seat.status { parts.append(status) }
        switch seat.hand {
        case .none: break
        case .faceDown: parts.append(language.text("뒷면 카드 두 장", "two face-down cards"))
        case let .faceUp(cards): parts.append(cards.map { $0.spoken(in: language) }.joined(separator: ", "))
        }
        return parts.joined(separator: ", ")
    }

    // MARK: Center

    private var centerHeight: CGFloat {
        (center.reservesBoard || !center.board.isEmpty) ? TableCard.height + 8 + ChipStack.height
            : ChipStack.height
    }

    private var centerGroup: some View {
        VStack(spacing: 8) {
            if center.reservesBoard || !center.board.isEmpty {
                HStack(spacing: 4) {
                    ForEach(center.board, id: \.self) { TableCard(card: $0) }
                }
                .frame(height: TableCard.height)
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
                    .lineLimit(1)
                    .fixedSize()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(center.potTotal.map { language.text("팟 \($0)", "Pot, \($0)") }
                ?? language.text("가운데 칩. 팟 총액은 아직 숨겨져 있어요",
                                 "Center chips. The pot total is hidden for now"))
            .accessibilityIdentifier("table-pot")
        }
    }

    @ViewBuilder
    private var chipInFlight: some View {
        if let movingChip, let start = seatCenters[movingChip.seatID] {
            GeometryReader { proxy in
                let end = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                Circle()
                    .fill(GT.chipTop)
                    .overlay(Circle().strokeBorder(GT.chipEdge, style: StrokeStyle(lineWidth: 1.2, dash: [2.2, 1.8])))
                    .frame(width: 14, height: 14)
                    .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                    .position(movingChip.arrived ? end : start)
                    .opacity(movingChip.arrived ? 0.35 : 1)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
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

/// Solid deep slate with a cream inset line: distinct from the felt and from suit red.
struct TableCardBack: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(GT.cardBack)
            .overlay {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(GT.cardBackLine.opacity(0.7), lineWidth: 1)
                    .padding(3)
            }
            .frame(width: 26, height: TableCard.height)
            .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
            .accessibilityHidden(true)
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
