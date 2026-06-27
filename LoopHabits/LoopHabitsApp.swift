import SwiftUI
import SwiftData

@main
struct LoopHabitsApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some Scene {
        WindowGroup {
            HabitListView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .modelContainer(for: [Habit.self, HabitEntry.self])
    }
}
