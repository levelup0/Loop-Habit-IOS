import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)]) private var habits: [Habit]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                        HabitRowView(habit: habit)
                    }
                }
                .onDelete(perform: delete)
                .onMove(perform: move)
            }
            .navigationTitle("Привычки")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddHabitView(nextSortOrder: habits.count)
            }
            .overlay {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "Нет привычек",
                        systemImage: "checkmark.circle",
                        description: Text("Нажмите + чтобы добавить первую привычку")
                    )
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        offsets.forEach { context.delete(habits[$0]) }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = habits
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
