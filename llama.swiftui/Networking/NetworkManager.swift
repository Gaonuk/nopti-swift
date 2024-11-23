import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://nopti-ee349d72e62a.herokuapp.com"
    
    private init() {}
    
    // Fetch content
    func fetchContent() async throws -> [Content] {
        guard let url = URL(string: "\(baseURL)/content") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError("Failed to fetch content")
        }
        
        return try JSONDecoder().decode([Content].self, from: data)
    }
    
    // AI Workflow
    func executeWorkflow(input: String) async throws -> WorkflowResponse {
        guard let url = URL(string: "\(baseURL)/workflow") else {
            throw NetworkError.invalidURL
        }
        
        let inputUser = InputUser(input: input)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(inputUser)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError("Workflow failed")
        }
        
        return try JSONDecoder().decode(WorkflowResponse.self, from: data)
    }
    
    // Reset content
    func resetContent() async throws {
        guard let url = URL(string: "\(baseURL)/reset") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError("Reset failed")
        }
    }
} 