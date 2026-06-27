import SwiftUI
import SwiftData

enum SortMode: String, CaseIterable {
    case manual  = "Manually"
    case name    = "By name"
    case color   = "By color"
    case score   = "By score"
    case status  = "By status"
}

let columnWidth: CGFloat = 40
let rowHeight:   CGFloat = 56
let headerHeight: CGFloat = 44

struct HabitListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)]) private var habits: [Habit]

    @AppStorage("hideCompleted") private var hideCompleted = false
    @AppStorage("isDarkMode") private var isDarkMode = true

    @State private var showingTypeSelector = false
    @State private var selectedHabitType: HabitType? = nil
    @State private var showingCreate = false
    @State private var showingSettings = false
    @State private var hideArchived = true
    @State private var sortMode: SortMode = .manual

    // Today is index 0 (leftmost). Dates go: today, yesterday, ...59 days ago
    private var visibleDates: [Date] {
        let today = Calendar.current.startOfDay(for: .now)
        return (0..<60).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: today) }
    }

    private var displayedHabits: [Habit] {
        var list = habits.filter { hideArchived ? !$0.isArchived : true }
        if hideCompleted { list = list.filter { !$0.completedToday } }
        switch sortMode {
        case .manual:  break
        case .name:    list.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .color:   list.sort { $0.colorHex < $1.colorHex }
        case .score:   list.sort { $0.score > $1.score }
        case .status:  list.sort { $0.completedToday && !$1.completedToday }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(UIColor.systemBackground).ignoresSafeArea()

                if displayedHabits.isEmpty {
                    emptyState
                } else {
                    habitGrid
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingTypeSelector = true } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterMenu
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingTypeSelector) {
                HabitTypePickerSheet(selectedType: $selectedHabitType)
                    .onChange(of: selectedHabitType) { _, newType in
                        if newType != nil {
                            showingTypeSelector = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                showingCreate = true
                            }
                        }
                    }
            }
            .sheet(isPresented: $showingCreate, onDismiss: { selectedHabitType = nil }) {
                CreateHabitView(type: selectedHabitType ?? .yesNo, nextSortOrder: habits.count)
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Habit grid

    private var habitGrid: some View {
        GeometryReader { geo in
            let labelWidth = geo.size.width - columnWidth * 7  // show ~7 columns by default
            let clampedLabel = max(120, min(200, labelWidth))

            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    // Fixed left label column
                    LazyVStack(spacing: 0) {
                        Color.clear.frame(height: headerHeight)
                        ForEach(displayedHabits) { habit in
                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                HabitLabelCell(habit: habit)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(habit.isArchived ? "Unarchive" : "Archive") {
                                    habit.isArchived.toggle()
                                }
                                Button("Delete", role: .destructive) {
                                    context.delete(habit)
                                }
                            }
                            Divider().opacity(0.3)
                        }
                    }
                    .frame(width: clampedLabel)

                    // Shared horizontal scroll — today is leftmost (index 0)
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(spacing: 0) {
                            DateHeaderRow(dates: visibleDates)
                            ForEach(displayedHabits) { habit in
                                HabitDatesRow(habit: habit, dates: visibleDates)
                                Divider().opacity(0.3)
                            }
                        }
                        .frame(width: columnWidth * CGFloat(visibleDates.count))
                    }
                    // Discrete snapping: each column = columnWidth
                    .scrollTargetBehavior(.paging)
                    // Start at left edge = today
                    .defaultScrollAnchor(.leading)
                }
            }
        }
    }

    // MARK: - Filter menu

    private var filterMenu: some View {
        Menu {
            Toggle("Hide archived", isOn: $hideArchived)
            Toggle("Hide entered today", isOn: $hideCompleted)
            Divider()
            Menu("Sort") {
                Picker("Sort", selection: $sortMode) {
                    ForEach(SortMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No habits yet")
                .font(.title3.bold())
            Text("Tap + to add your first habit")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - HabitLabelCell

struct HabitLabelCell: View {
    let habit: Habit

    private var habitColor: Color { Color(hex: habit.colorHex) ?? .accentColor }

    var body: some View {
        HStack(spacing: 10) {
            ScoreRingView(score: habit.score, color: habitColor, size: 32, lineWidth: 3.5)
            Text(habit.name)
                .font(.body)
                .foregroundStyle(habitColor)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(height: rowHeight)
    }
}

// MARK: - DateHeaderRow

struct DateHeaderRow: View {
    let dates: [Date]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(dates, id: \.self) { date in
                let isToday = Calendar.current.isDateInToday(date)
                VStack(spacing: 1) {
                    Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                        .font(.system(size: 9, weight: .medium))
                    Text(date.formatted(.dateTime.day()))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(isToday ? Color.primary : Color.secondary)
                .frame(width: columnWidth)
            }
        }
        .frame(height: headerHeight)
    }
}

// MARK: - HabitDatesRow

struct HabitDatesRow: View {
    @Environment(\.modelContext) private var context
    let habit: Habit
    let dates: [Date]

    @State private var showingNumberSheet = false
    @State private var numberSheetDate: Date = .now
    @State private var numberSheetEntry: HabitEntry? = nil
    @State private var numberResult: Double? = nil
    // Bump to force re-render after SwiftData mutations
    @State private var tick: Int = 0

    private var habitColor: Color { Color(hex: habit.colorHex) ?? .accentColor }
    private let cal = Calendar.current

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(dates.enumerated()), id: \.offset) { idx, date in
                let entry = habit.entries.first(where: { cal.isDate($0.date, inSameDayAs: date) })
                if habit.habitType == .measurable {
                    let numVal: Double? = entry.flatMap { $0.numericValue > 0 ? $0.numericValue : nil }
                    NumberButton(
                        value: numVal,
                        targetValue: habit.targetValue,
                        targetType: habit.targetType,
                        color: habitColor,
                        isToday: cal.isDateInToday(date),
                        onTap: {
                            numberSheetDate = date
                            numberSheetEntry = entry
                            showingNumberSheet = true
                        }
                    )
                } else {
                    // Compute effective value (accounting for YES_AUTO)
                    let effectiveVal = effectiveValue(for: date, entry: entry)
                    CheckmarkButton(
                        value: effectiveVal,
                        isScheduled: habit.isScheduled(on: date),
                        color: habitColor,
                        isToday: cal.isDateInToday(date),
                        onTap: { cycle(date: date, entry: entry) }
                    )
                }
            }
        }
        .frame(height: rowHeight)
        .id(tick)  // force redraw when tick changes
        .sheet(isPresented: $showingNumberSheet) {
            NumberEntrySheet(
                habitName: habit.name,
                unit: habit.unit,
                targetValue: habit.targetValue,
                currentValue: numberSheetEntry?.numericValue,
                result: $numberResult
            )
            .onChange(of: numberResult) { _, v in
                guard let v else { return }
                commitNumeric(date: numberSheetDate, entry: numberSheetEntry, newValue: v)
                numberResult = nil
                numberSheetEntry = nil
            }
        }
    }

    // YES_AUTO: if habit has period-based frequency and period is already satisfied,
    // untracked days in that period show as yesAuto
    private func effectiveValue(for date: Date, entry: HabitEntry?) -> Int {
        if let e = entry { return e.value }

        // Only compute auto for period-based types
        guard habit.frequencyType == .timesPerWeek ||
              habit.frequencyType == .timesPerMonth ||
              habit.frequencyType == .timesInPeriod else {
            return CheckmarkValue.no.rawValue
        }

        let periodDays: Int
        switch habit.frequencyType {
        case .timesPerWeek:  periodDays = 7
        case .timesPerMonth: periodDays = 30
        case .timesInPeriod: periodDays = max(1, habit.frequencyDenominator)
        default: return CheckmarkValue.no.rawValue
        }
        let needed = habit.frequencyNumerator

        // Find the period window that contains this date
        guard let windowStart = cal.date(byAdding: .day, value: -(periodDays - 1), to: date),
              let windowEnd   = cal.date(byAdding: .day, value:  (periodDays - 1), to: date) else {
            return CheckmarkValue.no.rawValue
        }

        // Count YES_MANUAL entries whose period window overlaps this date
        let manualInWindow = habit.entries.filter { e in
            guard e.value == CheckmarkValue.yesManual.rawValue else { return false }
            let eDay = cal.startOfDay(for: e.date)
            guard let eWindowStart = cal.date(byAdding: .day, value: -(periodDays - 1), to: eDay),
                  let eWindowEnd   = cal.date(byAdding: .day, value:  (periodDays - 1), to: eDay) else { return false }
            // Check overlap: entry's window overlaps our date
            return eDay >= windowStart && eDay <= windowEnd
        }

        return manualInWindow.count >= needed ? CheckmarkValue.yesAuto.rawValue : CheckmarkValue.no.rawValue
    }

    // Cycle: NO→YES_MANUAL→SKIP→NO (only YES_MANUAL is stored; YES_AUTO and NO have no entry)
    private func cycle(date: Date, entry: HabitEntry?) {
        // Determine current stored value (ignore yesAuto — it's computed, not stored)
        let storedVal = entry?.value ?? CheckmarkValue.no.rawValue
        let next = nextCheckmarkValue(storedVal)

        if next == CheckmarkValue.no.rawValue {
            if let e = entry {
                context.delete(e)
                habit.entries.removeAll { $0.id == e.id }
            }
        } else if let e = entry {
            e.value = next
        } else {
            let e = HabitEntry(date: date, value: CheckmarkValue(rawValue: next) ?? .yesManual)
            context.insert(e)
            habit.entries.append(e)
        }
        tick += 1
    }

    private func commitNumeric(date: Date, entry: HabitEntry?, newValue: Double) {
        if newValue <= 0 {
            if let e = entry {
                context.delete(e)
                habit.entries.removeAll { $0.id == e.id }
            }
        } else if let e = entry {
            e.numericValue = newValue
            e.value = CheckmarkValue.yesManual.rawValue
        } else {
            let e = HabitEntry(date: date, numericValue: newValue)
            context.insert(e)
            habit.entries.append(e)
        }
        tick += 1
    }
}

#Preview {
    HabitListView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}
