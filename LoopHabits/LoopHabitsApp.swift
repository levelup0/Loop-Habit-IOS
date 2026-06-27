import SwiftUI
import SwiftData

@main
struct LoopHabitsApp: App {
    var body: some Scene {
        WindowGroup {
            HabitListView()
        }
        .modelContainer(for: [Habit.self, HabitEntry.self])
    }
}
