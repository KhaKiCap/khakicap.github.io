import SwiftUI

struct FeedbackEditorView: View {
    let athleteId: UUID
    let sessionId: UUID
    let currentTimestamp: Double

    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var category: FeedbackCategory = .general

    var isValid: Bool { !text.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("시점") {
                    HStack {
                        Image(systemName: "clock").foregroundStyle(.secondary)
                        Text(formatTimestamp(currentTimestamp))
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                        Text("현재 재생 시점")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("카테고리") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 10) {
                        ForEach(FeedbackCategory.allCases, id: \.self) { cat in
                            CategoryChip(category: cat, isSelected: category == cat) {
                                category = cat
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("내용") {
                    TextField("이 시점에 대한 피드백을 입력하세요", text: $text, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
            }
            .navigationTitle("피드백 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        let item = FeedbackItem(
                            timestamp: currentTimestamp,
                            text: text.trimmingCharacters(in: .whitespaces),
                            category: category
                        )
                        store.addFeedback(item, sessionId: sessionId, athleteId: athleteId)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func formatTimestamp(_ seconds: Double) -> String {
        String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }
}

struct CategoryChip: View {
    let category: FeedbackCategory
    let isSelected: Bool
    let action: () -> Void

    var chipColor: Color {
        switch category {
        case .general: return .gray
        case .positive: return .yellow
        case .improvement: return .blue
        case .technique: return .green
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.systemImage).font(.caption)
                Text(category.rawValue).font(.subheadline.bold())
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? chipColor.opacity(0.2) : Color(.systemGray6))
            .foregroundStyle(isSelected ? chipColor : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? chipColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
