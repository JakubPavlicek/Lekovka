import SwiftUI

struct Caregiver: Codable, Identifiable {
    var id = UUID()
    var email: String
    var phone: String
    
    enum CodingKeys: String, CodingKey {
        case email, phone
    }
}

// MARK: - Caregivers View
struct CaregiversView: View {
    
    // MARK: - State
    @State private var caregivers: [Caregiver] = [Caregiver(email: "", phone: "")]
    @State private var isSubmitting: Bool = false
    @State private var submitResult: SubmitResult?
    
    // Phone Verification state
    @State private var verifyPhone: String = ""
    @State private var verifyOTP: String = ""
    @State private var isVerifying: Bool = false
    @State private var verifyResult: SubmitResult?
    
    @FocusState private var focusedFieldIndex: String?
    @State private var showInfo: Bool = false
    
    enum SubmitResult: Equatable {
        case success
        case error(String)
    }
    
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
                    
                    // MARK: - Phone Verification
                    phoneVerificationCard
                    
                    // MARK: - Caregiver List
                    caregiverListCard
                    
                    // MARK: - Add Button
                    addCaregiverButton
                    
                    // MARK: - Submit Button
                    submitButton
                    
                    // MARK: - Result Banner
                    if let result = submitResult {
                        resultBanner(result: result)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "0f0f1a").ignoresSafeArea())
            .navigationTitle("Caregivers")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                fetchCaregivers()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showInfo = true }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "ffd200"))
                    }
                }
            }
            .sheet(isPresented: $showInfo) {
                ZStack {
                    Color(hex: "0f0f1a").ignoresSafeArea()
                    VStack {
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 5)
                            .padding(.top, 12)
                        
                        infoCard
                            .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
                .presentationDetents([.height(260)])
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color(hex: "ffd200").opacity(0.06)).frame(width: 60, height: 60)
                Circle().fill(accentGradient).frame(width: 44, height: 44)
                    .shadow(color: Color(hex: "ffd200").opacity(0.35), radius: 8, x: 0, y: 4)
                Image(systemName: "person.2.badge.gearshape.fill").font(.system(size: 22)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Caregiver Contacts").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
                Text("Manage contacts and verify your phone").font(.system(size: 13, design: .rounded)).foregroundColor(Color.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(20).frame(maxWidth: .infinity).background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
    }
    
    // MARK: - Phone Verification Card
    private var phoneVerificationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "iphone.badge.play").foregroundColor(Color(hex: "ffd200"))
                Text("Phone Verification").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                TextField("", text: $verifyPhone, prompt: Text("Phone Number (+420...)").foregroundColor(Color.white.opacity(0.5)))
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.phonePad)
                
                TextField("", text: $verifyOTP, prompt: Text("Verification OTP Code").foregroundColor(Color.white.opacity(0.5)))
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.numberPad)
                
                Button(action: { verifyPhoneOTP() }) {
                    if isVerifying {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8)
                    } else {
                        Text("Verify Phone")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(accentGradient.opacity(verifyPhone.isEmpty || verifyOTP.isEmpty ? 0.3 : 1.0))
                .cornerRadius(12)
                .disabled(isVerifying || verifyPhone.isEmpty || verifyOTP.isEmpty)
            }
            
            if let result = verifyResult {
                Text(result == .success ? "Phone verified successfully!" : "Verification failed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(result == .success ? Color(hex: "38ef7d") : Color(hex: "f5576c"))
            }
        }
        .padding(20).background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
    }
    
    // MARK: - Caregiver List Card
    private var caregiverListCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "envelope.badge.fill").foregroundColor(Color(hex: "ffd200"))
                Text("Caregiver List").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.white)
                Spacer()
            }
            
            ForEach(caregivers.indices, id: \.self) { index in
                caregiverRow(index: index)
            }
        }
        .padding(20).background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
    }
    
    // MARK: - Single Caregiver Row
    private func caregiverRow(index: Int) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Circle().fill(Color(hex: "ffd200").opacity(0.15)).frame(width: 24, height: 24)
                    .overlay(Text("\(index + 1)").font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: "ffd200")))
                
                TextField("", text: $caregivers[index].email, prompt: Text("Email (Required)").foregroundColor(Color.white.opacity(0.5)))
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                
                if caregivers.count > 1 {
                    Button(action: { caregivers.remove(at: index) }) {
                        Image(systemName: "minus.circle.fill").foregroundColor(Color(hex: "f5576c").opacity(0.8))
                    }
                }
            }
            
            TextField("", text: $caregivers[index].phone, prompt: Text("Phone (Optional)").foregroundColor(Color.white.opacity(0.5)))
                .textFieldStyle(CustomTextFieldStyle())
                .keyboardType(.phonePad)
                .padding(.leading, 34)
            
            Divider().background(Color.white.opacity(0.05)).padding(.top, 4)
        }
    }
    
    // MARK: - Add Button
    private var addCaregiverButton: some View {
        Button(action: { caregivers.append(Caregiver(email: "", phone: "")) }) {
            Label("Add Another Caregiver", systemImage: "plus.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "ffd200"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "ffd200").opacity(0.1)))
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: { submitCaregivers() }) {
            HStack(spacing: 10) {
                if isSubmitting { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                else { Image(systemName: "paperplane.fill") }
                Text(isSubmitting ? "Saving..." : "Save Caregivers").font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 17)
            .background(RoundedRectangle(cornerRadius: 16).fill(accentGradient))
        }
        .disabled(isSubmitting)
    }
    
    // MARK: - Result Banner
    private func resultBanner(result: SubmitResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: result == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            Text(result == .success ? "Saved successfully!" : "Error occurred")
        }
        .foregroundColor(result == .success ? Color(hex: "38ef7d") : Color(hex: "f5576c"))
        .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
    }
    
    // MARK: - API Calls
    private func fetchCaregivers() {
        let baseURL = AuthManager.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/caregivers") else { return }
        var request = URLRequest(url: url)
        if let userId = UserDefaults.standard.string(forKey: "lekovka_user_id") { request.setValue(userId, forHTTPHeaderField: "X-User-ID") }
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data, let decoded = try? JSONDecoder().decode([Caregiver].self, from: data) {
                DispatchQueue.main.async {
                    self.caregivers = decoded.isEmpty ? [Caregiver(email: "", phone: "")] : decoded
                }
            }
        }.resume()
    }
    
    private func submitCaregivers() {
        let validOnes = caregivers.filter { !$0.email.isEmpty }
        isSubmitting = true
        let baseURL = AuthManager.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/caregivers") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let userId = UserDefaults.standard.string(forKey: "lekovka_user_id") { request.setValue(userId, forHTTPHeaderField: "X-User-ID") }
        
        let body: [String: [Caregiver]] = ["caregivers": validOnes]
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                self.isSubmitting = false
                if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                    self.submitResult = .success
                } else {
                    self.submitResult = .error("Failed")
                }
            }
        }.resume()
    }
    
    private func verifyPhoneOTP() {
        isVerifying = true
        let baseURL = AuthManager.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/caregivers/verify-phone") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let userId = UserDefaults.standard.string(forKey: "lekovka_user_id") { request.setValue(userId, forHTTPHeaderField: "X-User-ID") }
        
        let body: [String: String] = ["phone": verifyPhone, "otp": verifyOTP]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                self.isVerifying = false
                if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                    self.verifyResult = .success
                } else {
                    self.verifyResult = .error("Failed")
                }
            }
        }.resume()
    }
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How it works", systemImage: "info.circle.fill").foregroundColor(.white)
            Text("Add caregivers and verify your phone to ensure you're always connected.").font(.system(size: 14)).foregroundColor(.white.opacity(0.6))
        }
        .padding(20).background(RoundedRectangle(cornerRadius: 20).fill(cardColor.opacity(0.6)))
    }
}

// Custom TextField style for a consistent sleek look
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 15, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "0f0f1a")))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}
