import SwiftUI

struct AddAthleteView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var sport = ""
    @State private var position = ""
    @State private var note = ""

    var isValid: Bool { !name.isEmpty && !sport.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("이름 *", text: $name)
                    TextField("종목 * (예: 축구, 농구, 야구)", text: $sport)
                    TextField("포지션 (예: 공격수)", text: $position)
                }
                Section("메모") {
                    TextField("특이사항 또는 목표", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("선수 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        store.addAthlete(name: name, sport: sport, position: position, note: note)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
