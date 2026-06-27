import Foundation
import SwiftData

// Entry value constants (mirrors Android uhabits)
enum CheckmarkValue: Int {
    case no        = 0
    case yesAuto   = 1
    case yesManual = 2
    case skip      = 3
}

@Model
final class HabitEntry {
    var id: UUID
    var date: Date
    var value: Int          // CheckmarkValue raw value; 2 = yesManual
    var numericValue: Double // for Measurable habits; 0 = not set
    var entryNotes: String

    init(date: Date = .now, value: CheckmarkValue = .yesManual, notes: String = "") {
        self.id           = UUID()
        self.date         = date
        self.value        = value.rawValue
        self.numericValue = 0
        self.entryNotes   = notes
    }

    init(date: Date, numericValue: Double, notes: String = "") {
        self.id           = UUID()
        self.date         = date
        self.value        = numericValue > 0 ? CheckmarkValue.yesManual.rawValue : CheckmarkValue.no.rawValue
        self.numericValue = numericValue
        self.entryNotes   = notes
    }

    var checkmarkValue: CheckmarkValue {
        CheckmarkValue(rawValue: value) ?? .no
    }

    var isDone: Bool {
        value == CheckmarkValue.yesManual.rawValue || value == CheckmarkValue.yesAuto.rawValue
    }
}
