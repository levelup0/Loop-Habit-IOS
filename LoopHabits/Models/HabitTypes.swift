import Foundation

enum HabitType: Int, Codable, CaseIterable {
    case yesNo      = 0
    case measurable = 1
}

enum TargetType: Int, Codable, CaseIterable {
    case atLeast = 0
    case atMost  = 1
}

enum FrequencyType: Int, Codable, CaseIterable {
    case everyDay       = 0
    case everyNDays     = 1
    case timesPerWeek   = 2
    case timesPerMonth  = 3
    case timesInPeriod  = 4
    case specificDays   = 5
}

struct Streak: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    var length: Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day! + 1
    }
}

enum ScoreGrouping: String, CaseIterable, Identifiable {
    case day   = "Day"
    case week  = "Week"
    case month = "Month"
    var id: String { rawValue }
}

enum HistoryGrouping: String, CaseIterable, Identifiable {
    case week  = "Week"
    case month = "Month"
    case year  = "Year"
    var id: String { rawValue }
}
