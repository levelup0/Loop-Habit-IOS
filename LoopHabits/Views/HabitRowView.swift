import SwiftUI
import SwiftData

struct HabitRowView: View {
    @Environment(\.modelContext) private var context
    let habit: Habit

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: habit.colorHex) ?? .accentColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                Text("Серия: \(habit.currentStreak) дн.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if habit.isScheduledToday {
                Button(action: toggleToday) {
                    Image(systemName: habit.completedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(
                            habit.completedToday
                                ? (Color(hex: habit.colorHex) ?? .accentColor)
                                : .secondary
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func toggleToday() {
        if let entry = habit.entries.first(where: { Calendar.current.isDateInToday($0.date) }) {
            context.delete(entry)
        } else {
            let entry = HabitEntry(date: .now)
            context.insert(entry)
            habit.entries.append(entry)
        }
    }
}
