import SwiftUI
import SwiftData

struct FeedbackEditorView: View {
    @Bindable var session: VideoSession
    let currentTimestamp: Double

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var feedbackText = ""
    @State private var selectedCategory: FeedbackCategory = .general
    @State private var customTimestamp: Double

    init(session: VideoSession, currentTimestamp: Double) {
        self.session = session
        self.currentTimestamp = currentTimestamp
        self._customTimestamp = State(initialValue: currentTimestamp)
    }

    private var isValid: Bool { !feedbackText.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("시점") {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text(formatTimestamp(customTimestamp))
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                        Text("현재 재생 시점")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("카테고리") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        ForEach(FeedbackCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("피드백 내용") {
                    TextField("이 시점에 대한 피드백을 입력하세요", text: $feedbackText, axis: .vertical)
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
                    Button("추가") { saveFeedback() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func saveFeedback() {
        let item = FeedbackItem(
            timestamp: customTimestamp,
            text: feedbackText.trimmingCharacters(in: .whitespaces),
            category: selectedCategory
        )
        session.feedbackItems.append(item)
        try? modelContext.save()
        dismiss()
    }

    private func formatTimestamp(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

struct CategoryChip: View {
    let category: FeedbackCategory
    let isSelected: Bool
    let action: () -> Void

    private var chipColor: Color {
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
                Image(systemName: category.systemImage)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.subheadline.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
