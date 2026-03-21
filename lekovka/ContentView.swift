import SwiftUI
import UserNotifications

// MARK: - Content View (Tab Root)
/// Main tab-based navigation for the Lekovka pill reminder app.
struct ContentView: View {
    @StateObject private var bleManager = BLEBackgroundManager()
    @StateObject private var apiService = APIService()
    @StateObject private var reminderManager = PillReminderManager()
    
    @State private var selectedTab: Int = 0
    
    // Tab bar colors
    init() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color(hex: "12121f"))
        
        // Unselected items
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.35)
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.35)
        ]
        
        // Selected items
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "667eea"))
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "667eea"))
        ]
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TimerView(reminderManager: reminderManager)
                .tabItem {
                    Image(systemName: "timer.circle.fill")
                    Text("Timer")
                }
                .tag(0)
            
            BLEView(bleManager: bleManager, reminderManager: reminderManager)
                .tabItem {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("BLE")
                }
                .tag(1)
            
            APIView(apiService: apiService, reminderManager: reminderManager)
                .tabItem {
                    Image(systemName: "icloud.and.arrow.up.fill")
                    Text("Report")
                }
                .tag(2)
            
            NotificationsView()
                .tabItem {
                    Image(systemName: "bell.badge.fill")
                    Text("Feed")
                }
                .tag(3)
        }
        .tint(Color(hex: "667eea"))
        .onAppear {
            reminderManager.requestNotificationPermission()
        }
        // Listen for BLE pill confirmation → auto-mark pills taken
        .onChange(of: bleManager.lastReceivedString) { newValue in
            if newValue.lowercased().contains("taken") || newValue.lowercased().contains("pill") {
                withAnimation(.spring(response: 0.5)) {
                    reminderManager.markPillsTaken()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
