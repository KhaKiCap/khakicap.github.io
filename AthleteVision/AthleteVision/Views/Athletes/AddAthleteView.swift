import SwiftUI
import SwiftData

struct AddAthleteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var sport = ""
    @State private var position = ""
    @State private var profileNote = ""

    private var isValid: Bool { !name.isEmpty && !sport.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("이름 *", text: $name)
                    TextField("종목 * (예: 축구, 농구)", text: $sport)
                    TextField("포지션 (예: 공격수)", text: $position)
                }

                Section("메모") {
                    TextField("선수 특이사항 또는 목표", text: $profileNote, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
            }
            .navigationTitle("선수 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") { saveAthlete() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func saveAthlete() {
        let athlete = Athlete(
            name: name,
            sport: sport,
            position: position,
            profileNote: profileNote
        )
        modelContext.insert(athlete)
        dismiss()
    }
}
