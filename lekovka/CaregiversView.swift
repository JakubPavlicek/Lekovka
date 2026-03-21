import SwiftUI

// MARK: - Caregivers View
/// Email/Contact form for adding caregiver emails.
/// Sends POST /caregivers with { "emails": ["..."] } to notify
/// caregivers when the user misses their pills too many times.
struct CaregiversView: View {
    
    // MARK: - State
    @State private var emails: [String] = [""]
    @State private var isSubmitting: Bool = false
    @State private var submitResult: SubmitResult?
    @FocusState private var focusedFieldIndex: Int?
    
    enum SubmitResult: Equatable {
        case success
        case error(String)
    }
    
    // Gradient matching the app's warm accent
    private let accentGradient = LinearGradient(
        colors: [Color(hex: "f7971e"), Color(hex: "ffd200")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let cardColor = Color(hex: "1a1a2e")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Email List
                    emailListCard
                    
                    // MARK: - Add Button
                    addEmailButton
                    
                    // MARK: - Submit Button
                    submitButton
                    
                    // MARK: - Result Banner
                    if let result = submitResult {
                        resultBanner(result: result)
                    }
                    
                    // MARK: - Info Section
                    infoCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "0f0f1a").ignoresSafeArea())
            .navigationTitle("Caregivers")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow rings
                Circle()
                    .fill(Color(hex: "ffd200").opacity(0.06))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(accentGradient)
                    .frame(width: 90, height: 90)
                    .shadow(color: Color(hex: "ffd200").opacity(0.35), radius: 16, x: 0, y: 8)
                
                Image(systemName: "person.2.badge.gearshape.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.white)
            }
            
            Text("Caregiver Contacts")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Add emails of people who should be\nnotified when you miss your medication")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Email List Card
    private var emailListCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "envelope.badge.fill")
                    .foregroundColor(Color(hex: "ffd200"))
                Text("Email Addresses")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(validEmailCount)/\(emails.count)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "ffd200").opacity(0.7))
            }
            
            ForEach(Array(emails.enumerated()), id: \.offset) { index, _ in
                emailRow(index: index)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Single Email Row
    private func emailRow(index: Int) -> some View {
        HStack(spacing: 10) {
            // Row number badge
            ZStack {
                Circle()
                    .fill(Color(hex: "ffd200").opacity(0.15))
                    .frame(width: 30, height: 30)
                Text("\(index + 1)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "ffd200"))
            }
            
            // Email input
            TextField("", text: $emails[index], prompt: Text("caregiver@email.com")
                .foregroundColor(Color.white.opacity(0.2)))
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedFieldIndex, equals: index)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "0f0f1a"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    focusedFieldIndex == index
                                        ? Color(hex: "ffd200").opacity(0.5)
                                        : Color.white.opacity(0.06),
                                    lineWidth: 1
                                )
                        )
                )
            
            // Delete button (only if more than one row)
            if emails.count > 1 {
                Button(action: {
                    withAnimation(.spring(response: 0.35)) {
                        removeEmail(at: index)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "f5576c").opacity(0.8))
                }
            }
        }
    }
    
    // MARK: - Add Email Button
    private var addEmailButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35)) {
                emails.append("")
                // Focus the new field after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedFieldIndex = emails.count - 1
                }
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text("Add Another Email")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Color(hex: "ffd200"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "ffd200").opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "ffd200").opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: { submitEmails() }) {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                }
                Text(isSubmitting ? "Saving..." : "Save Caregivers")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundColor(validEmailCount > 0 ? .white : Color.white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        validEmailCount > 0
                            ? accentGradient
                            : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(
                        color: validEmailCount > 0 ? Color(hex: "ffd200").opacity(0.3) : .clear,
                        radius: 12, x: 0, y: 6
                    )
            )
        }
        .disabled(isSubmitting || validEmailCount == 0)
    }
    
    // MARK: - Result Banner
    private func resultBanner(result: SubmitResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: result == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 22))
            
            Text(result == .success
                 ? "Caregivers saved successfully!"
                 : { if case .error(let msg) = result { return msg } else { return "" } }())
                .font(.system(size: 14, weight: .medium, design: .rounded))
            
            Spacer()
        }
        .foregroundColor(result == .success ? Color(hex: "38ef7d") : Color(hex: "f5576c"))
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    (result == .success ? Color(hex: "38ef7d") : Color(hex: "f5576c"))
                        .opacity(0.1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            (result == .success ? Color(hex: "38ef7d") : Color(hex: "f5576c"))
                                .opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    // MARK: - Info Card
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color(hex: "ffd200").opacity(0.7))
                Text("How it works")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                infoRow(icon: "1.circle.fill", text: "Add your caregiver email addresses")
                infoRow(icon: "2.circle.fill", text: "They'll be notified if you miss your pills")
                infoRow(icon: "3.circle.fill", text: "Alerts are sent after repeated missed doses")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardColor.opacity(0.6))
        )
    }
    
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "ffd200").opacity(0.6))
            Text(text)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Color.white.opacity(0.5))
        }
    }
    
    // MARK: - Helpers
    
    private var validEmailCount: Int {
        emails.filter { isValidEmail($0) }.count
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        // Simple email validation
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }
    
    private func removeEmail(at index: Int) {
        guard emails.count > 1 else { return }
        emails.remove(at: index)
    }
    
    // MARK: - API Call
    private func submitEmails() {
        let validEmails = emails
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { isValidEmail($0) }
        
        guard !validEmails.isEmpty else { return }
        
        isSubmitting = true
        submitResult = nil
        
        let baseURL = AuthManager.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/caregivers") else {
            isSubmitting = false
            submitResult = .error("Invalid API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Auth header with persisted user ID
        if let userId = UserDefaults.standard.string(forKey: "lekovka_user_id") {
            request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        }
        
        let body: [String: [String]] = ["emails": validEmails]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    withAnimation(.spring(response: 0.4)) {
                        submitResult = .error("Connection error: \(error.localizedDescription)")
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    withAnimation(.spring(response: 0.4)) {
                        submitResult = .error("Invalid server response")
                    }
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    withAnimation(.spring(response: 0.4)) {
                        submitResult = .success
                    }
                    
                    // Hide the success message after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        if self.submitResult == .success {
                            withAnimation(.spring(response: 0.4)) {
                                self.submitResult = nil
                            }
                        }
                    }
                } else {
                    withAnimation(.spring(response: 0.4)) {
                        submitResult = .error("Server error (HTTP \(httpResponse.statusCode))")
                    }
                }
            }
        }.resume()
    }
}
