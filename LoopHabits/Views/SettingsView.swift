import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("firstDayOfWeek") private var firstDayOfWeek = 1  // 1=Mon
    @AppStorage("hideCompleted") private var hideCompleted = false

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
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
