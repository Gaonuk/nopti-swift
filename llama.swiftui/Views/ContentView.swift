import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ConversationViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                if let suggestion = viewModel.suggestion {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Suggested Content:")
                            .font(.headline)
                        
                        Text(suggestion)
                            .font(.body)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding()
                }
                
                if let error = viewModel.error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else if let content = viewModel.content {
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
        .task {
            await viewModel.loadContent()
        }
    }
} 