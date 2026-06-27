import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var colorHex: String
    var daysOfWeek: [Int]   // 1=Mon … 7=Sun
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var entries: [HabitEntry]

    init(name: String, colorHex: String = "#5856D6", daysOfWeek: [Int] = Array(1...7)) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.daysOfWeek = daysOfWeek
        self.createdAt = Date()
        self.entries = []
    }

    var isScheduledToday: Bool {
        let wd = Calendar.current.component(.weekday, from: .now)
        let day = wd == 1 ? 7 : wd - 1
        return daysOfWeek.contains(day)
    }

    var completedToday: Bool {
        entries.contains { Calendar.current.isDateInToday($0.date) }
    }

    func completed(on date: Date) -> Bool {
        entries.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var currentStreak: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let limit = cal.date(byAdding: .year, value: -1, to: today)!
        var streak = 0
        var day = today

        while day >= limit {
            let wd = cal.component(.weekday, from: day)
            let dayNum = wd == 1 ? 7 : wd - 1
            if daysOfWeek.contains(dayNum) {
                if completed(on: day) {
                    streak += 1
                } else if day < today {
                    break
                }
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }
}

@Model
final class HabitEntry {
    var id: UUID
    var date: Date

    init(date: Date = .now) {
        self.id = UUID()
        self.date = date
    }
}
