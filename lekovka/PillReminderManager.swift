import Foundation
import UserNotifications
import Combine

// MARK: - Pill Reminder Manager
/// Central state manager for pill reminders, timers, and notification scheduling.
class PillReminderManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var targetHour: Int = 8
    @Published var targetMinute: Int = 0
    @Published var isTimerActive: Bool = false
    @Published var pillsTaken: Bool = false
    @Published var pillsTakenTime: Date? = nil
    @Published var timeRemainingString: String = ""
    @Published var reminderCount: Int = 0
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var targetDate: Date?
    private let reminderIntervalSeconds: TimeInterval = 180 // 3 minutes
    private let notificationCategoryIdentifier = "PILL_REMINDER"
    
    init() {
        requestNotificationPermission()
    }
    
    // MARK: - Notification Permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Timer Control
    
    /// Schedules a pill reminder at the given hour:minute today (or tomorrow if that time has passed).
    func startTimer() {
        guard !pillsTaken else { return }
        
        cancelAllReminders()
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = targetHour
        components.minute = targetMinute
        components.second = 0
        
        guard var date = calendar.date(from: components) else { return }
        
        // If the target time has already passed today, schedule for tomorrow
        if date <= Date() {
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        targetDate = date
        isTimerActive = true
        reminderCount = 0
        
        // Schedule the initial notification
        scheduleNotification(at: date, title: "💊 Time to take your pills!", body: "It's \(formattedTime()) — don't forget your medication.", identifier: "pill_reminder_main")
        
        // Schedule follow-up reminders every 3 minutes (up to 10)
        for i in 1...10 {
            let reminderDate = date.addingTimeInterval(reminderIntervalSeconds * Double(i))
            scheduleNotification(
                at: reminderDate,
                title: "⏰ Pill Reminder #\(i)",
                body: "You still haven't taken your pills! It's been \(i * 3) minutes.",
                identifier: "pill_reminder_followup_\(i)"
            )
        }
        
        // Start a display timer to show countdown
        startCountdownTimer()
    }
    
    func stopTimer() {
        isTimerActive = false
        targetDate = nil
        timeRemainingString = ""
        timer?.invalidate()
        timer = nil
        cancelAllReminders()
    }
    
    /// Called when pills are confirmed taken (from BLE, API, or manual).
    func markPillsTaken() {
        pillsTaken = true
        pillsTakenTime = Date()
        stopTimer()
    }
    
    /// Resets for a new day.
    func resetForNewDay() {
        pillsTaken = false
        pillsTakenTime = nil
        reminderCount = 0
    }
    
    // MARK: - Formatted Time
    func formattedTime() -> String {
        return String(format: "%02d:%02d", targetHour, targetMinute)
    }
    
    // MARK: - Private Helpers
    
    private func startCountdownTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let target = self.targetDate else { return }
            
            let remaining = target.timeIntervalSince(Date())
            
            if remaining <= 0 {
                DispatchQueue.main.async {
                    self.timeRemainingString = "Time's up! Take your pills!"
                    self.timer?.invalidate()
                    self.timer = nil
                }
                return
            }
            
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            let seconds = Int(remaining) % 60
            
            DispatchQueue.main.async {
                self.timeRemainingString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            }
        }
    }
    
    private func scheduleNotification(at date: Date, title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        let triggerInterval = date.timeIntervalSince(Date())
        guard triggerInterval > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification scheduling error: \(error.localizedDescription)")
            }
        }
    }
    
    private func cancelAllReminders() {
        var identifiers = ["pill_reminder_main"]
        for i in 1...10 {
            identifiers.append("pill_reminder_followup_\(i)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
