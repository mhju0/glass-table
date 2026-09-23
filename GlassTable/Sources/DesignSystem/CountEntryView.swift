// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Direct whole-number entry without a seeded guess. The in-sheet keypad keeps every
/// digit, deletion, and submit reachable at accessibility sizes without depending on a
/// software keyboard dismissal gesture.
struct CountEntryView: View {
    @Environment(\.learningLanguage) private var language
    @Binding var entry: String
    let suffix: String
    let onSubmit: () -> Void
    var maximumDigits = 3
    var maximumValue = 999
    @State private var isEditing = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 5)

    var body: some View {
        VStack(spacing: 9) {
            if isEditing {
                HStack(spacing: 8) {
                    Text(entry.isEmpty ? language.text("숫자를 입력하세요", "Enter a number") : "\(entry)\(suffix)")
                        .font(GT.title(20).monospacedDigit())
                        .foregroundStyle(entry.isEmpty ? GT.inkMuted : GT.ink)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    Button(action: deleteLast) {
                        Image(systemName: "delete.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(GT.ink)
                            .frame(width: 48, height: 48)
                            .background(GT.surface,
                                        in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(GT.borderStrong, lineWidth: 1))
                    }
                    .buttonStyle(GTPress())
                    .disabled(entry.isEmpty)
                    .accessibilityLabel(language.text("마지막 숫자 지우기", "Delete last digit"))
                }

                LazyVGrid(columns: columns, spacing: 7) {
                    ForEach(0...9, id: \.self) { digit in
                        Button { append(digit) } label: {
                            Text("\(digit)")
                                .font(GT.semibold(18).monospacedDigit())
                                .foregroundStyle(GT.ink)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(GT.surface,
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(GT.borderStrong, lineWidth: 1))
                        }
                        .buttonStyle(GTPress())
                        .accessibilityLabel(language.text("숫자 \(digit)", "Digit \(digit)"))
                    }
                }
                SecondaryCTAButton(title: language.text("입력 완료", "Done entering")) { isEditing = false }
            } else {
                HStack(spacing: 10) {
                    Button { isEditing = true } label: {
                        Text(entry.isEmpty ? language.text("답 입력", "Enter answer") : "\(entry)\(suffix)")
                            .font(GT.title(18).monospacedDigit())
                            .foregroundStyle(entry.isEmpty ? GT.inkMuted : GT.ink)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(GT.surface,
                                        in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .strokeBorder(GT.borderStrong, lineWidth: 1))
                    }
                    .buttonStyle(GTPress())
                    Button(action: onSubmit) {
                        Text(language.text("확인", "Check answer")).font(GT.title(GT.Typography.buttonSize))
                            .foregroundStyle(entry.isEmpty ? GT.inkMuted : GT.onCTA)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(entry.isEmpty ? GT.surface : GT.cta,
                                        in: RoundedRectangle(cornerRadius: 15,
                                                             style: .continuous))
                    }
                    .buttonStyle(GTPress())
                    .disabled(entry.isEmpty)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func append(_ digit: Int) {
        guard entry.count < maximumDigits else { return }
        let candidate = entry == "0" ? "\(digit)" : entry + String(digit)
        guard let value = Int(candidate), value <= maximumValue else { return }
        entry = candidate
    }

    private func deleteLast() {
        guard !entry.isEmpty else { return }
        entry.removeLast()
    }
}
