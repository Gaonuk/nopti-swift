import SwiftUI

struct ContentWorkflowView: View {
    @StateObject private var viewModel = ConversationViewModel()
    @State private var userInput: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task {
                            await viewModel.loadContent()
                        }
                    }
                } else {
                    List {
                        ForEach(viewModel.content) { item in
                            ContentItemView(content: item)
                        }
                    }
                    
                    // Workflow Input
                    VStack {
                        TextField("Enter your query", text: $userInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        Button("Execute Workflow") {
                            Task {
                                await viewModel.executeWorkflow(input: userInput)
                            }
                        }
                        .disabled(userInput.isEmpty)
                    }
                    
                    if let result = viewModel.workflowResult {
                        Text(result)
                            .padding()
                    }
                }
            }
            .navigationTitle("Content")
            .toolbar {
                Button("Reset") {
                    Task {
                        await viewModel.resetContent()
                    }
                }
            }
        }
        .task {
            await viewModel.loadContent()
        }
    }
} 