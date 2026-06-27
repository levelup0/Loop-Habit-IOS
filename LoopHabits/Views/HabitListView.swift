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

    // Today is index 0 (leftmost). Dates: today, yesterday, ..., 59 days ago
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
                if displayedHabits.isEmpty { emptyState } else { habitGrid }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingTypeSelector = true } label: {
                        Image(systemName: "plus").font(.body.weight(.semibold))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) { filterMenu }
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { showingCreate = true }
                        }
                    }
            }
            .sheet(isPresented: $showingCreate, onDismiss: { selectedHabitType = nil }) {
                CreateHabitView(type: selectedHabitType ?? .yesNo, nextSortOrder: habits.count)
            }
            .navigationDestination(isPresented: $showingSettings) { SettingsView() }
        }
    }

    // MARK: - Grid

    private var habitGrid: some View {
        GeometryReader { geo in
            let labelWidth = max(120, geo.size.width - columnWidth * 7)

            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    // Fixed label column
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
                                Button("Delete", role: .destructive) { context.delete(habit) }
                            }
                            Divider().opacity(0.3)
                        }
                    }
                    .frame(width: labelWidth)

                    // Shared horizontal scroll — today is leftmost, snaps per column
                    ScrollView(.horizontal, showsIndicators: false) {
                        // Outer LazyHStack: one item per day column, each columnWidth wide.
                        // .scrollTargetLayout() on this makes .viewAligned snap column-by-column.
                        LazyHStack(spacing: 0) {
                            ForEach(Array(visibleDates.enumerated()), id: \.offset) { idx, date in
                                VStack(spacing: 0) {
                                    // Header cell
                                    DateHeaderCell(date: date)
                                    // One cell per habit
                                    ForEach(displayedHabits) { habit in
                                        HabitDayCell(habit: habit, date: date)
                                        Divider().opacity(0.3)
                                    }
                                }
                                .frame(width: columnWidth)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .defaultScrollAnchor(.leading)
                }
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Toggle("Hide archived", isOn: $hideArchived)
            Toggle("Hide entered today", isOn: $hideCompleted)
            Divider()
            Menu("Sort") {
                Picker("Sort", selection: $sortMode) {
                    ForEach(SortMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.inline)
            }
        } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle").font(.system(size: 56)).foregroundStyle(.secondary)
            Text("No habits yet").font(.title3.bold())
            Text("Tap + to add your first habit").font(.subheadline).foregroundStyle(.secondary)
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
                .font(.body).foregroundStyle(habitColor)
                .lineLimit(2).multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.leading, 16).padding(.trailing, 8)
        .frame(height: rowHeight)
    }
}

// MARK: - DateHeaderCell (single column)

struct DateHeaderCell: View {
    let date: Date

    var body: some View {
        let isToday = Calendar.current.isDateInToday(date)
        VStack(spacing: 1) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                .font(.system(size: 9, weight: .medium))
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(isToday ? Color.primary : Color.secondary)
        .frame(width: columnWidth, height: headerHeight)
    }
}

// MARK: - HabitDayCell
// Each cell queries its own entry so SwiftData changes trigger redraw

struct HabitDayCell: View {
    @Environment(\.modelContext) private var context
    let habit: Habit
    let date: Date

    @Query private var entries: [HabitEntry]

    private var cal: Calendar { Calendar.current }
    private var habitColor: Color { Color(hex: habit.colorHex) ?? .accentColor }
    private var entry: HabitEntry? { entries.first }

    @State private var showingNumberSheet = false

    init(habit: Habit, date: Date) {
        self.habit = habit
        self.date = date
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd   = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
        let hid = habit.id
        _entries = Query(
            filter: #Predicate<HabitEntry> { e in
                e.habitID == hid && e.date >= dayStart && e.date < dayEnd
            },
            sort: []
        )
    }

    var body: some View {
        Group {
            if habit.habitType == .measurable {
                let numVal: Double? = entry.flatMap { $0.numericValue > 0 ? $0.numericValue : nil }
                NumberButton(
                    value: numVal,
                    targetValue: habit.targetValue,
                    targetType: habit.targetType,
                    color: habitColor,
                    isToday: cal.isDateInToday(date),
                    onTap: { showingNumberSheet = true }
                )
                .sheet(isPresented: $showingNumberSheet) {
                    NumberEntrySheet(
                        habitName: habit.name,
                        unit: habit.unit,
                        targetValue: habit.targetValue,
                        currentValue: entry?.numericValue,
                        onSave: { v in commitNumeric(newValue: v) }
                    )
                }
            } else {
                let effectiveVal = effectiveValue()
                CheckmarkButton(
                    value: effectiveVal,
                    isScheduled: habit.isScheduled(on: date),
                    color: habitColor,
                    isToday: cal.isDateInToday(date),
                    onTap: { cycle() }
                )
            }
        }
        .frame(width: columnWidth, height: rowHeight)
    }

    // YES_AUTO: untracked day inside a satisfied period
    // Uses habit.entries (relationship) — good enough for auto detection
    private func effectiveValue() -> Int {
        if let e = entry { return e.value }

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
        default:             return CheckmarkValue.no.rawValue
        }
        let needed = habit.frequencyNumerator
        let dayStart = cal.startOfDay(for: date)
        guard let wStart = cal.date(byAdding: .day, value: -(periodDays - 1), to: dayStart) else {
            return CheckmarkValue.no.rawValue
        }
        let manualCount = habit.entries.filter { e in
            e.value == CheckmarkValue.yesManual.rawValue &&
            cal.startOfDay(for: e.date) >= wStart &&
            cal.startOfDay(for: e.date) <= dayStart
        }.count
        return manualCount >= needed ? CheckmarkValue.yesAuto.rawValue : CheckmarkValue.no.rawValue
    }

    private func cycle() {
        let stored = entry?.value ?? CheckmarkValue.no.rawValue
        let next   = nextCheckmarkValue(stored)
        if next == CheckmarkValue.no.rawValue {
            if let e = entry { context.delete(e) }
        } else if let e = entry {
            e.value = next
        } else {
            let e = HabitEntry(
                habitID: habit.id,
                date: cal.startOfDay(for: date),
                value: CheckmarkValue(rawValue: next) ?? .yesManual
            )
            context.insert(e)
        }
    }

    private func commitNumeric(newValue: Double) {
        if newValue <= 0 {
            if let e = entry { context.delete(e) }
            return
        }
        if let e = entry {
            e.numericValue = newValue
            e.value = CheckmarkValue.yesManual.rawValue
        } else {
            let e = HabitEntry(
                habitID: habit.id,
                date: cal.startOfDay(for: date),
                numericValue: newValue
            )
            context.insert(e)
        }
    }
}

#Preview {
    HabitListView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}
