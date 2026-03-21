import Foundation
import Combine

// MARK: - API Service
/// Handles all external API communication for the Lekovka app.
class APIService: ObservableObject {
    
    @Published var response: String = ""
    @Published var isLoading: Bool = false
    
    // MARK: - Report Pills Taken
    /// Reports to the external API that the user has taken their pills.
    func reportPillsTaken(name: String) {
        isLoading = true
        response = ""
        
        // TODO: Replace with your actual API endpoint
        guard let url = URL(string: "https://official-joke-api.appspot.com/random_joke") else { return }
        
        // Build the request body
        let body: [String: Any] = [
            "name": name,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "action": "pills_taken"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET" // TODO: Change to POST when using real API
        // request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        // request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.response = "❌ Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.response = "❌ No data received"
                    return
                }
                
                // For now, show the joke API response as confirmation
                // TODO: Parse your real API response here
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let setup = json["setup"] as? String,
                       let punchline = json["punchline"] as? String {
                        self.response = "✅ Pills reported for \(name)!\n\nFun fact while you wait:\n\(setup)\n\(punchline) 😂"
                    } else {
                        self.response = "✅ Pills reported successfully for \(name)!"
                    }
                } catch {
                    self.response = "✅ Reported! (Parse note: \(error.localizedDescription))"
                }
            }
        }.resume()
    }
    
    // MARK: - Fetch Friend Notifications
    /// Fetches notifications of other people who have taken their pills.
    func fetchFriendNotifications(completion: @escaping ([(name: String, time: Date, message: String)]) -> Void) {
        // TODO: Replace with real API endpoint
        // For now, returns mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion([])
        }
    }
}
