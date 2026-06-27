import SwiftUI
import SwiftData
import UserNotifications

@main
struct LoopHabitsApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some Scene {
        WindowGroup {
            HabitListView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onAppear { requestNotificationPermission() }
        }
        .modelContainer(for: [Habit.self, HabitEntry.self])
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
