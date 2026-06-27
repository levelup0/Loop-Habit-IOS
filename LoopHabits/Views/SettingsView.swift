import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// UTType for .db files
extension UTType {
    static let sqliteDB = UTType(importedAs: "public.database")
}

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("firstDayOfWeek") private var firstDayOfWeek = 1
    @AppStorage("hideCompleted") private var hideCompleted = false

    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Habit.sortOrder)]) private var habits: [Habit]

    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var exportURL: URL?
    @State private var alertMessage: String?
    @State private var showingAlert = false
    @State private var isProcessing = false

    var body: some View {
        Form {
            Section("Interface") {
                Toggle("Dark Theme", isOn: $isDarkMode)
                Picker("First Day of Week", selection: $firstDayOfWeek) {
                    Text("Monday").tag(1)
                    Text("Sunday").tag(7)
                }
                Toggle("Hide Entered Today", isOn: $hideCompleted)
            }

            Section("Backup") {
                Button {
                    prepareExport()
                } label: {
                    HStack {
                        Label("Export to .db", systemImage: "square.and.arrow.up")
                        if isProcessing { Spacer(); ProgressView() }
                    }
                }
                .disabled(isProcessing || habits.isEmpty)

                Button {
                    showingImporter = true
                } label: {
                    Label("Import from .db", systemImage: "square.and.arrow.down")
                }
                .disabled(isProcessing)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        // Import picker
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [UTType(filenameExtension: "db") ?? .data, .data],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        // Export share sheet
        .sheet(isPresented: $showingExporter) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
        .alert("", isPresented: $showingAlert, presenting: alertMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: - Export

    private func prepareExport() {
        isProcessing = true
        let snapshot = habits  // capture before leaving main actor
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LoopHabitsBackup.db")
        do {
            try exportToLoopDB(habits: snapshot, to: url)
            exportURL = url
            showingExporter = true
        } catch {
            alertMessage = "Export failed: \(error.localizedDescription)"
            showingAlert = true
        }
        isProcessing = false
    }

    // MARK: - Import

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            alertMessage = "Could not open file: \(error.localizedDescription)"
            showingAlert = true
        case .success(let urls):
            guard let url = urls.first else { return }
            isProcessing = true
            let securedAccess = url.startAccessingSecurityScopedResource()
            do {
                let importResult = try importFromLoopDB(url: url, context: context)
                if securedAccess { url.stopAccessingSecurityScopedResource() }
                alertMessage = "Imported \(importResult.habitsImported) habits and \(importResult.entriesImported) entries." +
                    (importResult.skipped > 0 ? " Skipped \(importResult.skipped) duplicates." : "")
            } catch {
                if securedAccess { url.stopAccessingSecurityScopedResource() }
                alertMessage = "Import failed: \(error.localizedDescription)"
            }
            isProcessing = false
            showingAlert = true
        }
    }
}

// MARK: - ShareSheet (UIActivityViewController wrapper)

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}
