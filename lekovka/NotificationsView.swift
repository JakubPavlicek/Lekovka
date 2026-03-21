import SwiftUI

// MARK: - Pill Notification Model
struct PillNotification: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let time: Date
    let message: String
}

// MARK: - Notifications View
/// Page 4: Feed of push notifications showing when other people took their pills.
struct NotificationsView: View {
    
    @State private var notifications: [PillNotification] = []
    @State private var isRefreshing: Bool = false
    
    private let accentGradient = LinearGradient(
        colors: [Color(hex: "f7971e"), Color(hex: "ffd200")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Demo avatars
    private let avatarColors: [String] = ["667eea", "f093fb", "4facfe", "38ef7d", "f5576c", "ffd200", "11998e", "764ba2"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Notification Feed
                    if notifications.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(notifications.enumerated()), id: \.element.id) { index, notification in
                                notificationCard(notification: notification, index: index)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "0f0f1a").ignoresSafeArea())
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { refreshNotifications() }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "ffd200"))
                    }
                }
            }
            .onAppear {
                if notifications.isEmpty {
                    loadMockNotifications()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentGradient)
                        .frame(width: 50, height: 50)
                        .shadow(color: Color(hex: "ffd200").opacity(0.3), radius: 10, x: 0, y: 4)
                    
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Friend Activity")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(notifications.count) notifications today")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "1a1a2e"))
                .shadow(color: Color.black.opacity(0.3), radius: 14, x: 0, y: 6)
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(Color.white.opacity(0.2))
            
            Text("No notifications yet")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.4))
            
            Text("When friends take their pills, you'll see it here")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Color.white.opacity(0.25))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
    
    private func notificationCard(notification: PillNotification, index: Int) -> some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: avatarColors[index % avatarColors.count]),
                                Color(hex: avatarColors[(index + 3) % avatarColors.count])
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                
                Text(String(notification.name.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timeAgo(notification.time))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                
                Text(notification.message)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.55))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1a1a2e"))
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Helpers
    
    private func timeAgo(_ date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 60 { return "just now" }
        if diff < 3600 { return "\(diff / 60)m ago" }
        if diff < 86400 { return "\(diff / 3600)h ago" }
        return "\(diff / 86400)d ago"
    }
    
    private func refreshNotifications() {
        withAnimation(.spring(response: 0.4)) {
            isRefreshing = true
        }
        
        // Simulate network refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.5)) {
                loadMockNotifications()
                isRefreshing = false
            }
        }
    }
    
    private func loadMockNotifications() {
        // TODO: Replace with real API call to fetch friend notifications
        let names = ["Babička Marie", "Děda Karel", "Mama", "Tata", "Jana", "Petr"]
        let messages = [
            "took their morning pills 💊",
            "just confirmed their medication ✅",
            "took their evening dose 🌙",
            "reported pills taken on time 🎯",
            "took their vitamins and medicine 💪",
            "confirmed daily medication 🏥"
        ]
        
        notifications = (0..<names.count).map { i in
            PillNotification(
                name: names[i],
                time: Date().addingTimeInterval(-Double(i * 1800 + Int.random(in: 0...600))),
                message: messages[i % messages.count]
            )
        }
    }
}
