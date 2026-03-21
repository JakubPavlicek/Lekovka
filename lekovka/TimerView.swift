import SwiftUI

// MARK: - Timer View
/// Page 1: Set a pill reminder time (HH:mm) and see a live countdown.
struct TimerView: View {
    @ObservedObject var reminderManager: PillReminderManager
    
    // Gradient colors for the pill theme
    private let accentGradient = LinearGradient(
        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let successGradient = LinearGradient(
        colors: [Color(hex: "11998e"), Color(hex: "38ef7d")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    
                    // MARK: - Status Card
                    if reminderManager.pillsTaken {
                        pillsTakenCard
                    } else {
                        timerSetupSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "0f0f1a").ignoresSafeArea())
            .navigationTitle("Pill Timer")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Subviews
    
    private var pillsTakenCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(successGradient)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(hex: "38ef7d").opacity(0.4), radius: 20, x: 0, y: 8)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)
            
            Text("Pills Taken! ✅")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if let time = reminderManager.pillsTakenTime {
                Text("Taken at \(time, formatter: timeFormatter)")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.5)) {
                    reminderManager.resetForNewDay()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset for Tomorrow")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "667eea"))
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "667eea").opacity(0.15))
                )
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "1a1a2e"))
                .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
        )
    }
    
    private var timerSetupSection: some View {
        VStack(spacing: 24) {
            // Time picker card
            VStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color(hex: "667eea"))
                    Text("Set Reminder Time")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 4) {
                    // Hours picker
                    Picker("Hours", selection: $reminderManager.targetHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(String(format: "%02d", hour))
                                .tag(hour)
                                .foregroundColor(.white)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 150)
                    .clipped()
                    
                    Text(":")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "667eea"))
                    
                    // Minutes picker
                    Picker("Minutes", selection: $reminderManager.targetMinute) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text(String(format: "%02d", minute))
                                .tag(minute)
                                .foregroundColor(.white)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 150)
                    .clipped()
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a1a2e"))
                    .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
            )
            
            // Countdown / Start-Stop
            if reminderManager.isTimerActive {
                // Countdown display
                VStack(spacing: 16) {
                    Text("⏳ Next Reminder")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Text(reminderManager.timeRemainingString)
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentGradient)
                    
                    Text("Scheduled for \(reminderManager.formattedTime())")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.4))
                    
                    HStack(spacing: 16) {
                        // Cancel button
                        Button(action: {
                            withAnimation(.spring(response: 0.4)) {
                                reminderManager.stopTimer()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: "e74c3c").opacity(0.8))
                            )
                        }
                        
                        // Mark as taken
                        Button(action: {
                            withAnimation(.spring(response: 0.5)) {
                                reminderManager.markPillsTaken()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Taken!")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(successGradient)
                            )
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "1a1a2e"))
                        .shadow(color: Color(hex: "667eea").opacity(0.15), radius: 20, x: 0, y: 8)
                )
            } else {
                // Start button
                Button(action: {
                    withAnimation(.spring(response: 0.4)) {
                        reminderManager.startTimer()
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 20))
                        Text("Set Reminder")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(accentGradient)
                            .shadow(color: Color(hex: "667eea").opacity(0.4), radius: 12, x: 0, y: 6)
                    )
                }
            }
            
            // Info card
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Color(hex: "667eea"))
                    Text("How it works")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    infoRow(icon: "1.circle.fill", text: "Set your pill time above")
                    infoRow(icon: "2.circle.fill", text: "You'll be notified at that time")
                    infoRow(icon: "3.circle.fill", text: "Reminders repeat every 3 min")
                    infoRow(icon: "4.circle.fill", text: "Take your pill via ESP32 or API to stop")
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1a1a2e").opacity(0.6))
            )
        }
    }
    
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "667eea").opacity(0.7))
            Text(text)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Color.white.opacity(0.5))
        }
    }
    
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
}
