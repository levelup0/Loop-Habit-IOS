import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var nextSortOrder: Int = 0

    @State private var name = ""
    @State private var colorHex = "#5856D6"
    @State private var selectedDays: Set<Int> = Set(1...7)

    private let dayLabels = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    private let palette = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#5AC8FA", "#007AFF", "#5856D6", "#AF52DE", "#FF2D55"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например: Медитация", text: $name)
                }

                Section("Цвет") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 8) {
                        ForEach(palette, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(height: 32)
                                .overlay {
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Дни недели") {
                    HStack(spacing: 4) {
                        ForEach(1...7, id: \.self) { day in
                            let on = selectedDays.contains(day)
                            Text(dayLabels[day - 1])
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(on ? (Color(hex: colorHex) ?? .accentColor) : Color(.systemGray5))
                                .foregroundStyle(on ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .onTapGesture {
                                    if on { selectedDays.remove(day) }
                                    else  { selectedDays.insert(day) }
                                }
                        }
                    }
                }
            }
            .navigationTitle("Новая привычка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }

    private func save() {
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespaces),
            colorHex: colorHex,
            daysOfWeek: Array(selectedDays).sorted(),
            sortOrder: nextSortOrder
        )
        context.insert(habit)
        dismiss()
    }
}
