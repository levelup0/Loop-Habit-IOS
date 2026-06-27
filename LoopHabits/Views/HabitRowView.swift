import SwiftUI

// Legacy row view — kept for compatibility; main list now uses HabitLabelCell + HabitDatesRow
struct HabitRowView: View {
    let habit: Habit

    var body: some View {
        HabitLabelCell(habit: habit)
    }
}
