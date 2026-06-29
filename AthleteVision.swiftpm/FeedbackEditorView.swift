import SwiftUI

struct FeedbackEditorView: View {
    let athleteId: UUID
    let sessionId: UUID
    let currentTimestamp: Double
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var category: FeedbackCategory = .general

    var body: some View {
        NavigationStack {
            Form {
                Section("시점") {
                    HStack {
                        Image(systemName: "clock").foregroundColor(.secondary)
                        Text(fmt(currentTimestamp))
                            .font(.system(.body, design: .monospaced).bold()).foregroundColor(.accentColor)
                        Spacer()
                        Text("현재 재생 시점").font(.caption).foregroundColor(.secondary)
                    }
                }

                Section("카테고리") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 10) {
                        ForEach(FeedbackCategory.allCases, id: \.self) { cat in
                            Button {
                                category = cat
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: cat.systemImage).font(.caption)
                                    Text(cat.rawValue).font(.subheadline.bold())
                                }
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(category == cat ? cat.color.opacity(0.2) : Color(.systemGray6))
                                .foregroundColor(category == cat ? cat.color : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(category == cat ? cat.color : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("내용") {
                    TextField("피드백 내용을 입력하세요", text: $text, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
            }
            .navigationTitle("피드백 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        store.addFeedback(
                            FeedbackItem(timestamp: currentTimestamp,
                                         text: text.trimmingCharacters(in: .whitespaces),
                                         category: category),
                            sessionId: sessionId, athleteId: athleteId
                        )
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func fmt(_ s: Double) -> String {
        String(format: "%d:%02d", Int(s) / 60, Int(s) % 60)
    }
}
