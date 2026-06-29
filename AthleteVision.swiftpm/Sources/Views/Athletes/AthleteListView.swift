import SwiftUI

struct AthleteListView: View {
    @EnvironmentObject private var store: DataStore
    @State private var searchText = ""
    @State private var showingAdd = false

    var filtered: [Athlete] {
        guard !searchText.isEmpty else { return store.athletes }
        return store.athletes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.sport.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.athletes.isEmpty {
                    EmptyStateView(
                        title: "선수 없음",
                        systemImage: "person.2.slash",
                        description: "+ 버튼으로 선수를 추가하세요"
                    )
                } else {
                    List {
                        ForEach(filtered) { athlete in
                            NavigationLink(destination: AthleteDetailView(athleteId: athlete.id)) {
                                AthleteRowView(athlete: athlete)
                            }
                        }
                        .onDelete { offsets in
                            offsets.forEach { store.deleteAthlete(id: filtered[$0].id) }
                        }
                    }
                    .searchable(text: $searchText, prompt: "이름 또는 종목 검색")
                }
            }
            .navigationTitle("선수 관리")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddAthleteView()
            }
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
                    .foregroundColor(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(athlete.name).font(.headline)
                HStack(spacing: 4) {
                    Text(athlete.sport).font(.subheadline).foregroundColor(.secondary)
                    if !athlete.position.isEmpty {
                        Text("· \(athlete.position)").font(.subheadline).foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(athlete.sessions.count)")
                    .font(.title3.bold()).foregroundColor(Color.accentColor)
                Text("영상").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
