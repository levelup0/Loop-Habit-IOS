import Foundation
import SwiftData

@Model
final class Habit {
    // MARK: - Stored properties (all new ones have defaults for SwiftData auto-migration)
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    var sortOrder: Int
    var isArchived: Bool

    // Type: 0=yesNo, 1=measurable
    var typeRaw: Int = 0
    var question: String = ""
    var habitNotes: String = ""

    // Measurable-only
    var unit: String = ""
    var targetValue: Double = 0.0
    var targetTypeRaw: Int = 0  // 0=atLeast, 1=atMost

    // Frequency: 0=everyDay,1=everyNDays,2=timesPerWeek,3=timesPerMonth,4=timesInPeriod,5=specificDays
    var frequencyTypeRaw: Int = 0
    var frequencyNumerator: Int = 1
    var frequencyDenominator: Int = 1
    var daysOfWeek: [Int] = Array(1...7)  // 1=Mon…7=Sun, used when frequencyType==.specificDays

    // Reminder (-1 = off)
    var reminderHour: Int = -1
    var reminderMinute: Int = 0

    @Relationship(deleteRule: .cascade) var entries: [HabitEntry] = []

    init(
        name: String,
        colorHex: String = "#E53935",
        sortOrder: Int = 0,
        frequencyType: FrequencyType = .everyDay
    ) {
        self.id           = UUID()
        self.name         = name
        self.colorHex     = colorHex
        self.createdAt    = Date()
        self.sortOrder    = sortOrder
        self.isArchived   = false
        self.frequencyTypeRaw = frequencyType.rawValue
    }

    // MARK: - Typed accessors

    var habitType: HabitType {
        get { HabitType(rawValue: typeRaw) ?? .yesNo }
        set { typeRaw = newValue.rawValue }
    }

    var targetType: TargetType {
        get { TargetType(rawValue: targetTypeRaw) ?? .atLeast }
        set { targetTypeRaw = newValue.rawValue }
    }

    var frequencyType: FrequencyType {
        get { FrequencyType(rawValue: frequencyTypeRaw) ?? .everyDay }
        set { frequencyTypeRaw = newValue.rawValue }
    }

    /// Frequency as a daily probability (used in score formula)
    var frequency: Double {
        switch frequencyType {
        case .everyDay:      return 1.0
        case .everyNDays:    return 1.0 / Double(max(1, frequencyDenominator))
        case .timesPerWeek:  return Double(frequencyNumerator) / 7.0
        case .timesPerMonth: return Double(frequencyNumerator) / 30.0
        case .timesInPeriod: return Double(frequencyNumerator) / Double(max(1, frequencyDenominator))
        case .specificDays:  return Double(daysOfWeek.count) / 7.0
        }
    }

    // MARK: - Scheduling

    func isScheduled(on date: Date) -> Bool {
        let cal = Calendar.current
        switch frequencyType {
        case .everyDay:
            return true
        case .specificDays:
            let wd = cal.component(.weekday, from: date)
            let dayNum = wd == 1 ? 7 : wd - 1
            return daysOfWeek.contains(dayNum)
        case .everyNDays:
            let days = cal.dateComponents([.day], from: cal.startOfDay(for: createdAt), to: cal.startOfDay(for: date)).day ?? 0
            return days >= 0 && days % max(1, frequencyDenominator) == 0
        case .timesPerWeek, .timesPerMonth, .timesInPeriod:
            return true
        }
    }

    var isScheduledToday: Bool { isScheduled(on: .now) }

    // MARK: - Completion

    func completed(on date: Date) -> Bool {
        let cal = Calendar.current
        return entries.contains { cal.isDate($0.date, inSameDayAs: date) && $0.isDone }
    }

    var completedToday: Bool { completed(on: .now) }

    var totalCompletions: Int {
        entries.filter { $0.isDone }.count
    }

    // MARK: - Score (exact Android formula)

    private func scoreIncrement(previousScore: Double, checkmarkValue: Double) -> Double {
        let multiplier = pow(0.5, sqrt(frequency) / 13.0)
        return previousScore * multiplier + checkmarkValue * (1.0 - multiplier)
    }

    /// Compute score up to (and including) a given date
    func score(asOf endDate: Date) -> Double {
        let cal = Calendar.current
        let end = cal.startOfDay(for: endDate)
        guard let start = cal.date(byAdding: .year, value: -1, to: end) else { return 0 }

        var s = 0.0
        var day = start
        while day <= end {
            if isScheduled(on: day) {
                let done = completed(on: day) ? 1.0 : 0.0
                s = scoreIncrement(previousScore: s, checkmarkValue: done)
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return s
    }

    var score: Double { score(asOf: .now) }
    var monthlyScore: Double { score(asOf: Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now) }
    var yearlyScore: Double  { score(asOf: Calendar.current.date(byAdding: .year,  value: -1, to: .now) ?? .now) }

    // MARK: - Score history for chart

    func scoreHistory(groupBy: ScoreGrouping) -> [(Date, Double)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let start = cal.date(byAdding: .year, value: -1, to: today) else { return [] }

        var dailyScores: [(Date, Double)] = []
        var s = 0.0
        var day = start
        while day <= today {
            if isScheduled(on: day) {
                let done = completed(on: day) ? 1.0 : 0.0
                s = scoreIncrement(previousScore: s, checkmarkValue: done)
            }
            dailyScores.append((day, s))
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        switch groupBy {
        case .day:
            return dailyScores
        case .week:
            let grouped = Dictionary(grouping: dailyScores) { point -> Date in
                cal.dateInterval(of: .weekOfYear, for: point.0)?.start ?? point.0
            }
            return grouped.map { ($0.key, $0.value.last!.1) }.sorted { $0.0 < $1.0 }
        case .month:
            let grouped = Dictionary(grouping: dailyScores) { point -> Date in
                cal.dateInterval(of: .month, for: point.0)?.start ?? point.0
            }
            return grouped.map { ($0.key, $0.value.last!.1) }.sorted { $0.0 < $1.0 }
        }
    }

    // MARK: - History bar chart data

    func completionHistory(groupBy: HistoryGrouping) -> [(Date, Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let lookback: Calendar.Component
        let groupUnit: Calendar.Component
        switch groupBy {
        case .week:  lookback = .month;  groupUnit = .weekOfYear
        case .month: lookback = .year;   groupUnit = .month
        case .year:  lookback = .year;   groupUnit = .year
        }
        guard let start = cal.date(byAdding: lookback, value: -2, to: today) else { return [] }

        let doneEntries = entries.filter { $0.isDone && $0.date >= start }
        let grouped = Dictionary(grouping: doneEntries) { entry -> Date in
            cal.dateInterval(of: groupUnit, for: entry.date)?.start ?? entry.date
        }
        return grouped.map { ($0.key, $0.value.count) }.sorted { $0.0 < $1.0 }
    }

    // MARK: - Streaks

    var currentStreak: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let limit = cal.date(byAdding: .year, value: -2, to: today) else { return 0 }
        var streak = 0
        var day = today
        while day >= limit {
            if isScheduled(on: day) {
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

    var bestStreaks: [Streak] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let limit = cal.date(byAdding: .year, value: -2, to: today) else { return [] }

        var streaks: [Streak] = []
        var streakStart: Date? = nil
        var day = limit

        while day <= today {
            if isScheduled(on: day) {
                if completed(on: day) {
                    if streakStart == nil { streakStart = day }
                } else {
                    if let start = streakStart {
                        let end = cal.date(byAdding: .day, value: -1, to: day) ?? day
                        streaks.append(Streak(start: start, end: end))
                        streakStart = nil
                    }
                }
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        if let start = streakStart {
            streaks.append(Streak(start: start, end: today))
        }
        return streaks.sorted { $0.length > $1.length }.prefix(10).map { $0 }
    }

    var bestStreakLength: Int { bestStreaks.first?.length ?? 0 }

    // MARK: - Frequency dot grid (56 weeks × 7 days, Mon=0)

    func frequencyGrid() -> [[Bool]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let numWeeks = 56
        let wd = cal.component(.weekday, from: today)
        let daysToMonday = wd == 1 ? 6 : wd - 2
        guard let thisMonday = cal.date(byAdding: .day, value: -daysToMonday, to: today) else { return [] }

        return (0..<numWeeks).map { weekOffset in
            let monday = cal.date(byAdding: .weekOfYear, value: -(numWeeks - 1 - weekOffset), to: thisMonday)!
            return (0..<7).map { dayOffset in
                guard let date = cal.date(byAdding: .day, value: dayOffset, to: monday) else { return false }
                return date <= today && completed(on: date)
            }
        }
    }
}
