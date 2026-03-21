import Foundation
import UserNotifications
import Combine

// MARK: - Pill Reminder Manager
/// Central state manager for pill reminders with two schedules (morning & evening).
class PillReminderManager: ObservableObject {
    
    // MARK: - Published Properties (Morning)
    @Published var morningHour: Int = UserDefaults.standard.object(forKey: "lekovka_morning_hour") as? Int ?? 8 {
        didSet { UserDefaults.standard.set(morningHour, forKey: "lekovka_morning_hour") }
    }
    @Published var morningMinute: Int = UserDefaults.standard.object(forKey: "lekovka_morning_minute") as? Int ?? 0 {
        didSet { UserDefaults.standard.set(morningMinute, forKey: "lekovka_morning_minute") }
    }
    @Published var isMorningActive: Bool = UserDefaults.standard.bool(forKey: "lekovka_morning_active") {
        didSet { UserDefaults.standard.set(isMorningActive, forKey: "lekovka_morning_active") }
    }
    @Published var morningPillsTaken: Bool = UserDefaults.standard.bool(forKey: "lekovka_morning_taken") {
        didSet { UserDefaults.standard.set(morningPillsTaken, forKey: "lekovka_morning_taken") }
    }
    @Published var morningPillsTakenTime: Date? = {
        if let interval = UserDefaults.standard.object(forKey: "lekovka_morning_taken_time") as? Double {
            return Date(timeIntervalSince1970: interval)
        }
        return nil
    }() {
        didSet {
            if let date = morningPillsTakenTime {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "lekovka_morning_taken_time")
            } else {
                UserDefaults.standard.removeObject(forKey: "lekovka_morning_taken_time")
            }
        }
    }
    @Published var morningTimeRemaining: String = ""
    @Published var morningScheduleID: Int? {
        didSet {
            if let id = morningScheduleID {
                UserDefaults.standard.set(id, forKey: "lekovka_morning_schedule_id")
            } else {
                UserDefaults.standard.removeObject(forKey: "lekovka_morning_schedule_id")
            }
        }
    }
    
    // MARK: - Published Properties (Evening)
    @Published var eveningHour: Int = UserDefaults.standard.object(forKey: "lekovka_evening_hour") as? Int ?? 20 {
        didSet { UserDefaults.standard.set(eveningHour, forKey: "lekovka_evening_hour") }
    }
    @Published var eveningMinute: Int = UserDefaults.standard.object(forKey: "lekovka_evening_minute") as? Int ?? 0 {
        didSet { UserDefaults.standard.set(eveningMinute, forKey: "lekovka_evening_minute") }
    }
    @Published var isEveningActive: Bool = UserDefaults.standard.bool(forKey: "lekovka_evening_active") {
        didSet { UserDefaults.standard.set(isEveningActive, forKey: "lekovka_evening_active") }
    }
    @Published var eveningPillsTaken: Bool = UserDefaults.standard.bool(forKey: "lekovka_evening_taken") {
        didSet { UserDefaults.standard.set(eveningPillsTaken, forKey: "lekovka_evening_taken") }
    }
    @Published var eveningPillsTakenTime: Date? = {
        if let interval = UserDefaults.standard.object(forKey: "lekovka_evening_taken_time") as? Double {
            return Date(timeIntervalSince1970: interval)
        }
        return nil
    }() {
        didSet {
            if let date = eveningPillsTakenTime {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "lekovka_evening_taken_time")
            } else {
                UserDefaults.standard.removeObject(forKey: "lekovka_evening_taken_time")
            }
        }
    }
    @Published var eveningTimeRemaining: String = ""
    @Published var eveningScheduleID: Int? {
        didSet {
            if let id = eveningScheduleID {
                UserDefaults.standard.set(id, forKey: "lekovka_evening_schedule_id")
            } else {
                UserDefaults.standard.removeObject(forKey: "lekovka_evening_schedule_id")
            }
        }
    }
    
    // MARK: - General
    @Published var reminderCount: Int = 0
    
    /// Convenience: true if both pills have been taken
    var allPillsTaken: Bool {
        morningPillsTaken && eveningPillsTaken
    }
    
    // Legacy compatibility
    var pillsTaken: Bool {
        get { allPillsTaken }
    }
    var pillsTakenTime: Date? {
        [morningPillsTakenTime, eveningPillsTakenTime].compactMap { $0 }.max()
    }
    var isTimerActive: Bool {
        isMorningActive || isEveningActive
    }
    
    // MARK: - Private Properties
    private var morningTimer: Timer?
    private var eveningTimer: Timer?
    private var morningTargetDate: Date? = {
        if let interval = UserDefaults.standard.object(forKey: "lekovka_morning_target") as? Double {
            return Date(timeIntervalSince1970: interval)
        }
        return nil
    }() {
        didSet {
            if let d = morningTargetDate {
                UserDefaults.standard.set(d.timeIntervalSince1970, forKey: "lekovka_morning_target")
            } else {
                UserDefaults.standard.removeObject(forKey: "lekovka_morning_target")
            }
        }
    }
    
    private var eveningTargetDate: Date? = {
        if let interval = UserDefaults.standard.object(forKey: "lekovka_evening_target") as? Double {
            return Date(timeIntervalSince1970: interval)
        }
        return nil
    }() {
        didSet {
            if let d = eveningTargetDate {
                UserDefaults.standard.set(d.timeIntervalSince1970, forKey: "lekovka_evening_target")
            } else {
                UserDefaults.standard.removeObject(forKey: "lekovka_evening_target")
            }
        }
    }
    
    /// How many minutes between repeat reminders.
    var reminderIntervalMinutes: Int {
        let saved = UserDefaults.standard.integer(forKey: "lekovka_notify_after_minutes")
        return saved > 0 ? saved : 1
    }
    
    init() {
        if let mID = UserDefaults.standard.object(forKey: "lekovka_morning_schedule_id") as? Int {
            self.morningScheduleID = mID
        }
        if let eID = UserDefaults.standard.object(forKey: "lekovka_evening_schedule_id") as? Int {
            self.eveningScheduleID = eID
        }
        
        // Resume local visual countdowns if active and not marked taken yet
        if isMorningActive && !morningPillsTaken && morningTargetDate != nil {
            startCountdownTimer(for: .morning)
        }
        if isEveningActive && !eveningPillsTaken && eveningTargetDate != nil {
            startCountdownTimer(for: .evening)
        }
        
        // Auto-reset rollover tracking
        checkAndResetForNewDay()
        
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
    
    // MARK: - Formatted Times
    func formattedMorningTime() -> String {
        String(format: "%02d:%02d", morningHour, morningMinute)
    }
    
    func formattedEveningTime() -> String {
        String(format: "%02d:%02d", eveningHour, eveningMinute)
    }
    
    // Legacy compatibility
    var targetHour: Int {
        get { morningHour }
        set { morningHour = newValue }
    }
    var targetMinute: Int {
        get { morningMinute }
        set { morningMinute = newValue }
    }
    var timeRemainingString: String {
        morningTimeRemaining
    }
    func formattedTime() -> String {
        formattedMorningTime()
    }
    
    // MARK: - Start Both Timers
    func startBothTimers() {
        startMorningTimer()
        startEveningTimer()
    }
    
    // MARK: - Morning Timer
    func startMorningTimer() {
        guard !morningPillsTaken else { return }
        
        cancelReminders(prefix: "morning")
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = morningHour
        components.minute = morningMinute
        components.second = 0
        
        guard var date = calendar.date(from: components) else { return }
        
        if date <= Date() {
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        morningTargetDate = date
        isMorningActive = true
        
        scheduleNotification(
            at: date,
            title: "🌅 Morning pills!",
            body: "It's \(formattedMorningTime()) — time for your morning medication.",
            identifier: "morning_reminder_main"
        )
        
        let intervalSeconds = TimeInterval(reminderIntervalMinutes * 60)
        for i in 1...10 {
            let reminderDate = date.addingTimeInterval(intervalSeconds * Double(i))
            scheduleNotification(
                at: reminderDate,
                title: "⏰ Morning Reminder #\(i)",
                body: "You still haven't taken your morning pills! It's been \(i * reminderIntervalMinutes) minutes.",
                identifier: "morning_reminder_followup_\(i)"
            )
        }
        
        startCountdownTimer(for: .morning)
    }
    
    // MARK: - Evening Timer
    func startEveningTimer() {
        guard !eveningPillsTaken else { return }
        
        cancelReminders(prefix: "evening")
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = eveningHour
        components.minute = eveningMinute
        components.second = 0
        
        guard var date = calendar.date(from: components) else { return }
        
        if date <= Date() {
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        eveningTargetDate = date
        isEveningActive = true
        
        scheduleNotification(
            at: date,
            title: "🌙 Evening pills!",
            body: "It's \(formattedEveningTime()) — time for your evening medication.",
            identifier: "evening_reminder_main"
        )
        
        let intervalSeconds = TimeInterval(reminderIntervalMinutes * 60)
        for i in 1...10 {
            let reminderDate = date.addingTimeInterval(intervalSeconds * Double(i))
            scheduleNotification(
                at: reminderDate,
                title: "⏰ Evening Reminder #\(i)",
                body: "You still haven't taken your evening pills! It's been \(i * reminderIntervalMinutes) minutes.",
                identifier: "evening_reminder_followup_\(i)"
            )
        }
        
        startCountdownTimer(for: .evening)
    }
    
    // MARK: - Stop Timers
    func stopMorningTimer() {
        isMorningActive = false
        morningTargetDate = nil
        morningTimeRemaining = ""
        morningTimer?.invalidate()
        morningTimer = nil
        cancelReminders(prefix: "morning")
        
        // Delete specifically the morning schedule from backend using the persisted ID
        if let id = morningScheduleID {
            deleteScheduleFromAPI(id: id)
            morningScheduleID = nil
        }
    }
    
    func stopEveningTimer() {
        isEveningActive = false
        eveningTargetDate = nil
        eveningTimeRemaining = ""
        eveningTimer?.invalidate()
        eveningTimer = nil
        cancelReminders(prefix: "evening")
        
        // Delete specifically the evening schedule from backend using the persisted ID
        if let id = eveningScheduleID {
            deleteScheduleFromAPI(id: id)
            eveningScheduleID = nil
        }
    }
    
    func stopTimer() {
        stopMorningTimer()
        stopEveningTimer()
    }
    
    // MARK: - Mark Pills Taken
    func markMorningPillsTaken() {
        morningPillsTaken = true
        morningPillsTakenTime = Date()
        morningTimer?.invalidate()
        morningTimer = nil
        cancelReminders(prefix: "morning") // Clear any remaining alarms for today
    }
    
    func markEveningPillsTaken() {
        eveningPillsTaken = true
        eveningPillsTakenTime = Date()
        eveningTimer?.invalidate()
        eveningTimer = nil
        cancelReminders(prefix: "evening") // Clear any remaining alarms for today
    }
    
    /// Legacy: marks both as taken
    func markPillsTaken() {
        if !morningPillsTaken { markMorningPillsTaken() }
        if !eveningPillsTaken { markEveningPillsTaken() }
    }
    
    // MARK: - Reset
    func checkAndResetForNewDay() {
        let calendar = Calendar.current
        let now = Date()
        var needsMorningRestart = false
        var needsEveningRestart = false
        
        // Morning Rollover check
        if isMorningActive {
            if morningPillsTaken, let takenTime = morningPillsTakenTime {
                if !calendar.isDate(now, inSameDayAs: takenTime) {
                    morningPillsTaken = false
                    morningPillsTakenTime = nil
                    needsMorningRestart = true
                }
            } else if !morningPillsTaken, let targetDate = morningTargetDate {
                if !calendar.isDate(now, inSameDayAs: targetDate) && targetDate < now {
                    needsMorningRestart = true
                }
            }
        }
        
        // Evening Rollover check
        if isEveningActive {
            if eveningPillsTaken, let takenTime = eveningPillsTakenTime {
                if !calendar.isDate(now, inSameDayAs: takenTime) {
                    eveningPillsTaken = false
                    eveningPillsTakenTime = nil
                    needsEveningRestart = true
                }
            } else if !eveningPillsTaken, let targetDate = eveningTargetDate {
                if !calendar.isDate(now, inSameDayAs: targetDate) && targetDate < now {
                    needsEveningRestart = true
                }
            }
        }
        
        if needsMorningRestart {
            startMorningTimer()
        }
        if needsEveningRestart {
            startEveningTimer()
        }
    }
    
    func resetForNewDay() {
        morningPillsTaken = false
        morningPillsTakenTime = nil
        eveningPillsTaken = false
        eveningPillsTakenTime = nil
        reminderCount = 0
    }
    
    // MARK: - Schedule Configuration JSON (for ESP32)
    /// Builds the post-configuration-schedule JSON to send to ESP32.
    func buildConfigurationScheduleJSON() -> String? {
        let payload: [String: Any] = [
            "action": "post-configuration-schedule",
            "body": [
                "morning": [
                    "interval_alert_trigger_minutes": reminderIntervalMinutes,
                    "alert": formattedMorningTime()
                ],
                "evening": [
                    "interval_alert_trigger_minutes": reminderIntervalMinutes,
                    "alert": formattedEveningTime()
                ]
            ]
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }
    
    // MARK: - API Response Model
    struct ScheduleResponse: Codable {
        let id: Int
        let scheduled_time: String
        let user_id: Int
    }
    
    // MARK: - Send Schedule to REST API
    func sendScheduleToAPI() {
        let baseURL = AuthManager.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/schedules") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let userId = UserDefaults.standard.string(forKey: "lekovka_user_id") {
            request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        }
        
        let morningTime = formattedMorningTime()
        let eveningTime = formattedEveningTime()
        
        let body: [String: String] = [
            "time1": morningTime,
            "time2": eveningTime
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Schedule API error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode),
               let data = data {
                
                do {
                    let schedules = try JSONDecoder().decode([ScheduleResponse].self, from: data)
                    
                    // Match the returned IDs to morning vs evening based on their scheduled_time
                    DispatchQueue.main.async {
                        for schedule in schedules {
                            // Trim seconds if API returns "08:00:00" instead of "08:00"
                            let timePrefix = String(schedule.scheduled_time.prefix(5))
                            if timePrefix == morningTime {
                                self.morningScheduleID = schedule.id
                                print("✅ Saved morning schedule ID: \(schedule.id)")
                            } else if timePrefix == eveningTime {
                                self.eveningScheduleID = schedule.id
                                print("✅ Saved evening schedule ID: \(schedule.id)")
                            }
                        }
                    }
                } catch {
                    print("❌ Failed to decode schedules: \(error)")
                }
            } else {
                 let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                 print("📡 Schedule API response: HTTP \(status)")
            }
        }.resume()
    }
    
    // MARK: - Delete Specific Schedule from API
    private func deleteScheduleFromAPI(id: Int) {
        let baseURL = AuthManager.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/schedules/\(id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let userId = UserDefaults.standard.string(forKey: "lekovka_user_id") {
            request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        }
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse {
                print("🗑️ Deleted schedule ID \(id), API response: HTTP \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    // MARK: - Private Helpers
    
    private enum TimerSlot {
        case morning, evening
    }
    
    private func startCountdownTimer(for slot: TimerSlot) {
        switch slot {
        case .morning:
            morningTimer?.invalidate()
            morningTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self, let target = self.morningTargetDate else { return }
                let remaining = target.timeIntervalSince(Date())
                DispatchQueue.main.async {
                    if remaining <= 0 {
                        self.morningTimeRemaining = "Time's up!"
                        self.morningTimer?.invalidate()
                        self.morningTimer = nil
                    } else {
                        let h = Int(remaining) / 3600
                        let m = (Int(remaining) % 3600) / 60
                        let s = Int(remaining) % 60
                        self.morningTimeRemaining = String(format: "%02d:%02d:%02d", h, m, s)
                    }
                }
            }
        case .evening:
            eveningTimer?.invalidate()
            eveningTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self, let target = self.eveningTargetDate else { return }
                let remaining = target.timeIntervalSince(Date())
                DispatchQueue.main.async {
                    if remaining <= 0 {
                        self.eveningTimeRemaining = "Time's up!"
                        self.eveningTimer?.invalidate()
                        self.eveningTimer = nil
                    } else {
                        let h = Int(remaining) / 3600
                        let m = (Int(remaining) % 3600) / 60
                        let s = Int(remaining) % 60
                        self.eveningTimeRemaining = String(format: "%02d:%02d:%02d", h, m, s)
                    }
                }
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
    
    private func cancelReminders(prefix: String) {
        var identifiers = ["\(prefix)_reminder_main"]
        for i in 1...10 {
            identifiers.append("\(prefix)_reminder_followup_\(i)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
