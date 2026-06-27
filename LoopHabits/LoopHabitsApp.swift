import SwiftUI
import SwiftData
import UserNotifications

@main
struct LoopHabitsApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var importURL: URL? = nil

    var body: some Scene {
        WindowGroup {
            HabitListView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onAppear { requestNotificationPermission() }
                // Handle .db file opened via Files.app or "Open With"
                .onOpenURL { url in importURL = url }
                .sheet(item: $importURL) { url in
                    ImportConfirmSheet(url: url)
                }
        }
        .modelContainer(for: [Habit.self, HabitEntry.self])
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}

// URL needs to be Identifiable for .sheet(item:)
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// Confirmation sheet shown when a .db file is opened externally
struct ImportConfirmSheet: View {
    let url: URL
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var message: String? = nil
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)

                Text("Import Backup")
                    .font(.title2.bold())

                Text(url.lastPathComponent)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let msg = message {
                    Text(msg)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if isImporting {
                    ProgressView()
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if message == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import") { doImport() }
                            .fontWeight(.semibold)
                            .disabled(isImporting)
                    }
                } else {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func doImport() {
        isImporting = true
        let secured = url.startAccessingSecurityScopedResource()
        do {
            let result = try importFromLoopDB(url: url, context: context)
            if secured { url.stopAccessingSecurityScopedResource() }
            message = "✓ Imported \(result.habitsImported) habits and \(result.entriesImported) entries." +
                (result.skipped > 0 ? "\nSkipped \(result.skipped) duplicates." : "")
        } catch {
            if secured { url.stopAccessingSecurityScopedResource() }
            message = "Import failed:\n\(error.localizedDescription)"
        }
        isImporting = false
    }
}
