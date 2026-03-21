import SwiftUI

// MARK: - API View
/// Page 3: Report that pills have been taken via an external API call.
struct APIView: View {
    @ObservedObject var apiService: APIService
    @ObservedObject var reminderManager: PillReminderManager
    
    @State private var userName: String = ""
    
    private let accentGradient = LinearGradient(
        colors: [Color(hex: "f093fb"), Color(hex: "f5576c")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Header Illustration
                    headerSection
                    
                    // MARK: - Name Input
                    nameInputCard
                    
                    // MARK: - Report Button
                    reportButton
                    
                    // MARK: - API Response
                    if !apiService.response.isEmpty {
                        responseCard
                    }
                    
                    // MARK: - Status
                    if reminderManager.pillsTaken {
                        statusBadge
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "0f0f1a").ignoresSafeArea())
            .navigationTitle("Report Pills")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentGradient)
                    .frame(width: 90, height: 90)
                    .shadow(color: Color(hex: "f5576c").opacity(0.35), radius: 16, x: 0, y: 8)
                
                Image(systemName: "icloud.and.arrow.up.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            Text("Report via API")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Send a notification to others that you've taken your pills")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "1a1a2e"))
                .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
        )
    }
    
    private var nameInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .foregroundColor(Color(hex: "f093fb"))
                Text("Your Name")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            TextField("Enter your name", text: $userName)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.white)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "0f0f1a"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "f093fb").opacity(0.3), lineWidth: 1)
                        )
                )
                .tint(Color(hex: "f093fb"))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "1a1a2e"))
        )
    }
    
    private var reportButton: some View {
        Button(action: {
            let name = userName.isEmpty ? "Anonymous" : userName
            apiService.reportPillsTaken(name: name)
            withAnimation(.spring(response: 0.5)) {
                reminderManager.markPillsTaken()
            }
        }) {
            HStack(spacing: 10) {
                if apiService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                }
                Text(reminderManager.pillsTaken ? "Already Reported ✅" : "I Took My Pills!")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        reminderManager.pillsTaken
                            ? LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            : accentGradient
                    )
                    .shadow(
                        color: reminderManager.pillsTaken ? .clear : Color(hex: "f5576c").opacity(0.35),
                        radius: 12, x: 0, y: 6
                    )
            )
        }
        .disabled(apiService.isLoading || reminderManager.pillsTaken)
    }
    
    private var responseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "server.rack")
                    .foregroundColor(Color(hex: "f093fb"))
                Text("API Response")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(apiService.response)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(Color(hex: "f093fb").opacity(0.9))
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "0f0f1a"))
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "1a1a2e"))
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        )
    }
    
    private var statusBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "38ef7d"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Pills confirmed")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                if let time = reminderManager.pillsTakenTime {
                    Text("Taken at \(time, formatter: timeFormatter)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                }
            }
            
            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "38ef7d").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "38ef7d").opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
}
