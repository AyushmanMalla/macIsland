import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    private var hasPermission = false

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                if let error = error {
                    print("NotchFlow: Notification permission error: \(error)")
                }
            }
        }
    }

    func sendPomodoroNotification(for state: PomodoroState) {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        switch state {
        case .working:
            content.title = "Focus Time! 🎯"
            content.body = "Time to focus for 25 minutes. Let's go!"
        case .shortBreak:
            content.title = "Short Break ☕"
            content.body = "Great work! Take a 5-minute break."
        case .longBreak:
            content.title = "Long Break 🎉"
            content.body = "4 sessions done! Enjoy a 15-minute break."
        case .idle, .paused:
            return
        }

        let request = UNNotificationRequest(
            identifier: "pomodoro-\(UUID().uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("NotchFlow: Failed to send notification: \(error)")
            }
        }
    }
}
