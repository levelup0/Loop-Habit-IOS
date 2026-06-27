import SwiftUI
import SwiftData

struct CreateHabitView: View {
    let type: HabitType
    let nextSortOrder: Int
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var colorHex = "#E53935"
    @State private var question = ""
    @State private var habitNotes = ""
    @State private var frequencyType: FrequencyType = .everyDay
    @State private var numerator = 1
    @State private var denominator = 1
    @State private var daysOfWeek: Set<Int> = Set(1...7)
    @State private var reminderHour = -1
    @State private var reminderMinute = 0

    // Measurable-only
    @State private var unit = ""
    @State private var targetValue = 0.0
    @State private var targetType: TargetType = .atLeast

    @State private var showingColorPicker = false
    @State private var showingFrequencyPicker = false
    @State private var showingReminderPicker = false
    @State private var reminderDate: Date = {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        c.hour = 8; c.minute = 0
        return Calendar.current.date(from: c) ?? .now
    }()

    private let palette = Color.loopPalette

    var body: some View {
        NavigationStack {
            Form {
                // Name + Color
                Section {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Name").font(.caption).foregroundStyle(.secondary)
                            TextField("e.g. Exercise", text: $name)
                                .font(.body)
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

                // Question
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Question").font(.caption).foregroundStyle(.secondary)
                        TextField(
                            type == .yesNo
                                ? "e.g. Did you exercise today?"
                                : "e.g. How many miles did you run today?",
                            text: $question,
                            axis: .vertical
                        )
                        .lineLimit(2...)
                    }
                }

                // Measurable-only fields
                if type == .measurable {
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
                                TextField("e.g. 15", value: $targetValue, format: .number)
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

                // Frequency (yes/no)
                if type == .yesNo {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Frequency").font(.caption).foregroundStyle(.secondary)
                            Button(frequencyDescription) { showingFrequencyPicker = true }
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                // Reminder
                Section {
                    Toggle(isOn: $showingReminderPicker) {
                        HStack {
                            Label("Reminder", systemImage: "bell")
                            Spacer()
                            if reminderHour >= 0 {
                                Text(String(format: "%02d:%02d", reminderHour, reminderMinute))
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .onChange(of: showingReminderPicker) { _, on in
                        if on {
                            let c = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
                            reminderHour = c.hour ?? 8
                            reminderMinute = c.minute ?? 0
                        } else {
                            reminderHour = -1
                        }
                    }
                    if showingReminderPicker {
                        DatePicker("Time", selection: $reminderDate, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .onChange(of: reminderDate) { _, d in
                                let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                                reminderHour = c.hour ?? reminderHour
                                reminderMinute = c.minute ?? reminderMinute
                            }
                    }
                }

                // Notes
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes").font(.caption).foregroundStyle(.secondary)
                        TextField("(Optional)", text: $habitNotes, axis: .vertical)
                            .lineLimit(3...)
                    }
                }
            }
            .navigationTitle(type == .yesNo ? "Yes or No" : "Measurable")
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
        let h = Habit(
            name: name.trimmingCharacters(in: .whitespaces),
            colorHex: colorHex,
            sortOrder: nextSortOrder,
            frequencyType: frequencyType
        )
        h.habitType = type
        h.question = question
        h.habitNotes = habitNotes
        h.frequencyNumerator = numerator
        h.frequencyDenominator = denominator
        h.daysOfWeek = Array(daysOfWeek).sorted()
        h.unit = unit
        h.targetValue = targetValue
        h.targetType = targetType
        h.reminderHour = reminderHour
        h.reminderMinute = reminderMinute
        context.insert(h)
        ReminderManager.schedule(for: h)
        dismiss()
    }
}
