import Foundation
import SwiftUI
import Combine

// MARK: - Auth Manager
/// Handles user authentication state, API base URL configuration,
/// and persistence of user ID via UserDefaults.
class AuthManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let userId = "lekovka_user_id"
        static let userEmail = "lekovka_user_email"
    }
    
    // MARK: - API Base URL (change this to point to your server)
    static let apiBaseURL = "http://3.65.52.122:8080/api/v1"
    
    // MARK: - Computed Properties
    
    /// The persisted user ID (nil if not logged in).
    var userId: String? {
        UserDefaults.standard.string(forKey: Keys.userId)
    }
    
    /// The persisted user email.
    var userEmail: String? {
        UserDefaults.standard.string(forKey: Keys.userEmail)
    }
    
    // MARK: - Initialization
    init() {
        // Check if a user ID already exists → skip login
        isLoggedIn = userId != nil
    }
    
    // MARK: - Login
    /// Sends POST /users with the email and persists the returned user ID.
    func login(email: String) {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let baseURL = Self.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/users") else {
            isLoading = false
            errorMessage = "Invalid API URL"
            return
        }
        
        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Connection error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid server response"
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    self.errorMessage = "Server error (HTTP \(httpResponse.statusCode))"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                // Parse the user ID and settings from the response
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        
                        // Parse user settings if present
                        if let notifyMins = json["notify_after_minutes"] as? Int {
                            UserDefaults.standard.set(notifyMins, forKey: "lekovka_notify_after_minutes")
                        }
                        if let notifyRetries = json["notify_caregivers_after_retries"] as? Int {
                            UserDefaults.standard.set(notifyRetries, forKey: "lekovka_notify_caregivers_after_retries")
                        }
                        
                        // Parse user ID
                        if let id = json["id"] {
                            let userIdString = "\(id)"
                            self.persistLogin(userId: userIdString, email: email)
                        } else {
                            self.errorMessage = "Could not parse user ID from response"
                        }
                    } else {
                        self.errorMessage = "Could not parse JSON response"
                    }
                } catch {
                    self.errorMessage = "Response parse error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // MARK: - Persistence
    private func persistLogin(userId: String, email: String) {
        UserDefaults.standard.set(userId, forKey: Keys.userId)
        UserDefaults.standard.set(email, forKey: Keys.userEmail)
        withAnimation(.easeInOut(duration: 0.4)) {
            isLoggedIn = true
        }
    }
    
    /// Logs out the user by clearing persisted data.
    func logout() {
        UserDefaults.standard.removeObject(forKey: Keys.userId)
        UserDefaults.standard.removeObject(forKey: Keys.userEmail)
        withAnimation(.easeInOut(duration: 0.4)) {
            isLoggedIn = false
        }
    }
}
