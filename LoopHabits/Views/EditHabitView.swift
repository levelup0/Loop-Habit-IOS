import SwiftUI

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    let habit: Habit

    @State private var name: String
    @State private var colorHex: String
    @State private var question: String
    @State private var habitNotes: String
    @State private var frequencyType: FrequencyType
    @State private var numerator: Int
    @State private var denominator: Int
    @State private var daysOfWeek: Set<Int>
    @State private var unit: String
    @State private var targetValue: Double
    @State private var targetType: TargetType

    @State private var showingColorPicker = false
    @State private var showingFrequencyPicker = false

    init(habit: Habit) {
        self.habit = habit
        _name         = State(initialValue: habit.name)
        _colorHex     = State(initialValue: habit.colorHex)
        _question     = State(initialValue: habit.question)
        _habitNotes   = State(initialValue: habit.habitNotes)
        _frequencyType = State(initialValue: habit.frequencyType)
        _numerator    = State(initialValue: habit.frequencyNumerator)
        _denominator  = State(initialValue: habit.frequencyDenominator)
        _daysOfWeek   = State(initialValue: Set(habit.daysOfWeek))
        _unit         = State(initialValue: habit.unit)
        _targetValue  = State(initialValue: habit.targetValue)
        _targetType   = State(initialValue: habit.targetType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Name").font(.caption).foregroundStyle(.secondary)
                            TextField("e.g. Exercise", text: $name)
                        }
                        Spacer()
                        VStack(alignment: .center, spacing: 4) {
                            Text("Color").font(.caption).foregroundStyle(.secondary)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: colorHex) ?? .accentColor)
                                .frame(width: 44, height: 44)
                                .onTapGesture { showingColorPicker = true }
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Question").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. Did you exercise today?", text: $question, axis: .vertical)
                            .lineLimit(2...)
                    }
                }

                if habit.habitType == .measurable {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Unit").font(.caption).foregroundStyle(.secondary)
                            TextField("e.g. miles", text: $unit)
                        }
                    }
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Target").font(.caption).foregroundStyle(.secondary)
                                TextField("0", value: $targetValue, format: .number)
                                    .keyboardType(.decimalPad)
                            }
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Frequency").font(.caption).foregroundStyle(.secondary)
                                Button(frequencyDescription) { showingFrequencyPicker = true }
                                    .foregroundStyle(.primary)
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Type").font(.caption).foregroundStyle(.secondary)
                            Picker("", selection: $targetType) {
                                Text("At least").tag(TargetType.atLeast)
                                Text("At most").tag(TargetType.atMost)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }

                if habit.habitType == .yesNo {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Frequency").font(.caption).foregroundStyle(.secondary)
                            Button(frequencyDescription) { showingFrequencyPicker = true }
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes").font(.caption).foregroundStyle(.secondary)
                        TextField("(Optional)", text: $habitNotes, axis: .vertical)
                            .lineLimit(3...)
                    }
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerSheet(colorHex: $colorHex)
            }
            .sheet(isPresented: $showingFrequencyPicker) {
                FrequencyPickerView(
                    frequencyType: $frequencyType,
                    numerator: $numerator,
                    denominator: $denominator,
                    daysOfWeek: $daysOfWeek
                )
            }
        }
    }

    private var frequencyDescription: String {
        switch frequencyType {
        case .everyDay:      return "Every day"
        case .everyNDays:    return "Every \(denominator) days"
        case .timesPerWeek:  return "\(numerator) times per week"
        case .timesPerMonth: return "\(numerator) times per month"
        case .timesInPeriod: return "\(numerator) times in \(denominator) days"
        case .specificDays:  return "\(daysOfWeek.count) days per week"
        }
    }

    private func save() {
        habit.name              = name.trimmingCharacters(in: .whitespaces)
        habit.colorHex          = colorHex
        habit.question          = question
        habit.habitNotes        = habitNotes
        habit.frequencyType     = frequencyType
        habit.frequencyNumerator   = numerator
        habit.frequencyDenominator = denominator
        habit.daysOfWeek        = Array(daysOfWeek).sorted()
        habit.unit              = unit
        habit.targetValue       = targetValue
        habit.targetType        = targetType
        dismiss()
    }
}
