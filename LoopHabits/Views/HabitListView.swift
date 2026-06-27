import SwiftUI
import SwiftData

enum SortMode: String, CaseIterable {
    case manual  = "Manually"
    case name    = "By name"
    case color   = "By color"
    case score   = "By score"
    case status  = "By status"
}

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

    // Last 60 days, most recent first (rightmost column = today)
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

    // MARK: - Habit grid (fixed left column + shared horizontal scroll)

    private var habitGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                // Left: fixed label column
                LazyVStack(spacing: 0) {
                    Color.clear.frame(height: 44)  // spacer matching date header height
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
                .frame(width: 180)

                // Right: single shared horizontal scroll for all date columns
                // scrollTargetBehavior(.viewAligned) gives discrete per-column snapping
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        DateHeaderRow(dates: visibleDates)
                        ForEach(displayedHabits) { habit in
                            HabitDatesRow(habit: habit, dates: visibleDates)
                            Divider().opacity(0.3)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .defaultScrollAnchor(.trailing)
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
        .frame(height: 56)
    }
}

// MARK: - DateHeaderRow

struct DateHeaderRow: View {
    let dates: [Date]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(dates, id: \.self) { date in
                VStack(spacing: 1) {
                    Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                        .font(.system(size: 9, weight: .medium))
                    Text(date.formatted(.dateTime.day()))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(
                    Calendar.current.isDateInToday(date) ? Color.primary : Color.secondary
                )
                .frame(width: 40)
            }
        }
        .frame(height: 44)
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

    private var habitColor: Color { Color(hex: habit.colorHex) ?? .accentColor }
    private let cal = Calendar.current

    var body: some View {
        HStack(spacing: 0) {
            ForEach(dates, id: \.self) { date in
                let entry = habit.entries.first(where: { cal.isDate($0.date, inSameDayAs: date) })
                if habit.habitType == .measurable {
                    let numVal: Double? = entry.flatMap { $0.numericValue > 0 ? $0.numericValue : nil }
                    NumberButton(
                        value: numVal,
                        unit: habit.unit,
                        color: habitColor,
                        isToday: cal.isDateInToday(date),
                        onTap: {
                            numberSheetDate = date
                            numberSheetEntry = entry
                            showingNumberSheet = true
                        }
                    )
                } else {
                    let currentValue = entry?.value ?? CheckmarkValue.no.rawValue
                    CheckmarkButton(
                        value: currentValue,
                        isScheduled: habit.isScheduled(on: date),
                        color: habitColor,
                        isToday: cal.isDateInToday(date),
                        onTap: { cycle(date: date, entry: entry, current: currentValue) }
                    )
                }
            }
        }
        .frame(height: 56)
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

    // Mirrors Android Entry.nextToggleValue(): NO→YES_MANUAL→SKIP→NO
    private func cycle(date: Date, entry: HabitEntry?, current: Int) {
        let next = nextCheckmarkValue(current)
        if next == CheckmarkValue.no.rawValue {
            if let e = entry { context.delete(e) }
        } else if let e = entry {
            e.value = next
        } else {
            let e = HabitEntry(date: date, value: CheckmarkValue(rawValue: next) ?? .yesManual)
            context.insert(e)
            habit.entries.append(e)
        }
    }

    private func commitNumeric(date: Date, entry: HabitEntry?, newValue: Double) {
        if newValue <= 0 {
            if let e = entry { context.delete(e) }
            return
        }
        if let e = entry {
            e.numericValue = newValue
            e.value = CheckmarkValue.yesManual.rawValue
        } else {
            let e = HabitEntry(date: date, numericValue: newValue)
            context.insert(e)
            habit.entries.append(e)
        }
    }
}

#Preview {
    HabitListView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}
