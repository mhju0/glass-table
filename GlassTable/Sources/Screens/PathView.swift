// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

struct PathView: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.leadsWithTerms) private var termsLead
    @Environment(ProgressionModel.self) private var model
    let onOpenNode: (CurriculumNode) -> Void
    let onOpenFreePlay: () -> Void
    let onOpenBasics: () -> Void
    @State private var didScrollToCurrentNode = false
    /// A lesson opened ahead of the suggested order, awaiting the learner's choice.
    @State private var early: CurriculumNode?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: GT.Space.section) {
                    header
                    freePlay
                    basics
                    ForEach(Curriculum.tracks) { track in trackSection(track) }
                }
                .padding(.horizontal, GT.Space.edge)
            }
            .gtTabBarClearance()
            .background(FeltBackground())
            .onAppear { scrollToCurrentNodeOnce(using: proxy) }
            .confirmationDialog(language.text("앞 레슨부터 해 볼까요?", "Start with an earlier lesson?"),
                                isPresented: Binding(get: { early != nil }, set: { if !$0 { early = nil } }),
                                titleVisibility: .visible, presenting: early) { node in
                if let first = Curriculum.unfinishedGroundwork(for: node, in: model.state).first {
                    Button(language.text("‘\(learningNodeTitle(first, language: language))’부터",
                                         "Start with “\(learningNodeTitle(first, language: language))”")) { onOpenNode(first) }
                }
                Button(language.text("그래도 이 레슨 시작", "Open this lesson anyway")) { onOpenNode(node) }
                Button(language.text("취소", "Cancel"), role: .cancel) {}
            } message: { node in
                let count = Curriculum.unfinishedGroundwork(for: node, in: model.state).count
                Text(language.text("이 레슨은 앞의 레슨 \(count)개에서 배운 내용을 써요. 어느 쪽이든 고를 수 있어요.",
                                   "This lesson uses ideas from \(count) earlier lessons. You can pick either way."))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(language.text("전체 레슨", "All lessons")).font(GT.title(30)).foregroundStyle(GT.onFelt)
            Text(language.text("짧은 트랙 네 개예요. 추천 순서대로 가도 되고, 어떤 레슨이든 바로 열 수 있어요.", "Four short tracks. Follow the suggested order, or open any lesson you like."))
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
                    .frame(width: 36, height: 36, alignment: .leading)
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
            .gtInset(GT.Space.card).frame(maxWidth: .infinity, alignment: .leading)
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
                    .frame(width: 36, height: 36, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.text("홀덤 기초", "Hold'em basics")).font(GT.title(17)).foregroundStyle(GT.onFelt)
                    Text(language.text("족보와 확인 문제", "Hand ranks and a quick check"))
                        .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(GT.onFeltSecondary)
            }
            .gtInset(GT.Space.card).frame(maxWidth: .infinity, alignment: .leading)
            .gtPanel().contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityValue(done ? language.text("완료", "Completed") : "")
        .accessibilityIdentifier("path-basics")
    }

    private func trackSection(_ track: LearningTrack) -> some View {
        let cleared = track.lessons.filter { model.state.nodes[$0.id]?.cleared == true }.count
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(track.id.title(in: language)).font(GT.title(21)).foregroundStyle(GT.onFelt)
                Spacer(minLength: 8)
                Text("\(cleared)/\(track.lessons.count)")
                    .font(GT.semibold(13).monospacedDigit()).foregroundStyle(GT.onFeltSecondary)
                    .accessibilityLabel(language.text("\(track.lessons.count)개 중 \(cleared)개 통과",
                                                      "\(cleared) of \(track.lessons.count) passed"))
            }
            Text(track.id.blurb(in: language)).font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4).padding(.bottom, 6)
            ForEach(track.lessons, id: \.id) { nodeRow($0) }
            if let challenge = track.challenge { nodeRow(challenge, challenge: true) }
        }
        .padding(.top, 12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("track-\(track.id.rawValue)")
    }

    private func scrollToCurrentNodeOnce(using proxy: ScrollViewProxy) {
        guard !didScrollToCurrentNode, let node = currentNode
        else { return }
        didScrollToCurrentNode = true
        // Defer the one initial scroll until layout has produced the row; subsequent
        // renders do not move the learner away from where they scrolled.
        DispatchQueue.main.async {
            proxy.scrollTo(node.id, anchor: .center)
        }
    }

    private var currentNode: CurriculumNode? { model.nextNode }

    /// Finished, suggested next, or simply open. Nothing on the tracks is ever locked.
    private func status(of node: CurriculumNode) -> NodeStatus {
        if model.state.nodes[node.id]?.cleared == true { return .cleared }
        return node == currentNode ? .available : .locked
    }

    private func nodeRow(_ node: CurriculumNode, challenge: Bool = false) -> some View {
        let status = status(of: node)
        let names = Curriculum.taughtConcept(of: node).map { skillNames($0, language: language, termsLead: termsLead) }
        let title = names?.lead ?? learningNodeTitle(node, language: language)
        // Each track can be started on its own, so its first lesson says so until done.
        let startsTrack = status != .cleared
            && Curriculum.tracks.contains { !$0.isOptional && $0.lessons.first == node }
        let tag = challenge ? language.text("선택 도전 · 섞어 풀기", "Optional challenge · mixed")
            : names.map {
                // In plain-words mode the tag is the poker term, so it is labelled as one.
                let tag = termsLead ? $0.tag : language.text("용어: \($0.tag)", "Term: \($0.tag)")
                return startsTrack ? language.text("여기서 시작 · \(tag)", "Start here · \(tag)") : tag
            }
        // Tried but under the pass mark: no check, and the best run so far.
        let notPassed = status == .cleared ? nil : model.state.nodes[node.id]?.best.map {
            language.text("통과 전 · 최고 \($0.right)/\($0.questions)",
                          "Not passed · best \($0.right)/\($0.questions)")
        }
        return Button {
            if status != .cleared, !Curriculum.unfinishedGroundwork(for: node, in: model.state).isEmpty {
                early = node
            } else {
                onOpenNode(node)
            }
        } label: {
            HStack(spacing: 13) {
                badge(status: status, boss: challenge)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(GT.title(status == .available ? 17 : 15))
                        .foregroundStyle(GT.onFelt)
                    if let tag {
                        Text(tag).font(GT.semibold(12)).foregroundStyle(GT.mint)
                    }
                    if let notPassed {
                        Text(notPassed).font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                    }
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
        .accessibilityLabel("\(title), \(tag.map { $0 + ", " } ?? "")\(statusLabel(status))"
                            + (notPassed.map { ", \($0)" } ?? "")
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
        case .cleared: return language.text("통과", "Passed")
        case .available: return language.text("추천 순서", "Suggested next")
        case .locked: return language.text("언제든 시작", "Available anytime")
        }
    }

    private func practiceLabel(_ node: CurriculumNode) -> String? {
        guard let concept = Curriculum.taughtConcept(of: node) else { return nil }
        let record = model.record(for: concept)
        guard record.total > 0 else { return nil }
        switch record.tier {
        case .attempted: return language.text("막 시작", "Just started")
        case .familiar: return language.text("익히는 중", "Getting familiar")
        case .proficient: return language.text("능숙 단계", "Practiced")
        case .mastered: return language.text("숙달 단계", "Mixed checks passed")
        }
    }
}
