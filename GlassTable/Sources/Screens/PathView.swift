// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

struct PathView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenNode: (CurriculumNode) -> Void
    let onOpenFreePlay: () -> Void
    @State private var expandedUnitIDs: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GT.Space.section) {
                header
                freePlay
                ForEach(Array(Curriculum.units.enumerated()), id: \.element.id) { index, unit in
                    unitSection(unit, index: index)
                }
            }
            .padding(.horizontal, 18)
        }
        .gtTabBarClearance()
        .background(FeltBackground())
        .onAppear { expandCurrentUnit() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("배움의 길").font(GT.title(30)).foregroundStyle(GT.onFelt)
            Text("한 단원씩 이해하고, 직접 꺼내 보고, 섞어서 확인해요.")
                .font(GT.body(15)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 14)
    }

    private var freePlay: some View {
        Button(action: onOpenFreePlay) {
            HStack(spacing: 13) {
                Image(systemName: "infinity")
                    .font(.system(size: 18, weight: .semibold)).foregroundStyle(GT.mint)
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("자유 연습").font(GT.title(17)).foregroundStyle(GT.onFelt)
                    Text("원하는 개념을 횟수 제한 없이 연습해요")
                        .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(GT.onFeltSecondary)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .gtPanel().contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
    }

    private func unitSection(_ unit: CurriculumUnit, index: Int) -> some View {
        let cleared = unit.nodes.filter { model.status(of: $0) == .cleared }.count
        let expanded = expandedUnitIDs.contains(unit.id)
        let current = unit.nodes.contains { model.status(of: $0) == .available }
        return VStack(spacing: 0) {
            Button { toggle(unit.id) } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(index + 1)단원").font(GT.semibold(13))
                            .foregroundStyle(current ? GT.mint : GT.onFeltSecondary)
                        Spacer(minLength: 8)
                        Text("\(cleared)/\(unit.nodes.count)")
                            .font(GT.semibold(13).monospacedDigit()).foregroundStyle(GT.onFeltSecondary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(GT.onFeltSecondary)
                            .rotationEffect(.degrees(expanded ? 180 : 0))
                    }
                    Text(unit.title).font(GT.title(21)).foregroundStyle(GT.onFelt)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(GT.hairlineFelt)
                            Capsule().fill(GT.mint)
                                .frame(width: proxy.size.width * Double(cleared)
                                       / Double(max(unit.nodes.count, 1)))
                        }
                    }.frame(height: 4)
                }
                .padding(.vertical, 14).contentShape(Rectangle())
            }
            .buttonStyle(GTPress())
            .accessibilityLabel("\(index + 1)단원, \(unit.title), \(unit.nodes.count)개 중 \(cleared)개 완료")
            .accessibilityHint(expanded ? "단원 접기" : "단원 펼치기")

            if expanded {
                VStack(spacing: 0) {
                    ForEach(unit.nodes, id: \.id) { node in nodeRow(node) }
                }
                .padding(.bottom, 8).transition(.opacity)
            }
        }
    }

    private func toggle(_ id: String) {
        withAnimation(reduceMotion ? nil : GT.Motion.change) {
            if expandedUnitIDs.contains(id) { expandedUnitIDs.remove(id) }
            else { expandedUnitIDs.insert(id) }
        }
    }

    private func expandCurrentUnit() {
        guard expandedUnitIDs.isEmpty,
              let unit = Curriculum.units.first(where: {
                  $0.nodes.contains { model.status(of: $0) == .available }
              }) else { return }
        expandedUnitIDs.insert(unit.id)
    }

    private func nodeRow(_ node: CurriculumNode) -> some View {
        let status = model.status(of: node)
        let boss = if case .boss = node.kind { true } else { false }
        return Button { onOpenNode(node) } label: {
            HStack(spacing: 13) {
                badge(status: status, boss: boss)
                VStack(alignment: .leading, spacing: 3) {
                    Text(node.title).font(GT.title(status == .available ? 17 : 15))
                        .foregroundStyle(status == .locked ? GT.onFeltMuted : GT.onFelt)
                    Text(boss ? "단원에서 배운 개념을 섞어서 풀어요" : nodeBlurb(node))
                        .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                if let label = practiceLabel(node) {
                    Text(label).font(GT.semibold(11)).foregroundStyle(GT.onFeltSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.vertical, 12).padding(.horizontal, status == .available ? 12 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(status == .available ? GT.glass : .clear,
                        in: RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(GTPress()).disabled(status == .locked)
        .accessibilityLabel("\(node.title), \(statusLabel(status))"
                            + (practiceLabel(node).map { ", \($0)" } ?? ""))
    }

    private func badge(status: NodeStatus, boss: Bool) -> some View {
        Image(systemName: icon(status: status, boss: boss))
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(status == .cleared ? GT.onCTA
                             : (status == .available ? GT.mint : GT.onFeltMuted))
            .frame(width: 30, height: 30)
            .background(status == .cleared ? GT.mint : GT.feltDeep, in: Circle())
            .overlay(Circle().stroke(status == .available ? GT.mint : GT.hairlineFelt,
                                     lineWidth: status == .available ? 2 : 1))
            .accessibilityHidden(true)
    }

    private func icon(status: NodeStatus, boss: Bool) -> String {
        switch status {
        case .cleared: return "checkmark"
        case .locked: return "lock.fill"
        case .available: return boss ? "crown.fill" : "play.fill"
        }
    }

    private func statusLabel(_ status: NodeStatus) -> String {
        switch status {
        case .cleared: return "완료"
        case .available: return "지금 할 차례"
        case .locked: return "잠김"
        }
    }

    private func practiceLabel(_ node: CurriculumNode) -> String? {
        guard let concept = Curriculum.taughtConcept(of: node) else { return nil }
        let record = model.record(for: concept)
        guard record.total > 0 else { return nil }
        switch record.tier {
        case .attempted: return "기록 시작"
        case .familiar: return "반복 중"
        case .proficient: return "능숙 단계"
        case .mastered: return "숙달 단계"
        }
    }
}
