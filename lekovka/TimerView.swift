import SwiftUI

// MARK: - Timer View
/// Page 2: Two pill reminder timers (morning & evening) with HH:mm pickers,
/// countdown displays, and ESP32 + REST API schedule sync.
struct TimerView: View {
    @ObservedObject var reminderManager: PillReminderManager
    @ObservedObject var bleManager: BLEBackgroundManager
    
    @State private var isSaving: Bool = false
    @State private var saveConfirmation: String? = nil
    
    @State private var showMorningCancelAlert: Bool = false
    @State private var showEveningCancelAlert: Bool = false
    
    @State private var showInfo: Bool = false
    
    @AppStorage("lekovka_notify_after_minutes") private var reminderIntervalMinutes: Int = 1
    
    // Gradient colors
    private let morningGradient = LinearGradient(
        colors: [Color(hex: "f7971e"), Color(hex: "ffd200")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let eveningGradient = LinearGradient(
        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let successGradient = LinearGradient(
        colors: [Color(hex: "11998e"), Color(hex: "38ef7d")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let cardColor = Color(hex: "1a1a2e")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Morning Timer
                    timerCard(
                        title: "Morning",
                        icon: "sun.max.fill",
                        iconColor: "ffd200",
                        gradient: morningGradient,
                        showCancelAlert: $showMorningCancelAlert,
                        hour: $reminderManager.morningHour,
                        minute: $reminderManager.morningMinute,
                        isActive: reminderManager.isMorningActive,
                        pillsTaken: reminderManager.morningPillsTaken,
                        pillsTakenTime: reminderManager.morningPillsTakenTime,
                        timeRemaining: reminderManager.morningTimeRemaining,
                        formattedTime: reminderManager.formattedMorningTime(),
                        onStart: { reminderManager.startMorningTimer() },
                        onStop: { reminderManager.stopMorningTimer() },
                        onTaken: { reminderManager.markMorningPillsTaken() }
                    )
                    
                    // MARK: - Evening Timer
                    timerCard(
                        title: "Evening",
                        icon: "moon.stars.fill",
                        iconColor: "764ba2",
                        gradient: eveningGradient,
                        showCancelAlert: $showEveningCancelAlert,
                        hour: $reminderManager.eveningHour,
                        minute: $reminderManager.eveningMinute,
                        isActive: reminderManager.isEveningActive,
                        pillsTaken: reminderManager.eveningPillsTaken,
                        pillsTakenTime: reminderManager.eveningPillsTakenTime,
                        timeRemaining: reminderManager.eveningTimeRemaining,
                        formattedTime: reminderManager.formattedEveningTime(),
                        onStart: { reminderManager.startEveningTimer() },
                        onStop: { reminderManager.stopEveningTimer() },
                        onTaken: { reminderManager.markEveningPillsTaken() }
                    )
                    
                    // MARK: - Save & Sync Button
                    saveButton
                    
                    // MARK: - Confirmation banner
                    if let msg = saveConfirmation {
                        confirmationBanner(message: msg)
                    }
                    
                    // MARK: - Reset (if both taken)
                    if reminderManager.allPillsTaken {
                        resetButton
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showInfo = true }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "667eea"))
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
                .presentationDetents([.height(280)])
            }
        }
    }
    
    // MARK: - Timer Card
    private func timerCard(
        title: String,
        icon: String,
        iconColor: String,
        gradient: LinearGradient,
        showCancelAlert: Binding<Bool>,
        hour: Binding<Int>,
        minute: Binding<Int>,
        isActive: Bool,
        pillsTaken: Bool,
        pillsTakenTime: Date?,
        timeRemaining: String,
        formattedTime: String,
        onStart: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onTaken: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            pillsTaken
                                ? successGradient
                                : gradient
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(hex: iconColor).opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: pillsTaken ? "checkmark.circle.fill" : icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(title) Pills")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if pillsTaken, let time = pillsTakenTime {
                        Text("Taken at \(time, formatter: timeFormatter)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Color(hex: "38ef7d").opacity(0.8))
                    } else if isActive {
                        Text("Scheduled for \(formattedTime)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.45))
                    } else {
                        Text("Set your \(title.lowercased()) time")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.35))
                    }
                }
                
                Spacer()
                
                // Status badge
                if pillsTaken {
                    Text("Done")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "38ef7d"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(Color(hex: "38ef7d").opacity(0.15))
                        )
                } else if isActive {
                    Text("Active")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: iconColor))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(Color(hex: iconColor).opacity(0.15))
                        )
                }
            }
            
            if pillsTaken {
                // Already taken — nothing else to show
            } else if isActive {
                // Countdown
                VStack(spacing: 12) {
                    Text(timeRemaining)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundStyle(gradient)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            showCancelAlert.wrappedValue = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "e74c3c").opacity(0.8))
                            )
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.5)) { onTaken() }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Taken!")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(successGradient)
                            )
                        }
                    }
                }
                .padding(.top, 4)
            } else {
                // Time picker (native DatePicker allows infinite scrolling)
                let timeBinding = Binding<Date>(
                    get: {
                        var components = DateComponents()
                        components.hour = hour.wrappedValue
                        components.minute = minute.wrappedValue
                        return Calendar.current.date(from: components) ?? Date()
                    },
                    set: { newDate in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                        if let h = components.hour, let m = components.minute {
                            hour.wrappedValue = h
                            minute.wrappedValue = m
                        }
                    }
                )
                
                ZStack {
                    // Premium Glassmorphic Background for the Picker
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex: iconColor).opacity(0.4), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    DatePicker(
                        "Set \(title) time",
                        selection: timeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .environment(\.timeZone, TimeZone.current)
                    .scaleEffect(1.05) // Make the wheel slightly more prominent
                    .frame(height: 130)
                    .clipped()
                }
                .frame(height: 140)
                .padding(.horizontal, 10)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
        )
        .alert("Cancel \(title) Timer?", isPresented: showCancelAlert) {
            Button("Keep Timer", role: .cancel) { }
            Button("Yes, Cancel", role: .destructive) {
                withAnimation(.spring(response: 0.4)) { onStop() }
            }
        } message: {
            Text("This will stop the reminders and delete the schedule from the server.")
        }
    }
    
    // MARK: - Save & Sync Button
    private var saveButton: some View {
        Button(action: { saveSchedule() }) {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 20))
                }
                Text(isSaving ? "Saving..." : "Save & Sync Schedule")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: "667eea").opacity(0.4), radius: 12, x: 0, y: 6)
            )
        }
        .disabled(isSaving)
    }
    
    // MARK: - Confirmation Banner
    private func confirmationBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
            Spacer()
        }
        .foregroundColor(Color(hex: "38ef7d"))
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "38ef7d").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "38ef7d").opacity(0.2), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    // MARK: - Reset Button
    private var resetButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.5)) {
                reminderManager.resetForNewDay()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                Text("Reset for Tomorrow")
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(Color(hex: "667eea"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "667eea").opacity(0.12))
            )
        }
    }
    
    // MARK: - Info Card
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color(hex: "667eea"))
                Text("How it works")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                infoRow(icon: "1.circle.fill", text: "Set your morning & evening pill times")
                infoRow(icon: "2.circle.fill", text: "Tap Save to sync with ESP32 and server")
                infoRow(icon: "3.circle.fill", text: "Reminders repeat every \(max(1, reminderIntervalMinutes)) min until taken")
                infoRow(icon: "4.circle.fill", text: "Confirm via ESP32 or tap \"Taken!\" to stop")
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
                .foregroundColor(Color(hex: "667eea").opacity(0.7))
            Text(text)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Color.white.opacity(0.5))
        }
    }
    
    // MARK: - Save Schedule
    private func saveSchedule() {
        isSaving = true
        saveConfirmation = nil
        
        // 1. Start local timers & notifications
        withAnimation(.spring(response: 0.4)) {
            reminderManager.startBothTimers()
        }
        
        // 2. Send configuration to ESP32 via BLE
        if let json = reminderManager.buildConfigurationScheduleJSON() {
            bleManager.sendString(json)
        }
        
        // 3. Send schedule to REST API
        reminderManager.sendScheduleToAPI()
        
        // Show confirmation after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isSaving = false
            withAnimation(.spring(response: 0.4)) {
                saveConfirmation = "Schedule saved & synced!"
            }
            // Auto-hide confirmation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation { saveConfirmation = nil }
            }
        }
    }
    
    // MARK: - Formatter
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
}
