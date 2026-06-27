import SwiftUI
import SwiftData

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss

    let habit: Habit

    @State private var name: String
    @State private var colorHex: String
    @State private var selectedDays: Set<Int>

    private let dayLabels = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    private let palette = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#5AC8FA", "#007AFF", "#5856D6", "#AF52DE", "#FF2D55"
    ]

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _colorHex = State(initialValue: habit.colorHex)
        _selectedDays = State(initialValue: Set(habit.daysOfWeek))
    }

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
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }

    private func save() {
        habit.name = name.trimmingCharacters(in: .whitespaces)
        habit.colorHex = colorHex
        habit.daysOfWeek = Array(selectedDays).sorted()
        dismiss()
    }
}
