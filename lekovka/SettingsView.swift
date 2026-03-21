import SwiftUI
import Combine

// MARK: - Settings View
/// Allows the user to configure notification intervals and caregiver alert thresholds.
/// Saves locally via AppStorage and syncs to the backend via POST/PATCH /users.
struct SettingsView: View {
    
    // Bindings to the actual persisted values
    @AppStorage("lekovka_notify_after_minutes") private var savedNotifyMinutes: Int = 1
    @AppStorage("lekovka_notify_caregivers_after_retries") private var savedNotifyCaregivers: Int = 3
    
    // Local state for editing before saving
    @State private var draftNotifyMinutes: Int = 1
    @State private var draftNotifyCaregivers: Int = 3
    
    @State private var isSaving: Bool = false
    @State private var saveMessage: String? = nil
    @State private var isSuccess: Bool = false
    
    private let cardColor = Color(hex: "1a1a2e")
    private let accentGradient = LinearGradient(
        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Settings Form
                    settingsCard
                    
                    // MARK: - Save Button
                    saveButton
                    
                    // MARK: - Save Message Banner
                    if let message = saveMessage {
                        messageBanner(text: message, isSuccess: isSuccess)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "0f0f1a").ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                // Initialize draft values with saved values when the view appears
                draftNotifyMinutes = max(1, savedNotifyMinutes)
                draftNotifyCaregivers = max(1, savedNotifyCaregivers)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "667eea").opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(accentGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(hex: "667eea").opacity(0.4), radius: 16, x: 0, y: 8)
                
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
            }
            
            Text("App Preferences")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Customize your pill reminders\nand caregiver notifications.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Settings Card
    private var settingsCard: some View {
        VStack(spacing: 24) {
            // Setting 1
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(Color(hex: "667eea"))
                    Text("Reminder Interval")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text("How many minutes between local notifications if you forget to take your pill.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text("\(draftNotifyMinutes) Minute(s)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Stepper("", value: $draftNotifyMinutes, in: 1...60)
                        .labelsHidden()
                        .colorScheme(.dark)
                }
                .padding()
                .background(Color(hex: "0f0f1a").cornerRadius(12))
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Setting 2
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.2.badge.gearshape.fill")
                        .foregroundColor(Color(hex: "f7971e"))
                    Text("Caregiver Alert Threshold")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text("How many missed reminders before an email is sent to your caregivers.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text("\(draftNotifyCaregivers) Missed")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Stepper("", value: $draftNotifyCaregivers, in: 1...20)
                        .labelsHidden()
                        .colorScheme(.dark)
                }
                .padding()
                .background(Color(hex: "0f0f1a").cornerRadius(12))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            saveSettings()
        }) {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                }
                Text(isSaving ? "Saving..." : "Save Preferences")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(accentGradient)
                    .shadow(color: Color(hex: "667eea").opacity(0.3), radius: 12, x: 0, y: 6)
            )
        }
        .disabled(isSaving || (draftNotifyMinutes == savedNotifyMinutes && draftNotifyCaregivers == savedNotifyCaregivers))
    }
    
    // MARK: - Message Banner
    private func messageBanner(text: String, isSuccess: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 20))
            
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
            
            Spacer()
        }
        .foregroundColor(isSuccess ? Color(hex: "38ef7d") : Color(hex: "f5576c"))
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill((isSuccess ? Color(hex: "38ef7d") : Color(hex: "f5576c")).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke((isSuccess ? Color(hex: "38ef7d") : Color(hex: "f5576c")).opacity(0.2), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    // MARK: - API Call
    private func saveSettings() {
        guard let userId = UserDefaults.standard.string(forKey: "lekovka_user_id") else {
            withAnimation {
                self.isSuccess = false
                self.saveMessage = "Error: Not logged in."
            }
            return
        }
        
        isSaving = true
        saveMessage = nil
        
        // Setup API Request
        let baseURL = AuthManager.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        // Note: Assumed endpoint is PATCH /users to update the current user's preferences
        guard let url = URL(string: "\(baseURL)/users") else {
            isSaving = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let body: [String: Int] = [
            "notify_after_minutes": draftNotifyMinutes,
            "notify_caregivers_after_retries": draftNotifyCaregivers
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                self.isSaving = false
                
                if let error = error {
                    withAnimation {
                        self.isSuccess = false
                        self.saveMessage = "Error: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    withAnimation {
                        self.isSuccess = false
                        self.saveMessage = "Invalid server response."
                    }
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    // Update the local AppStorage values on success!
                    self.savedNotifyMinutes = self.draftNotifyMinutes
                    self.savedNotifyCaregivers = self.draftNotifyCaregivers
                    
                    withAnimation {
                        self.isSuccess = true
                        self.saveMessage = "Settings saved successfully!"
                    }
                    
                    // Hide the success message after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if self.isSuccess {
                            withAnimation { self.saveMessage = nil }
                        }
                    }
                    
                } else {
                    withAnimation {
                        self.isSuccess = false
                        self.saveMessage = "Server error (HTTP \(httpResponse.statusCode))"
                    }
                }
            }
        }.resume()
    }
}
