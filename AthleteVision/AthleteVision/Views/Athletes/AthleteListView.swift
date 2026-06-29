import SwiftUI
import SwiftData

struct AthleteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Athlete.name) private var athletes: [Athlete]
    @State private var showingAddAthlete = false
    @State private var searchText = ""

    var filteredAthletes: [Athlete] {
        guard !searchText.isEmpty else { return athletes }
        return athletes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.sport.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if athletes.isEmpty {
                    ContentUnavailableView(
                        "선수 없음",
                        systemImage: "person.2.slash",
                        description: Text("우측 상단 + 버튼으로 선수를 추가하세요")
                    )
                } else {
                    List {
                        ForEach(filteredAthletes) { athlete in
                            NavigationLink(destination: AthleteDetailView(athlete: athlete)) {
                                AthleteRowView(athlete: athlete)
                            }
                        }
                        .onDelete(perform: deleteAthletes)
                    }
                    .searchable(text: $searchText, prompt: "이름 또는 종목 검색")
                }
            }
            .navigationTitle("선수 관리")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAthlete = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAthlete) {
                AddAthleteView()
            }
        }
    }

    private func deleteAthletes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredAthletes[index])
        }
    }
}

struct AthleteRowView: View {
    let athlete: Athlete

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                Text(athlete.initials)
                    .font(.title3.bold())
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(athlete.name)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(athlete.sport)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !athlete.position.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(athlete.position)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(athlete.sessions.count)")
                    .font(.title3.bold())
                    .foregroundStyle(Color.accentColor)
                Text("영상")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
