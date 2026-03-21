import SwiftUI

// MARK: - BLE View
/// Page 2: ESP32 BLE scanning, connection, and pill-taken data reception.
struct BLEView: View {
    @ObservedObject var bleManager: BLEBackgroundManager
    @ObservedObject var reminderManager: PillReminderManager
    
    private let accentGradient = LinearGradient(
        colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Connection Status Card
                    connectionCard
                    
                    // MARK: - Action Buttons
                    actionSection
                    
                    // MARK: - Received Data
                    if !bleManager.lastReceivedString.isEmpty {
                        dataCard
                    }
                    
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "0f0f1a").ignoresSafeArea())
            .navigationTitle("ESP32 BLE")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Connection Card
    private var connectionCard: some View {
        VStack(spacing: 20) {
            ZStack {
                // Animated rings
                Circle()
                    .stroke(
                        bleManager.isConnected
                            ? Color(hex: "38ef7d").opacity(0.2)
                            : Color(hex: "4facfe").opacity(0.1),
                        lineWidth: 3
                    )
                    .frame(width: 130, height: 130)
                
                Circle()
                    .stroke(
                        bleManager.isConnected
                            ? Color(hex: "38ef7d").opacity(0.1)
                            : Color(hex: "4facfe").opacity(0.05),
                        lineWidth: 2
                    )
                    .frame(width: 160, height: 160)
                
                // Center icon
                ZStack {
                    Circle()
                        .fill(
                            bleManager.isConnected
                                ? LinearGradient(colors: [Color(hex: "11998e"), Color(hex: "38ef7d")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : accentGradient
                        )
                        .frame(width: 90, height: 90)
                        .shadow(
                            color: bleManager.isConnected
                                ? Color(hex: "38ef7d").opacity(0.4)
                                : Color(hex: "4facfe").opacity(0.3),
                            radius: 16, x: 0, y: 6
                        )
                    
                    Image(systemName: bleManager.isConnected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 12)
            
            // Status text
            HStack(spacing: 8) {
                Circle()
                    .fill(bleManager.isConnected ? Color(hex: "38ef7d") : Color(hex: "e74c3c"))
                    .frame(width: 10, height: 10)
                
                Text(bleManager.connectionStatus)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
            
            if bleManager.isScanning {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "4facfe")))
                        .scaleEffect(0.8)
                    Text("Scanning for ESP32...")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "1a1a2e"))
                .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Action Section
    private var actionSection: some View {
        VStack(spacing: 12) {
            if bleManager.isScanning {
                actionButton(
                    title: "Stop Scanning",
                    icon: "stop.circle.fill",
                    colors: [Color(hex: "f093fb"), Color(hex: "f5576c")],
                    action: { bleManager.stopScanning() }
                )
            } else if !bleManager.isConnected {
                actionButton(
                    title: "Scan for ESP32",
                    icon: "magnifyingglass.circle.fill",
                    colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                    action: { bleManager.startScanning() }
                )
            } else {
                // Connected actions
                actionButton(
                    title: "Disconnect",
                    icon: "wifi.slash",
                    colors: [Color(hex: "e74c3c"), Color(hex: "c0392b")],
                    action: { bleManager.disconnect() }
                )
            }
        }
    }
    
    private func actionButton(title: String, icon: String, colors: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .shadow(color: colors.first!.opacity(0.35), radius: 10, x: 0, y: 5)
            )
        }
    }
    
    // MARK: - Data Card
    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(Color(hex: "4facfe"))
                Text("Last Received Data")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                // If JSON contains pill-taken confirmation
                if bleManager.lastReceivedString.lowercased().contains("taken") ||
                   bleManager.lastReceivedString.lowercased().contains("pill") {
                    Button(action: {
                        withAnimation(.spring(response: 0.5)) {
                            reminderManager.markPillsTaken()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirm")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [Color(hex: "11998e"), Color(hex: "38ef7d")], startPoint: .leading, endPoint: .trailing))
                        )
                    }
                }
            }
            
            Text(bleManager.lastReceivedString)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(Color(hex: "4facfe").opacity(0.9))
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
}
