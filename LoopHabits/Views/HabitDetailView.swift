import SwiftUI
import SwiftData
import Charts

struct HabitDetailView: View {
    @Environment(\.modelContext) private var context
    let habit: Habit
    private let cal = Calendar.current

    @State private var showingEdit = false
    @State private var scoreGrouping: ScoreGrouping = .day
    @State private var historyGrouping: HistoryGrouping = .week

    private var habitColor: Color { Color(hex: habit.colorHex) ?? .accentColor }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                detailHeader
                overviewCard
                scoreCard
                historyCard
                calendarCard
                bestStreaksCard
                frequencyGridCard
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit") { showingEdit = true }
                    Divider()
                    Button(habit.isArchived ? "Unarchive" : "Archive") {
                        habit.isArchived.toggle()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditHabitView(habit: habit)
        }
    }

    // MARK: - 1. Header

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(habit.name)
                .font(.title2.bold())
                .foregroundStyle(habitColor)

            if !habit.question.isEmpty {
                Text(habit.question)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label(frequencySummary, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(habit.reminderHour == -1 ? "Off" : reminderText, systemImage: "bell")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var frequencySummary: String {
        switch habit.frequencyType {
        case .everyDay:      return "Every day"
        case .everyNDays:    return "Every \(habit.frequencyDenominator) days"
        case .timesPerWeek:  return "\(habit.frequencyNumerator)x per week"
        case .timesPerMonth: return "\(habit.frequencyNumerator)x per month"
        case .timesInPeriod: return "\(habit.frequencyNumerator) in \(habit.frequencyDenominator) days"
        case .specificDays:  return "\(habit.daysOfWeek.count) days/week"
        }
    }

    private var reminderText: String {
        String(format: "%02d:%02d", habit.reminderHour, habit.reminderMinute)
    }

    // MARK: - 2. Overview card

    private var overviewCard: some View {
        cardContainer(title: "Overview") {
            HStack(spacing: 24) {
                // Large score ring with % inside
                ZStack {
                    ScoreRingView(score: habit.score, color: habitColor, size: 80, lineWidth: 8)
                    Text("\(Int(habit.score * 100))%")
                        .font(.title3.bold())
                        .foregroundStyle(habitColor)
                }

                VStack(alignment: .leading, spacing: 10) {
                    statRow("Score",  "\(Int(habit.score * 100))%")
                    statRow("Month",  scoreDelta(habit.score, habit.monthlyScore))
                    statRow("Year",   scoreDelta(habit.score, habit.yearlyScore))
                    statRow("Total",  "\(habit.totalCompletions)")
                }
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.primary)
        }
    }

    private func scoreDelta(_ current: Double, _ past: Double) -> String {
        let delta = Int((current - past) * 100)
        return delta >= 0 ? "+\(delta)%" : "\(delta)%"
    }

    // MARK: - 3. Score chart

    private var scoreCard: some View {
        cardContainer(title: "Score") {
            HStack {
                Spacer()
                Picker("", selection: $scoreGrouping) {
                    ForEach(ScoreGrouping.allCases) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(.bottom, 4)

            let data = habit.scoreHistory(groupBy: scoreGrouping)
            if data.isEmpty {
                Text("No data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
            } else {
                Chart(data, id: \.0) { point in
                    AreaMark(
                        x: .value("Date", point.0),
                        yStart: .value("Base", 0),
                        yEnd: .value("Score", point.1 * 100)
                    )
                    .foregroundStyle(habitColor.opacity(0.2))

                    LineMark(
                        x: .value("Date", point.0),
                        y: .value("Score", point.1 * 100)
                    )
                    .foregroundStyle(habitColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(.circle)
                    .symbolSize(20)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) {
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 160)
            }
        }
    }

    // MARK: - 4. History bar chart

    private var historyCard: some View {
        cardContainer(title: "History") {
            HStack {
                Spacer()
                Picker("", selection: $historyGrouping) {
                    ForEach(HistoryGrouping.allCases) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            .padding(.bottom, 4)

            let data = habit.completionHistory(groupBy: historyGrouping)
            if data.isEmpty {
                Text("No data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
            } else {
                Chart(data, id: \.0) { point in
                    BarMark(
                        x: .value("Period", point.0),
                        y: .value("Count", point.1)
                    )
                    .foregroundStyle(habitColor)
                    .cornerRadius(3)
                }
                .frame(height: 120)
            }
        }
    }

    // MARK: - 5. Calendar grid (13 weeks)

    private var calendarCard: some View {
        cardContainer(title: "Calendar") {
            VStack(spacing: 4) {
                // Day-of-week header
                HStack(spacing: 4) {
                    ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], id: \.self) { d in
                        Text(d)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // 13 weeks grid
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { i in
                            if let day = week[i] {
                                calendarDot(day)
                            } else {
                                Color.clear.frame(maxWidth: .infinity, minHeight: 22)
                            }
                        }
                    }
                }
            }
        }
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
    private func calendarDot(_ day: Date) -> some View {
        let scheduled = habit.daysOfWeek.isEmpty || habit.isScheduled(on: day)
        let entry = habit.entries.first(where: { cal.isDate($0.date, inSameDayAs: day) })
        let entryVal = entry?.checkmarkValue ?? .no
        let done = entryVal == .yesManual || entryVal == .yesAuto
        let isSkip = entryVal == .skip
        let isToday = cal.isDateInToday(day)

        ZStack {
            Circle()
                .fill(done ? habitColor : Color.clear)
                .overlay {
                    if !done && !isSkip && scheduled {
                        Circle().strokeBorder(habitColor.opacity(0.3), lineWidth: 1)
                    }
                    if isSkip {
                        Circle().strokeBorder(habitColor.opacity(0.4), lineWidth: 1)
                    }
                    if isToday {
                        Circle().strokeBorder(.primary.opacity(0.5), lineWidth: 1.5)
                    }
                }
            if isSkip {
                Rectangle()
                    .fill(habitColor.opacity(0.5))
                    .frame(width: 8, height: 1.5)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22)
        .onTapGesture { if scheduled { toggleDay(day) } }
    }

    private func toggleDay(_ day: Date) {
        let existing = habit.entries.first(where: { cal.isDate($0.date, inSameDayAs: day) })
        let current = existing?.value ?? CheckmarkValue.no.rawValue
        let next = nextCheckmarkValue(current)
        if next == CheckmarkValue.no.rawValue {
            if let e = existing { context.delete(e) }
        } else if let e = existing {
            e.value = next
        } else {
            let e = HabitEntry(date: day, value: CheckmarkValue(rawValue: next) ?? .yesManual)
            context.insert(e)
            habit.entries.append(e)
        }
    }

    // MARK: - 6. Best Streaks

    private var bestStreaksCard: some View {
        cardContainer(title: "Best Streaks") {
            let streaks = habit.bestStreaks
            if streaks.isEmpty {
                Text("No streaks yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                let best = Double(streaks.first?.length ?? 1)
                VStack(spacing: 12) {
                    ForEach(streaks.prefix(5)) { streak in
                        HStack(spacing: 8) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(streak.start, format: .dateTime.month(.abbreviated).day().year())
                                Text(streak.end, format: .dateTime.month(.abbreviated).day().year())
                            }
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .trailing)

                            GeometryReader { geo in
                                let ratio = Double(streak.length) / best
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(habitColor)
                                    .frame(width: geo.size.width * ratio, height: 10)
                                    .frame(maxHeight: .infinity, alignment: .center)
                            }

                            Text("\(streak.length)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(habitColor)
                                .frame(width: 32, alignment: .trailing)
                        }
                        .frame(height: 32)
                    }
                }
            }
        }
    }

    // MARK: - 7. Frequency dot grid

    private var frequencyGridCard: some View {
        cardContainer(title: "Frequency") {
            let grid = habit.frequencyGrid()  // [[Bool]], 56 weeks × 7 days
            let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

            HStack(alignment: .top, spacing: 4) {
                // Day labels on right
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(dayLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 7))
                            .foregroundStyle(.secondary)
                            .frame(height: 10)
                    }
                }
                .padding(.top, 2)

                // Dot grid (weeks as columns)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(Array(grid.enumerated()), id: \.offset) { _, week in
                            VStack(spacing: 2) {
                                ForEach(0..<7, id: \.self) { dayIdx in
                                    Circle()
                                        .fill(week[dayIdx] ? habitColor : habitColor.opacity(0.15))
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                }
                .defaultScrollAnchor(.trailing)
            }
        }
    }

    // MARK: - Card container helper

    private func cardContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}
