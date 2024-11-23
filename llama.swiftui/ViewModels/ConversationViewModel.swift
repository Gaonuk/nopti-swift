@MainActor
class ConversationViewModel: ObservableObject {
    @Published var content: [Content] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var suggestion: String?
    
    func loadContent() async {
        isLoading = true
        do {
            content = try await NetworkManager.shared.fetchContent()
            suggest()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func executeWorkflow(input: String) async {
        isLoading = true
        do {
            let response = try await NetworkManager.shared.executeWorkflow(input: input)
            suggest()
            // workflowResult = response.result
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func resetContent() async {
        isLoading = true
        do {
            try await NetworkManager.shared.resetContent()
            content = []
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func suggest() {
        guard !content.isEmpty else {
            suggestion = nil
            return
        }
        
        suggestion = content[0].title
    }
} 