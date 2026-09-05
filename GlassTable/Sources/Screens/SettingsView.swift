// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProgressionModel.self) private var model
    @State private var showGlossary = false
    @State private var backup: BackupDocument?
    @State private var exportingBackup = false
    @State private var importingBackup = false
    @State private var pendingImport: Data?
    @State private var confirmingImport = false
    @State private var fileFailure: ProgressFileFailure?
    @State private var confirmingReset = false
    private static let privacyURL =
        URL(string: "https://mhju0.github.io/glass-table/privacy-policy.html")!
    private static let feedbackURL =
        URL(string: "mailto:michaelju0418@gmail.com?subject=Glass%20Table%20%ED%94%BC%EB%93%9C%EB%B0%B1")!
    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("설정").font(GT.title(26)).foregroundStyle(GT.onFelt)
                    .padding(.top, 20)
                VStack(spacing: 0) {
                    // A sheet, not a push — the same way the 용어 chip in a reveal opens
                    // it. Pushing gave the glossary a system back button, the one piece
                    // of chrome the app cannot draw itself.
                    Button { showGlossary = true } label: {
                        row("book.fill", "용어집", "포커 용어 한국어·영어 정리", chevron: true)
                    }
                    .buttonStyle(GTPress())
                    // 통계 and 첫 핸드 are gone. StatsView read the M1 per-drill stores
                    // that nothing writes any more, and 첫 핸드 is superseded by first
                    // run — 천천히 replays any concept's walkthrough on demand instead.
                }
                .gtCard(radius: 20)
                VStack(spacing: 0) {
                    // The store file *is* the export format (spec §8.1). Without this
                    // row the recovery screen's 백업 불러오기 asks for a file the user
                    // never had a way to create.
                    Button {
                        do {
                            backup = BackupDocument(try model.exportData())
                            exportingBackup = true
                        } catch { fileFailure = .export }
                    } label: {
                        row("square.and.arrow.up", "백업 만들기",
                            "진행 기록을 JSON 파일로 저장", chevron: true)
                    }
                    .buttonStyle(GTPress())
                    Divider().padding(.leading, 56)
                    // Without this row a backup was write-only: the recovery importer
                    // only appears once the store is *corrupt*, so a healthy reset or
                    // a new phone had no way back in — review finding on e059ec6.
                    Button { importingBackup = true } label: {
                        row("square.and.arrow.down", "백업 불러오기",
                            "백업 JSON으로 기록을 되돌려요", chevron: true)
                    }
                    .buttonStyle(GTPress())
                    .fileImporter(isPresented: $importingBackup,
                                  allowedContentTypes: [.json]) { result in
                        guard case let .success(url) = result else {
                            fileFailure = .read
                            return
                        }
                        let scoped = url.startAccessingSecurityScopedResource()
                        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                        do {
                            pendingImport = try Data(contentsOf: url)
                            confirmingImport = true
                        } catch { fileFailure = .read }
                    }
                    .confirmationDialog("지금 기록을 백업 내용으로 바꿀까요?",
                                        isPresented: $confirmingImport,
                                        titleVisibility: .visible) {
                        Button("백업으로 바꾸기", role: .destructive) {
                            // importData validates before replacing; a bad file lands
                            // in the alert, never in a half-replaced store.
                            if let data = pendingImport {
                                do { try model.importData(data) }
                                catch { fileFailure = .importing(error) }
                            }
                            pendingImport = nil
                        }
                        Button("취소", role: .cancel) { pendingImport = nil }
                    } message: {
                        Text("지금까지의 진행이 백업 시점의 기록으로 돌아가요.")
                    }
                    Divider().padding(.leading, 56)
                    Button { confirmingReset = true } label: {
                        row("arrow.counterclockwise", "진행 초기화",
                            "모든 기록을 지우고 처음부터", chevron: true, destructive: true)
                    }
                    .buttonStyle(GTPress())
                }
                .gtCard(radius: 20)
                VStack(spacing: 0) {
                    Link(destination: Self.feedbackURL) {
                        row("envelope.fill", "피드백 보내기", "버그·아이디어를 메일로",
                            chevron: false, external: true)
                    }
                    .buttonStyle(GTPress())
                    Divider().padding(.leading, 56)
                    Link(destination: Self.privacyURL) {
                        // arrow.up.right = leaves the app (Safari), unlike chevron rows.
                        row("doc.text", "개인정보 처리방침", nil, chevron: false, external: true)
                    }
                    .buttonStyle(GTPress())
                    Divider().padding(.leading, 56)
                    HStack(spacing: 14) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(GT.green).frame(width: 28)
                        Text("버전").font(GT.semibold(15)).foregroundStyle(GT.ink)
                        Spacer()
                        Text(version).font(GT.body(14)).foregroundStyle(GT.inkMuted)
                            .monospacedDigit()
                    }
                    .padding(16)
                }
                .gtCard(radius: 20)
            }
            .padding(.horizontal, 18)
        }
        .background(FeltBackground())
        .sheet(isPresented: $showGlossary) { GlossaryView() }
        .fileExporter(isPresented: $exportingBackup, document: backup,
                      contentType: .json,
                      defaultFilename: "glass-table-backup") { result in
            backup = nil
            if case let .failure(error) = result,
               (error as NSError).code != NSUserCancelledError {
                fileFailure = .export
            }
        }
        // 백업 만들기 + 백업 불러오기 make the advice real: a backup taken before this
        // genuinely restores from Settings, not only via the corrupt-store screen.
        .confirmationDialog("모든 진행 기록을 지울까요?", isPresented: $confirmingReset,
                            titleVisibility: .visible) {
            Button("전부 지우고 처음부터", role: .destructive) {
                do { try model.resetProgress() }
                catch { fileFailure = .reset }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("되돌릴 수 없어요. 남겨두고 싶으면 먼저 백업을 만들어 두세요.")
        }
        .alert(item: $fileFailure) { failure in
            Alert(title: Text("기록 파일을 처리하지 못했어요"), message: Text(failure.message),
                  dismissButton: .default(Text("확인")))
        }
        .onAppear {
            #if DEBUG
            // GT_DEMO_SETTINGS=1 GT_DEMO_GLOSSARY=1 — same reason as every other hook:
            // synthetic taps never reach Simulator content.
            if ProcessInfo.processInfo.environment["GT_DEMO_GLOSSARY"] != nil {
                showGlossary = true
            }
            #endif
        }
        // Leading, like every other 닫기 — it used to sit trailing, so dismissing a sheet
        // meant looking in a different corner depending on which sheet you were in.
        .gtChrome(.topBarLeading) { ChromeButton.close { dismiss() } }
    }

    private func row(_ icon: String, _ title: String, _ sub: String?,
                     chevron: Bool, external: Bool = false,
                     destructive: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                .foregroundStyle(destructive ? GT.suitRed : GT.green).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(GT.semibold(15)).foregroundStyle(GT.ink)
                if let sub { Text(sub).font(GT.body(12)).foregroundStyle(GT.inkMuted) }
            }
            Spacer()
            if chevron || external {
                Image(systemName: external ? "arrow.up.right" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GT.inkMuted)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}

/// Wraps the store's bytes for `fileExporter`. Write-only — reading a backup happens
/// through the fileImporters (Settings row, recovery screen), not through this type.
private struct BackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]
    let data: Data
    init(_ data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

#Preview { NavigationStack { SettingsView() } }
