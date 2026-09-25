// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

struct PathView: View {
    @Environment(\.learningLanguage) private var language
    @Environment(ProgressionModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenNode: (CurriculumNode) -> Void
    let onOpenFreePlay: () -> Void
    let onOpenBasics: () -> Void
    @State private var expandedUnitIDs: Set<String> = []
    @State private var didScrollToCurrentNode = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: GT.Space.section) {
                    header
                    freePlay
                    basics
                    ForEach(Array(Curriculum.units.enumerated()), id: \.element.id) { index, unit in
                        if let stage = stageTitle(index) {
                            Text(stage).font(GT.title(24)).foregroundStyle(GT.ink)
                                .padding(.top, 12)
                        }
                        unitSection(unit, index: index)
                    }
                }
                .padding(.horizontal, 18)
            }
            .gtTabBarClearance()
            .background(FeltBackground())
            .onAppear {
                expandCurrentUnit()
                scrollToCurrentNodeOnce(using: proxy)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(language.text("배움의 길", "Learning path")).font(GT.title(30)).foregroundStyle(GT.onFelt)
            Text(language.text("추천 순서대로 배우거나 어떤 레슨이든 골라요. 앞 단계를 건너뛰어도 완료 기록은 그대로예요.", "Follow the suggested order or pick any lesson. Skipping ahead doesn't mark earlier lessons complete."))
                .font(GT.body(15)).foregroundStyle(GT.onFeltSecondary)
                .lineSpacing(GT.Typography.bodyLineSpacing)
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
                    Text(language.text("한 가지 집중 연습", "Practice one skill")).font(GT.title(17)).foregroundStyle(GT.onFelt)
                    Text(language.text("원하는 주제를 다섯 문제씩 연습해요", "Five questions on one topic"))
                        .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
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

    /// Always open and never graded, so it sits outside the numbered units.
    private var basics: some View {
        let done = model.state.basicsLessonCompleted == true
        return Button(action: onOpenBasics) {
            HStack(spacing: 13) {
                Image(systemName: done ? "checkmark.circle.fill" : "suit.spade.fill")
                    .font(.system(size: 18, weight: .semibold)).foregroundStyle(GT.mint)
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.text("홀덤 기초", "Hold'em basics")).font(GT.title(17)).foregroundStyle(GT.onFelt)
                    Text(language.text("카드가 나오는 순서와 족보", "How cards are dealt, and hand ranks"))
                        .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(GT.onFeltSecondary)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .gtPanel().contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityValue(done ? language.text("완료", "Completed") : "")
        .accessibilityIdentifier("path-basics")
    }

    private func unitSection(_ unit: CurriculumUnit, index: Int) -> some View {
        let cleared = unit.nodes.filter { model.status(of: $0) == .cleared }.count
        let expanded = expandedUnitIDs.contains(unit.id)
        let current = unit.nodes.contains { model.status(of: $0) == .available }
        return VStack(spacing: 0) {
            Button { toggle(unit.id) } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(language.text("\(index + 1)단원", "Unit \(index + 1)")).font(GT.semibold(13))
                            .foregroundStyle(current ? GT.mint : GT.onFeltSecondary)
                        Spacer(minLength: 8)
                        Text("\(cleared)/\(unit.nodes.count)")
                            .font(GT.semibold(13).monospacedDigit()).foregroundStyle(GT.onFeltSecondary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(GT.onFeltSecondary)
                            .rotationEffect(.degrees(expanded ? 180 : 0))
                    }
                    Text(unitTitle(unit, index: index)).font(GT.title(21)).foregroundStyle(GT.onFelt)
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
            .accessibilityLabel(language.text("\(index + 1)단원, \(unit.title), \(unit.nodes.count)개 중 \(cleared)개 완료", "Unit \(index + 1), \(unitTitle(unit, index: index)), \(cleared) of \(unit.nodes.count) completed"))
            .accessibilityHint(expanded ? language.text("단원 접기", "Collapse unit") : language.text("단원 펼치기", "Expand unit"))

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
              let node = currentNode,
              let unit = Curriculum.units.first(where: {
                  $0.nodes.contains(where: { $0.id == node.id })
              }) else { return }
        expandedUnitIDs.insert(unit.id)
    }

    private func scrollToCurrentNodeOnce(using proxy: ScrollViewProxy) {
        guard !didScrollToCurrentNode, let node = currentNode
        else { return }
        didScrollToCurrentNode = true
        // The row enters the hierarchy only after expanding its unit. Defer the one
        // initial scroll until that state has produced the row; subsequent renders do
        // not move the learner away from where they scrolled.
        DispatchQueue.main.async {
            proxy.scrollTo(node.id, anchor: .center)
        }
    }

    private var currentNode: CurriculumNode? {
        return Curriculum.allNodes.first(where: { model.status(of: $0) == .available })
    }

    private func nodeRow(_ node: CurriculumNode) -> some View {
        let status = model.status(of: node)
        let boss = if case .boss = node.kind { true } else { false }
        return Button { onOpenNode(node) } label: {
            HStack(spacing: 13) {
                badge(status: status, boss: boss)
                VStack(alignment: .leading, spacing: 3) {
                    Text(learningNodeTitle(node, language: language)).font(GT.title(status == .available ? 17 : 15))
                        .foregroundStyle(GT.onFelt)
                    Text(learningNodeDescription(node, language: language))
                        .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
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
        .buttonStyle(GTPress())
        .id(node.id)
        .accessibilityLabel("\(learningNodeTitle(node, language: language)), \(statusLabel(status))"
                            + (practiceLabel(node).map { ", \($0)" } ?? ""))
        .accessibilityIdentifier("lesson-\(node.id)")
    }

    private func badge(status: NodeStatus, boss: Bool) -> some View {
        Image(systemName: icon(status: status, boss: boss))
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(status == .cleared ? GT.onCTA
                             : (status == .available ? GT.mint : GT.onFeltMuted))
            .frame(width: 30, height: 30)
            .background(status == .cleared ? GT.cta : GT.surface, in: Circle())
            .overlay(Circle().stroke(status == .available ? GT.mint : GT.hairlineFelt,
                                     lineWidth: status == .available ? 2 : 1))
            .accessibilityHidden(true)
    }

    private func icon(status: NodeStatus, boss: Bool) -> String {
        switch status {
        case .cleared: return "checkmark"
        case .locked: return "play.fill"
        case .available: return boss ? "crown.fill" : "play.fill"
        }
    }

    private func statusLabel(_ status: NodeStatus) -> String {
        switch status {
        case .cleared: return language.text("완료", "Completed")
        case .available: return language.text("추천 순서", "Suggested next")
        case .locked: return language.text("언제든 시작", "Available anytime")
        }
    }

    private func practiceLabel(_ node: CurriculumNode) -> String? {
        guard let concept = Curriculum.taughtConcept(of: node) else { return nil }
        let record = model.record(for: concept)
        guard record.total > 0 else { return nil }
        switch record.tier {
        case .attempted: return language.text("기록 시작", "Started")
        case .familiar: return language.text("반복 중", "Building familiarity")
        case .proficient: return language.text("능숙 단계", "Practiced")
        case .mastered: return language.text("숙달 단계", "Mixed checks passed")
        }
    }

    private func unitTitle(_ unit: CurriculumUnit, index: Int) -> String {
        language.text(unit.title, LearningMilestone.unitTitlesEnglish[index])
    }

    private func stageTitle(_ index: Int) -> String? {
        switch index {
        case 0: language.text("카드와 칩부터", "Start with cards and chips")
        case 1: language.text("가격과 가능성 비교", "Weigh the price and chances")
        case 2: language.text("상대의 가능한 패 읽기", "Read possible hands")
        case 5: language.text("더 깊이 있는 판단", "Go deeper with decisions")
        default: nil
        }
    }
}
