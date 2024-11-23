@MainActor
class ConversationViewModel: ObservableObject {
    @Published var content: [Content] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var workflowResult: String?
    
    func loadContent() async {
        isLoading = true
        do {
            content = try await NetworkManager.shared.fetchContent()
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
            workflowResult = response.result
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
} 