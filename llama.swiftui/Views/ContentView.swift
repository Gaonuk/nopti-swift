import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = UserContentViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let content = viewModel.userContent {
                List(content, id: \.link) { item in
                    VStack(alignment: .leading) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.summary)
                            .font(.subheadline)
                        Text(item.source)
                            .font(.caption)
                    }
                }
            }
        }
    }
} 