import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AthleteListView()
                .tabItem {
                    Label("선수", systemImage: "person.2.fill")
                }
        }
    }
}
