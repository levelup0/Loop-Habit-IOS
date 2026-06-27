import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var colorHex: String
    var daysOfWeek: [Int]   // 1=Mon … 7=Sun
    var createdAt: Date
    var sortOrder: Int
    var isArchived: Bool
    @Relationship(deleteRule: .cascade) var entries: [HabitEntry]

    init(name: String, colorHex: String = "#5856D6", daysOfWeek: [Int] = Array(1...7), sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.daysOfWeek = daysOfWeek
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.isArchived = false
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

    var bestStreak: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let limit = cal.date(byAdding: .year, value: -2, to: today) else { return 0 }

        var best = 0
        var current = 0
        var day = limit

        while day <= today {
            let wd = cal.component(.weekday, from: day)
            let dayNum = wd == 1 ? 7 : wd - 1
            if daysOfWeek.contains(dayNum) {
                if completed(on: day) {
                    current += 1
                    best = max(best, current)
                } else {
                    current = 0
                }
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return best
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
