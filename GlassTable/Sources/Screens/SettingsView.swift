// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UniformTypeIdentifiers
import GlassTableDrills

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProgressionModel.self) private var model
    @State private var showGlossary = false
    @State private var showGuide = false
    @State private var showLicense = false
    @State private var backup: BackupDocument?
    @State private var exportingBackup = false
    @State private var importingBackup = false
    @State private var pendingImport: PreparedProgressImport?
    @State private var importTask: Task<Void, Never>?
    @State private var importRequestID: UUID?
    @State private var isReadingImport = false
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
                    Button { showGuide = true } label: {
                        row("rectangle.stack", "시작 안내", "게임의 흐름과 공부하는 방법", chevron: true)
                    }
                    .buttonStyle(GTPress())
                    Divider().padding(.leading, 56)
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
                            "진행 기록을 파일로 보관해요", chevron: true)
                    }
                    .buttonStyle(GTPress())
                    Divider().padding(.leading, 56)
                    // Without this row a backup was write-only: the recovery importer
                    // only appears once the store is *corrupt*, so a healthy reset or
                    // a new phone had no way back in — review finding on e059ec6.
                    Button {
                        pendingImport = nil
                        importingBackup = true
                    } label: {
                        row("square.and.arrow.down", "백업 불러오기",
                            isReadingImport ? "파일을 확인하고 있어요" : "저장한 파일에서 기록을 가져와요",
                            chevron: true)
                    }
                    .buttonStyle(GTPress())
                    .disabled(isReadingImport)
                    .fileImporter(isPresented: $importingBackup,
                                  allowedContentTypes: [.json]) { result in
                        switch result {
                        case let .success(url):
                            readImport(url)
                        case let .failure(error):
                            if !ProgressFileFailure.isCancellation(error) {
                                fileFailure = .read
                            }
                        }
                    }
                    .confirmationDialog("지금 기록을 백업 내용으로 바꿀까요?",
                                        isPresented: $confirmingImport,
                                        titleVisibility: .visible) {
                        Button("백업으로 바꾸기", role: .destructive) {
                            // Replacement is atomic; an unsuccessful write lands
                            // in the alert, never in a half-replaced store.
                            if let prepared = pendingImport {
                                do { try model.importPrepared(prepared) }
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
                    .disabled(isReadingImport)
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
                    Button { showLicense = true } label: {
                        row("doc.plaintext", "오픈소스 라이선스", "Pretendard · FSRS", chevron: true)
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
        .sheet(isPresented: $showGuide) { NavigationStack { LearningGuideView() } }
        .sheet(isPresented: $showLicense) { NavigationStack { OpenSourceLicenseView() } }
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
        .onDisappear {
            importRequestID = nil
            importTask?.cancel()
            importTask = nil
        }
        .onAppear {
            #if DEBUG
            // GT_DEMO_SETTINGS=1 GT_DEMO_GLOSSARY=1 — same reason as every other hook:
            // synthetic taps never reach Simulator content.
            if ProcessInfo.processInfo.environment["GT_DEMO_GLOSSARY"] != nil {
                showGlossary = true
            }
            if ProcessInfo.processInfo.environment["GT_DEMO_GUIDE"] != nil {
                showGuide = true
            }
            #endif
        }
        // Leading, like every other 닫기 — it used to sit trailing, so dismissing a sheet
        // meant looking in a different corner depending on which sheet you were in.
        .gtChrome(.topBarLeading) { ChromeButton.close { dismiss() } }
    }

    private func readImport(_ url: URL) {
        importTask?.cancel()
        let requestID = UUID()
        importRequestID = requestID
        isReadingImport = true
        importTask = Task {
            do {
                let prepared = try await ProgressFileReader.readAndValidate(url)
                guard importRequestID == requestID else { return }
                pendingImport = prepared
                confirmingImport = true
            } catch {
                guard importRequestID == requestID,
                      !ProgressFileFailure.isCancellation(error) else { return }
                fileFailure = error is StoreError ? .importing(error) : .read
            }
            guard importRequestID == requestID else { return }
            isReadingImport = false
            importTask = nil
        }
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

private struct OpenSourceLicenseView: View {
    @Environment(\.dismiss) private var dismiss
    private func license(named name: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "라이선스 문서를 열 수 없어요. 설정의 피드백으로 알려주세요."
        }
        return text
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("오픈소스 라이선스").font(GT.title(26)).foregroundStyle(GT.onFelt)
                Text("Pretendard").font(GT.semibold(17)).foregroundStyle(GT.onFelt)
                Text(license(named: "Pretendard-LICENSE"))
                    .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                    .textSelection(.enabled)
                Text("FSRS").font(GT.semibold(17)).foregroundStyle(GT.onFelt)
                Text(license(named: "FSRS-LICENSE"))
                    .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                    .textSelection(.enabled)
            }.padding(24)
        }
        .background(FeltBackground())
        .gtChrome(.topBarLeading) { ChromeButton.close { dismiss() } }
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
