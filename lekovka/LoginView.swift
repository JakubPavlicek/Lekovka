import SwiftUI

// MARK: - Login View
/// Login screen shown when the user has not yet registered.
/// Sends email via POST /users and stores the returned user ID.
struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    
    @State private var email: String = ""
    @FocusState private var isEmailFocused: Bool
    
    // Brand gradients (consistent with the rest of the app)
    private let accentGradient = LinearGradient(
        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let backgroundGradient = LinearGradient(
        colors: [Color(hex: "0f0f1a"), Color(hex: "1a1a2e"), Color(hex: "0f0f1a")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "0f0f1a").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    
                    // MARK: - Logo / Branding
                    brandingSection
                    
                    Spacer().frame(height: 48)
                    
                    // MARK: - Login Card
                    loginCard
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .onTapGesture {
            isEmailFocused = false
        }
    }
    
    // MARK: - Branding Section
    private var brandingSection: some View {
        VStack(spacing: 20) {
            // App icon with glow
            ZStack {
                // Outer glow rings
                Circle()
                    .fill(Color(hex: "667eea").opacity(0.08))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(Color(hex: "667eea").opacity(0.05))
                    .frame(width: 200, height: 200)
                
                // Icon circle
                ZStack {
                    Circle()
                        .fill(accentGradient)
                        .frame(width: 110, height: 110)
                        .shadow(color: Color(hex: "667eea").opacity(0.5), radius: 24, x: 0, y: 10)
                    
                    Image(systemName: "pills.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.white)
                }
            }
            
            // App name
            Text("Lekovka")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(accentGradient)
            
            Text("Your pill reminder companion")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.45))
        }
    }
    
    // MARK: - Login Card
    private var loginCard: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 6) {
                Text("Get Started")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Enter your email to sign in")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.45))
            }
            
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "667eea").opacity(0.7))
                    
                    TextField("", text: $email, prompt: Text("your@email.com")
                        .foregroundColor(Color.white.opacity(0.25)))
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isEmailFocused)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "1a1a2e"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isEmailFocused
                                        ? Color(hex: "667eea").opacity(0.6)
                                        : Color.white.opacity(0.06),
                                    lineWidth: 1
                                )
                        )
                )
                
                // Error message
                if let error = authManager.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text(error)
                            .font(.system(size: 13, design: .rounded))
                    }
                    .foregroundColor(Color(hex: "f5576c"))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            // Login button
            Button(action: {
                isEmailFocused = false
                authManager.login(email: email)
            }) {
                HStack(spacing: 10) {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                    }
                    Text(authManager.isLoading ? "Signing in..." : "Continue")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(accentGradient)
                        .shadow(color: Color(hex: "667eea").opacity(0.4), radius: 12, x: 0, y: 6)
                )
            }
            .disabled(authManager.isLoading || email.isEmpty)
            .opacity(email.isEmpty ? 0.5 : 1.0)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "16162a"))
                .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
        )
    }
}

