// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// A small picture of what a skill asks, so the skill list reads at a glance. Purely
/// decorative: the row's text carries the meaning, and the accent settles in once.
struct SkillGlyph: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let concept: Concept
    @State private var settled = false

    var body: some View {
        picture
            .frame(width: 64, height: 48)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.tile, style: .continuous))
            .accessibilityHidden(true)
            .onAppear {
                if reduceMotion { settled = true }
                else { withAnimation(GT.Motion.fade) { settled = true } }
            }
    }

    @ViewBuilder private var picture: some View {
        switch concept {
        case .showdown:
            HStack(spacing: 6) {
                VStack(spacing: 2) {
                    accent(Image(systemName: "crown.fill").font(.system(size: 9)).foregroundStyle(GT.mint))
                    hand("A", "K")
                }
                hand("9", "9").padding(.top, 11).opacity(0.55)
            }
        case .potMath:
            HStack(spacing: 4) {
                chips(3)
                accent(Text("+").font(GT.fixed(12)).foregroundStyle(GT.mint))
                accent(chips(1))
            }
        case .position:
            ZStack {
                Ellipse().stroke(GT.hairlineFelt, lineWidth: 1).frame(width: 44, height: 26)
                ForEach(0..<6, id: \.self) { seat in
                    let angle = Double(seat) / 6 * 2 * .pi
                    Circle().fill(seat == 4 ? GT.mint : GT.onFeltMuted)
                        .frame(width: 7, height: 7)
                        .scaleEffect(seat == 4 && settled ? 1.4 : 1)
                        .offset(x: cos(angle) * 22, y: sin(angle) * 13)
                }
            }
        case .rfi:
            grid { row, column in row + column < 3 ? GT.mint : nil }
        case .defend:
            grid { row, column in row + column < 2 ? GT.mint : (row + column < 4 ? GT.green : nil) }
        case .rangeRead, .hitFrequency, .rangeAdvantage:
            grid { row, column in row < 2 && column < 2 ? GT.mint : (row + column < 5 ? GT.onFeltMuted : nil) }
        case .outs:
            HStack(spacing: 3) {
                card("7"); card("8"); card("9")
                accent(card("?", highlighted: true))
            }
        case .equitySense, .callFold, .mdf:
            VStack(spacing: 4) {
                ZStack(alignment: .leading) {
                    Capsule().fill(GT.hairlineFelt).frame(width: 44, height: 8)
                    Capsule().fill(GT.green).frame(width: settled ? 28 : 6, height: 8)
                    if concept != .equitySense {
                        Rectangle().fill(GT.mint).frame(width: 2, height: 14).offset(x: 15)
                    }
                }
                Text(concept == .equitySense ? "65%" : "?").font(GT.fixed(10)).foregroundStyle(GT.onFeltSecondary)
            }
        case .potOdds:
            HStack(spacing: 4) {
                chips(3)
                Text(":").font(GT.fixed(12)).foregroundStyle(GT.onFeltSecondary)
                accent(chips(1))
            }
        case .actionRead:
            HStack(spacing: 5) {
                Image(systemName: "bubble.left.fill").font(.system(size: 16)).foregroundStyle(GT.onFeltMuted)
                accent(hand("?", "?"))
            }
        case .combos:
            HStack(spacing: 4) {
                hand("A", "K")
                accent(Text("×16").font(GT.fixed(11)).foregroundStyle(GT.mint))
            }
        case .rangeNotation:
            accent(Text("AKs").font(GT.fixed(13)).foregroundStyle(GT.mint)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .overlay(Capsule().stroke(GT.mint, lineWidth: 1)))
        case .evCall, .evLoss:
            HStack(spacing: 4) {
                chips(2)
                accent(Text("±").font(GT.fixed(15)).foregroundStyle(GT.mint))
            }
        }
    }

    private func accent(_ view: some View) -> some View {
        view.opacity(settled ? 1 : 0).scaleEffect(settled ? 1 : 0.9)
    }

    private func card(_ label: String, highlighted: Bool = false) -> some View {
        Text(label).font(GT.fixed(9)).foregroundStyle(GT.cardInk)
            .frame(width: 12, height: 17)
            .background(GT.cardFace, in: RoundedRectangle(cornerRadius: 2.5, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .stroke(highlighted ? GT.mint : GT.cardEdge, lineWidth: highlighted ? 1.5 : 0.5))
    }

    private func hand(_ first: String, _ second: String) -> some View {
        HStack(spacing: 2) { card(first); card(second) }
    }

    private func chips(_ count: Int) -> some View {
        VStack(spacing: -4) {
            ForEach(0..<count, id: \.self) { _ in
                Capsule().fill(GT.chipTop).frame(width: 14, height: 7)
                    .overlay(Capsule().stroke(GT.chipEdge, lineWidth: 1))
            }
        }
    }

    private func grid(_ tone: @escaping (Int, Int) -> Color?) -> some View {
        VStack(spacing: 1.5) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 1.5) {
                    ForEach(0..<5, id: \.self) { column in
                        let color = tone(row, column)
                        RoundedRectangle(cornerRadius: 1.5).fill(color ?? GT.hairlineFelt)
                            .frame(width: 6.5, height: 6.5)
                            .opacity(color == nil || settled ? 1 : 0.25)
                    }
                }
            }
        }
    }
}
