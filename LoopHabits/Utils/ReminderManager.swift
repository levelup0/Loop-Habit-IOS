import UserNotifications
import Foundation

enum ReminderManager {
    static func schedule(for habit: Habit) {
        guard habit.reminderHour >= 0 else { return }
        cancel(for: habit)

        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = habit.question.isEmpty ? "Time to track your habit!" : habit.question
        content.sound = .default

        // Schedule for each applicable day of week
        // If specificDays — use daysOfWeek; otherwise repeat daily
        let days: [Int]
        if habit.frequencyType == .specificDays && !habit.daysOfWeek.isEmpty {
            // daysOfWeek stores 1=Mon..7=Sun; UNCalendarTrigger weekday 1=Sun..7=Sat
            days = habit.daysOfWeek.map { loopDay -> Int in
                // Loop 1(Mon)→UNS 2, Loop 7(Sun)→UNS 1
                loopDay == 7 ? 1 : loopDay + 1
            }
        } else {
            days = [1, 2, 3, 4, 5, 6, 7]  // every day
        }

        for weekday in days {
            var components = DateComponents()
            components.hour    = habit.reminderHour
            components.minute  = habit.reminderMinute
            components.weekday = weekday

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let id = notificationID(habit: habit, weekday: weekday)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    static func cancel(for habit: Habit) {
        let ids = (1...7).map { notificationID(habit: habit, weekday: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func notificationID(habit: Habit, weekday: Int) -> String {
        "\(habit.id.uuidString)-wd\(weekday)"
    }
}
