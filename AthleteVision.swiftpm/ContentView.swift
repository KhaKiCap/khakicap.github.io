import SwiftUI

struct ContentView: View {
    var body: some View {
        AthleteListView()
    }
}

// MARK: - Shared empty state

struct PlaceholderView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            Text(title).font(.title3.bold())
            Text(subtitle).font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
