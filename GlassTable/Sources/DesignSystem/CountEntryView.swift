// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

/// Direct whole-number entry without a seeded guess. The in-sheet keypad keeps every
/// digit, deletion, and submit reachable at accessibility sizes without depending on a
/// software keyboard dismissal gesture.
struct CountEntryView: View {
    @Binding var entry: String
    let suffix: String
    let onSubmit: () -> Void
    @State private var isEditing = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 5)

    var body: some View {
        VStack(spacing: 9) {
            if isEditing {
                HStack(spacing: 8) {
                    Text(entry.isEmpty ? "숫자를 입력하세요" : "\(entry)\(suffix)")
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
                    .accessibilityLabel("마지막 숫자 지우기")
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
                        .accessibilityLabel("숫자 \(digit)")
                    }
                }
                SecondaryCTAButton(title: "입력 완료") { isEditing = false }
            } else {
                HStack(spacing: 10) {
                    Button { isEditing = true } label: {
                        Text(entry.isEmpty ? "답 입력" : "\(entry)\(suffix)")
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
                        Text("확인").font(GT.title(GT.Typography.buttonSize))
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
        // Count drills ask about outs or one hand class's remaining combinations;
        // neither answer can reach four digits.
        guard entry.count < 3 else { return }
        if entry == "0" { entry = "\(digit)" }
        else { entry.append(String(digit)) }
    }

    private func deleteLast() {
        guard !entry.isEmpty else { return }
        entry.removeLast()
    }
}
