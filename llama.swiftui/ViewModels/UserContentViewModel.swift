import Foundation

@MainActor
class UserContentViewModel: ObservableObject {
    @Published var userContent: [Content]? = nil
    @Published var isLoading: Bool = true
    @Published var error: String? = nil
    
    init() {
        loadData()
    }
    
    func loadData() {
        Task {
            do {
                isLoading = true
                let response = try await NetworkManager.shared.fetchUserContent()
                userContent = response
                error = nil
            } catch {
                error = error.localizedDescription
            }
            isLoading = false
        }
    }
} 