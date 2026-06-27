import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.modelContext) private var context
    let habit: Habit
    private let cal = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statsCard
                calendarCard
            }
            .padding()
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Stats

    private var statsCard: some View {
        HStack {
            stat("\(habit.currentStreak)", "Серия")
            Divider().frame(height: 40)
            stat(completionRate, "За 90 дней")
            Divider().frame(height: 40)
            stat("\(habit.entries.count)", "Всего")
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var completionRate: String {
        let today = cal.startOfDay(for: .now)
        let scheduled = (0..<90).compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }.filter { d in
            let wd = cal.component(.weekday, from: d)
            return habit.daysOfWeek.contains(wd == 1 ? 7 : wd - 1)
        }
        guard !scheduled.isEmpty else { return "—" }
        let done = scheduled.filter { habit.completed(on: $0) }.count
        return "\(Int(Double(done) / Double(scheduled.count) * 100))%"
    }

    // MARK: Calendar grid (13 weeks, Mon–Sun)

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("История").font(.headline)
            HStack(spacing: 4) {
                ForEach(["Пн","Вт","Ср","Чт","Пт","Сб","Вс"], id: \.self) { d in
                    Text(d).font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { i in
                        if let day = week[i] {
                            dayCell(day)
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 22)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var weeks: [[Date?]] {
        let today = cal.startOfDay(for: .now)
        let wd = cal.component(.weekday, from: today)
        let fromMon = wd == 1 ? 6 : wd - 2
        let thisMonday = cal.date(byAdding: .day, value: -fromMon, to: today)!
        return (0..<13).reversed().map { wk in
            let mon = cal.date(byAdding: .weekOfYear, value: -wk, to: thisMonday)!
            return (0..<7).map { d -> Date? in
                let day = cal.date(byAdding: .day, value: d, to: mon)!
                return day <= today ? day : nil
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: Date) -> some View {
        let wd = cal.component(.weekday, from: day)
        let dayNum = wd == 1 ? 7 : wd - 1
        let scheduled = habit.daysOfWeek.contains(dayNum)
        let done = habit.completed(on: day)

        RoundedRectangle(cornerRadius: 4)
            .fill(
                done      ? (Color(hex: habit.colorHex) ?? .accentColor) :
                scheduled ? Color(.systemGray4) : Color.clear
            )
            .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22)
            .overlay {
                if cal.isDateInToday(day) {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(.primary.opacity(0.4), lineWidth: 1.5)
                }
            }
            .onTapGesture { if scheduled { toggle(day) } }
    }

    private func toggle(_ day: Date) {
        if let e = habit.entries.first(where: { cal.isDate($0.date, inSameDayAs: day) }) {
            context.delete(e)
        } else {
            let e = HabitEntry(date: day)
            context.insert(e)
            habit.entries.append(e)
        }
    }
}
