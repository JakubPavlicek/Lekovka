import SwiftUI
import UserNotifications

// MARK: - Content View (Root)
/// Root view that shows LoginView or the main tab-based navigation
/// depending on whether the user has already logged in.
struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    @StateObject private var bleManager = BLEBackgroundManager()
    @StateObject private var reminderManager = PillReminderManager()
    
    @State private var selectedTab: Int = 0
    @Environment(\.scenePhase) private var scenePhase
    
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
        Group {
            if authManager.isLoggedIn {
                mainTabView
            } else {
                LoginView(authManager: authManager)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: authManager.isLoggedIn)
    }
    
    // MARK: - Main Tab View
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            BLEView(bleManager: bleManager, reminderManager: reminderManager)
                .tabItem {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("BLE")
                }
                .tag(0)
            
            TimerView(reminderManager: reminderManager, bleManager: bleManager)
                .tabItem {
                    Image(systemName: "timer.circle.fill")
                    Text("Timer")
                }
                .tag(1)
            
            CaregiversView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Caregivers")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .tint(Color(hex: "667eea"))
        .onAppear {
            reminderManager.requestNotificationPermission()
        }
        // Auto-clear notification badge when the app opens
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Clear the little red '1' badge on the home screen icon
                UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                
                // Automatically check if we rolled over midnight!
                reminderManager.checkAndResetForNewDay()
            }
        }
        // Listen for BLE pill confirmation → auto-mark pills taken
        .onChange(of: bleManager.lastReceivedString) { newValue in
            let lower = newValue.lowercased()
            if lower.contains("medicaments-taken-confirmation") || lower.contains("taken") || lower.contains("pill") {
                withAnimation(.spring(response: 0.5)) {
                    reminderManager.markClosestPillsTaken()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
