// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

struct GlossaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.learningLanguage) private var language
    @State private var selectedID: String?
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    init(focus: String? = nil) {
        _selectedID = State(initialValue: focus.flatMap { GlossaryCatalog.entry(for: $0)?.id })
    }

    static func displayName(for term: String, language: LearningLanguage) -> String {
        GlossaryCatalog.entry(for: term)?.name.text(in: language) ?? term
    }

    private var selected: GlossaryEntry? {
        selectedID.flatMap { GlossaryCatalog.entry(for: $0) }
    }

    var body: some View {
        Group {
            if let selected { detail(selected) }
            else { list }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FeltBackground())
        .gtChrome(leading: {
            ChromeButton.close { dismiss() }
                .accessibilityIdentifier("glossary-close")
        })
        .gtSheetSurface()
    }

    private func names(_ entry: GlossaryEntry, titleSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.name.text(in: language))
                .font(GT.title(titleSize)).foregroundStyle(GT.onFelt)
            Text(language == .korean ? entry.name.english : entry.name.korean)
                .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func detail(_ entry: GlossaryEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(language.text("용어집", "Glossary"))
                    .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                names(entry, titleSize: 28)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("glossary-detail-\(entry.id)")
                Text(entry.meaning.text(in: language))
                    .font(GT.body(18)).foregroundStyle(GT.onFelt)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("glossary-definition-\(entry.id)")
                Button {
                    selectedID = nil
                } label: {
                    Text(language.text("전체 용어 검색", "Search all terms"))
                }
                .buttonStyle(GTOutlinedAction(fills: true))
                .accessibilityIdentifier("glossary-all")
            }
            .gtContentEdge()
        }
        .accessibilityIdentifier("glossary-detail-scroll")
        .id(entry.id)
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(language.text("용어집", "Glossary"))
                    .font(GT.title(28)).foregroundStyle(GT.onFelt)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(GT.onFeltSecondary)
                    TextField(language.text("한국어·영어·약어 검색", "Search Korean, English or abbreviations"), text: $query)
                        .font(GT.body(16)).foregroundStyle(GT.onFelt)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .submitLabel(.search).focused($searchFocused)
                        .onSubmit { searchFocused = false }
                        .accessibilityIdentifier("glossary-search")
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(GT.onFeltSecondary).frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(GTPress())
                        .accessibilityLabel(language.text("검색어 지우기", "Clear search"))
                        .accessibilityIdentifier("glossary-clear")
                    }
                }
                .padding(.horizontal, 12).frame(minHeight: 52)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control))
                .overlay(RoundedRectangle(cornerRadius: GT.Radius.control)
                    .strokeBorder(GT.borderStrong, lineWidth: 1))
            }
            .padding(.horizontal, GT.Space.edge).padding(.top, 18).padding(.bottom, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    let results = GlossaryCatalog.search(query)
                    if results.isEmpty {
                        Text(language.text("맞는 용어가 없어요", "No matching terms"))
                            .font(GT.title(20)).foregroundStyle(GT.onFelt)
                            .padding(.bottom, 8)
                        Text(language.text("다른 한국어·영어 이름이나 약어로 찾아보세요", "Try another Korean or English name, or an abbreviation"))
                            .font(GT.body(16)).foregroundStyle(GT.onFeltSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("glossary-no-results")
                    } else {
                        ForEach(results) { entry in
                            Button {
                                searchFocused = false
                                selectedID = entry.id
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    names(entry, titleSize: 18)
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                                .padding(.vertical, 10).contentShape(Rectangle())
                            }
                            .buttonStyle(GTPress())
                            .accessibilityIdentifier("glossary-entry-\(entry.id)")
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, GT.Space.edge).padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .accessibilityIdentifier("glossary-list")
            .id(query)
        }
    }
}

#Preview { GlossaryView() }
