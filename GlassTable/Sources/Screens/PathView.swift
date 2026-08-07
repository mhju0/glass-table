// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// 길 — the road. Units of five nodes, each ending in a boss (spec §4.1).
///
/// Node state is carried by **shape first** (✓ / ▶ / lock / crown) with colour only
/// additive, the same WCAG discipline `VerdictRow` follows: colour is never the sole
/// channel for meaning.
struct PathView: View {
    @Environment(ProgressionModel.self) private var model
    let onOpenNode: (CurriculumNode) -> Void
    let onOpenFreePlay: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("길").font(GT.title(24)).foregroundStyle(GT.onFelt)
                    .padding(.top, 14).padding(.bottom, 14)

                ForEach(Array(Curriculum.units.enumerated()), id: \.element.id) { i, unit in
                    unitHeader(unit, index: i)
                    ForEach(unit.nodes, id: \.id) { node in
                        nodeRow(node)
                    }
                    .padding(.bottom, 14)
                }

                freePlayRow
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 96)   // clears the floating tab bar
        }
        .background(FeltBackground())
    }

    private func unitHeader(_ unit: CurriculumUnit, index: Int) -> some View {
        let cleared = unit.nodes.filter { model.status(of: $0) == .cleared }.count
        let done = cleared == unit.nodes.count
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                SectionLabel(text: "\(unit.section) · \(index + 1)단원")
                Spacer(minLength: 8)
                Text("\(cleared)/\(unit.nodes.count)")
                    .font(GT.semibold(11).monospacedDigit())
                    .foregroundStyle(done ? GT.mint : GT.onFeltSecondary)
            }
            Text(unit.title).font(GT.title(13)).foregroundStyle(GT.onFelt)
            // A filled bar reads before the fraction does — the "5/5" was carrying the
            // whole unit's state as two glyphs at the end of a sentence.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(GT.feltDeep)
                    Capsule().fill(GT.mint)
                        .frame(width: geo.size.width * Double(cleared)
                                      / Double(max(unit.nodes.count, 1)))
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.onFelt.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(unit.section) \(index + 1)단원 \(unit.title), "
                            + "\(unit.nodes.count)개 중 \(cleared)개 완료")
    }

    /// One node on the rail.
    ///
    /// The weight used to run backwards: a cleared node was a 40pt disc of `onFelt` —
    /// the brightest, largest thing on the screen — while the node you were actually
    /// meant to open was a hollow ring. Finished work drew the eye and the next step
    /// did not. Cleared nodes are now small mint discs, and only the live one gets the
    /// full badge, the halo and a glass card behind its title.
    ///
    /// The serpentine indent is gone with it. It was documented as decorative, but
    /// staggered rows read as a dependency tree, and the nodes in a unit are a
    /// sequence, not a branch. A continuous rail carries the route instead.
    private func nodeRow(_ node: CurriculumNode) -> some View {
        let status = model.status(of: node)
        let isBoss: Bool = { if case .boss = node.kind { return true }; return false }()
        let live = status == .available
        return Button { onOpenNode(node) } label: {
            HStack(spacing: 12) {
                ZStack {
                    Rectangle().fill(GT.hairlineFelt)
                        .frame(width: 2).frame(maxHeight: .infinity)
                    badge(status: status, isBoss: isBoss)
                }
                .frame(width: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(node.title).font(GT.title(live ? 15 : 13.5))
                        .foregroundStyle(status == .locked ? GT.onFelt.opacity(0.5) : GT.onFelt)
                    Text(isBoss ? "단원 시험" : nodeBlurb(node))
                        .font(GT.body(10.5))
                        .foregroundStyle(GT.onFeltSecondary.opacity(status == .locked ? 0.6 : 1))
                        .lineLimit(1)
                }
                .padding(live ? 12 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    if live {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(GT.glass)
                            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(GT.mint.opacity(0.45), lineWidth: 1))
                    }
                }
                // Row height comes from here, not from padding on the HStack — the rail
                // has to span the whole row or it renders as stubs either side of each
                // badge instead of one continuous line.
                .padding(.vertical, live ? 5 : 10)

                if let tier = tierBadge(node) { tierPill(tier) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .disabled(status == .locked)
        .accessibilityLabel("\(node.title). \(statusWord(status))"
                            + (tierBadge(node).map { ", 숙련도 \($0)" } ?? ""))
    }

    /// Mastery as a chip. It was 10pt grey text pinned to the right edge, which is the
    /// hardest thing on the row to scan and the reason the four tiers never registered.
    private func tierPill(_ tier: String) -> some View {
        let peak = tier == "숙달"
        return Text(tier)
            .font(GT.semibold(10))
            .foregroundStyle(peak ? GTBand.spotOnInk : GT.onFeltSecondary)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(peak ? GTBand.spotOnTint : GT.onFelt.opacity(0.08), in: Capsule())
    }

    private func badge(status: NodeStatus, isBoss: Bool) -> some View {
        let live = status == .available
        let size: CGFloat = live ? 34 : 24
        return ZStack {
            Circle()
                .fill(status == .locked ? GT.feltDeep : (live ? GT.felt : GT.mint))
                .overlay {
                    switch status {
                    case .locked: Circle().stroke(GT.hairlineFelt, lineWidth: 1.5)
                    case .available: Circle().stroke(GT.mint, lineWidth: 2.5)
                    case .cleared: EmptyView()
                    }
                }
                .frame(width: size, height: size)
            Image(systemName: glyph(status: status, isBoss: isBoss))
                .font(.system(size: live ? 14 : 10, weight: .bold))
                .foregroundStyle(status == .locked ? GT.onFeltMuted
                                                   : (live ? GT.mint : GT.onCTA))
        }
        // The live node keeps a halo so it reads at a glance without needing colour.
        .overlay {
            if live {
                Circle().stroke(GT.mint.opacity(0.20), lineWidth: 5)
                    .frame(width: size + 8, height: size + 8)
            }
        }
        .accessibilityHidden(true)
    }

    private func glyph(status: NodeStatus, isBoss: Bool) -> String {
        switch status {
        case .cleared:   return "checkmark"
        case .locked:    return "lock.fill"
        case .available: return isBoss ? "crown.fill" : "play.fill"
        }
    }

    private func statusWord(_ s: NodeStatus) -> String {
        switch s {
        case .cleared: return "완료"
        case .available: return "지금 할 차례"
        case .locked: return "잠김"
        }
    }

    /// Mastery shown per node, from the concept it teaches.
    private func tierBadge(_ node: CurriculumNode) -> String? {
        guard let concept = Curriculum.taughtConcept(of: node) else { return nil }
        let r = model.record(for: concept)
        guard r.total > 0 else { return nil }
        switch r.tier {
        case .attempted:  return "시도"
        case .familiar:   return "익숙"
        case .proficient: return "능숙"
        case .mastered:   return "숙달"
        }
    }

    /// Spec §7.1: unlimited free play, always reachable, never the greeting.
    private var freePlayRow: some View {
        Button(action: onOpenFreePlay) {
            HStack(spacing: 10) {
                Image(systemName: "infinity").font(.system(size: 14, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("자유 연습").font(GT.title(13.5))
                    Text("아무 드릴이나, 횟수 제한 없이").font(GT.body(10.5))
                        .foregroundStyle(GT.onFeltSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(GT.onFelt)
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(GT.onFelt.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(GTPress())
        .padding(.top, 18)
    }
}
