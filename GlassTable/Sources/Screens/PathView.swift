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
                    ForEach(Array(unit.nodes.enumerated()), id: \.element.id) { j, node in
                        nodeRow(node, indent: indent(for: j, of: unit.nodes.count))
                    }
                }

                freePlayRow
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 96)   // clears the floating tab bar
        }
        .background(FeltBackground())
    }

    /// A gentle serpentine so the column reads as a route rather than a list. Purely
    /// decorative — order is already carried by vertical position.
    private func indent(for index: Int, of count: Int) -> CGFloat {
        let mid = Double(count - 1) / 2
        let distance = abs(Double(index) - mid) / max(mid, 1)
        return CGFloat((1 - distance) * 46)
    }

    private func unitHeader(_ unit: CurriculumUnit, index: Int) -> some View {
        let cleared = unit.nodes.filter { model.status(of: $0) == .cleared }.count
        return VStack(alignment: .leading, spacing: 3) {
            SectionLabel(text: "\(unit.section) · \(index + 1)단원")
            Text("\(unit.title) · \(cleared)/\(unit.nodes.count)")
                .font(GT.title(13)).foregroundStyle(GT.onFelt)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.onFelt.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 12)
        .accessibilityElement(children: .combine)
    }

    private func nodeRow(_ node: CurriculumNode, indent: CGFloat) -> some View {
        let status = model.status(of: node)
        let isBoss: Bool = { if case .boss = node.kind { return true }; return false }()
        return Button { onOpenNode(node) } label: {
            HStack(spacing: 12) {
                badge(status: status, isBoss: isBoss)
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.title).font(GT.title(13.5))
                        .foregroundStyle(status == .locked ? GT.onFelt.opacity(0.5) : GT.onFelt)
                    Text(isBoss ? "단원 시험" : nodeBlurb(node))
                        .font(GT.body(10.5))
                        .foregroundStyle(GT.onFeltSecondary.opacity(status == .locked ? 0.6 : 1))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if let tier = tierBadge(node) {
                    Text(tier).font(GT.semibold(10)).foregroundStyle(GT.onFeltSecondary)
                }
            }
            .padding(.leading, indent)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .disabled(status == .locked)
        .accessibilityLabel("\(node.title). \(statusWord(status))")
    }

    private func badge(status: NodeStatus, isBoss: Bool) -> some View {
        ZStack {
            Circle()
                .fill(status == .locked ? Color.clear : GT.onFelt)
                .overlay {
                    if status == .locked {
                        Circle().stroke(GT.hairlineFelt, lineWidth: 1.5)
                    }
                }
                .frame(width: 40, height: 40)
            Image(systemName: glyph(status: status, isBoss: isBoss))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(status == .locked ? GT.onFeltMuted : GT.felt)
        }
        // The live node gets a halo so it reads at a glance without needing colour.
        .overlay {
            if status == .available {
                Circle().stroke(GT.onFelt.opacity(0.28), lineWidth: 5)
                    .frame(width: 48, height: 48)
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
