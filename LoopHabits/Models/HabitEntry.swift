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
    var value: Int      // CheckmarkValue raw value; 2 = yesManual
    var entryNotes: String

    init(date: Date = .now, value: CheckmarkValue = .yesManual, notes: String = "") {
        self.id         = UUID()
        self.date       = date
        self.value      = value.rawValue
        self.entryNotes = notes
    }

    var checkmarkValue: CheckmarkValue {
        CheckmarkValue(rawValue: value) ?? .no
    }

    var isDone: Bool {
        value == CheckmarkValue.yesManual.rawValue || value == CheckmarkValue.yesAuto.rawValue
    }
}
