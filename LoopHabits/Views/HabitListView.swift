import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)]) private var habits: [Habit]
    @State private var showingAdd = false
    @State private var showingArchive = false

    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }
    private var archivedHabits: [Habit] { habits.filter { $0.isArchived } }
    private var displayedHabits: [Habit] { showingArchive ? archivedHabits : activeHabits }

    var body: some View {
        NavigationStack {
            List {
                ForEach(displayedHabits) { habit in
                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                        HabitRowView(habit: habit)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            habit.isArchived.toggle()
                        } label: {
                            Label(
                                habit.isArchived ? "Восстановить" : "Архив",
                                systemImage: habit.isArchived ? "tray.and.arrow.up" : "archivebox"
                            )
                        }
                        .tint(habit.isArchived ? .green : .orange)
                    }
                }
                .onDelete(perform: delete)
                .onMove(perform: showingArchive ? nil : move)
            }
            .navigationTitle(showingArchive ? "Архив" : "Привычки")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !showingArchive {
                        Button { showingAdd = true } label: { Image(systemName: "plus") }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !showingArchive {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showingArchive.toggle()
                    } label: {
                        Label(
                            showingArchive ? "Активные привычки" : "Показать архив (\(archivedHabits.count))",
                            systemImage: showingArchive ? "list.bullet" : "archivebox"
                        )
                        .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddHabitView(nextSortOrder: habits.count)
            }
            .overlay {
                if displayedHabits.isEmpty {
                    ContentUnavailableView(
                        showingArchive ? "Архив пуст" : "Нет привычек",
                        systemImage: showingArchive ? "archivebox" : "checkmark.circle",
                        description: Text(showingArchive ? "Архивированные привычки появятся здесь" : "Нажмите + чтобы добавить первую привычку")
                    )
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let source = displayedHabits
        offsets.forEach { context.delete(source[$0]) }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = activeHabits
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, habit) in reordered.enumerated() {
            habit.sortOrder = index
        }
    }
}

#Preview {
    HabitListView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}
