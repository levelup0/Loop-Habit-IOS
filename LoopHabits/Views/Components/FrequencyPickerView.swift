import SwiftUI

struct FrequencyPickerView: View {
    @Binding var frequencyType: FrequencyType
    @Binding var numerator: Int
    @Binding var denominator: Int
    @Binding var daysOfWeek: Set<Int>
    @Environment(\.dismiss) private var dismiss

    // Separate local state per frequency type — no cross-contamination
    @State private var everyNDays: Int = 2
    @State private var timesPerWeek: Int = 3
    @State private var timesPerMonth: Int = 10
    @State private var timesInN: Int = 3
    @State private var timesInM: Int = 14

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            List {
                Section("Repeat") {
                    radioRow(.everyDay,      "Every day")
                    radioRow(.everyNDays,    "Every \(everyNDays) days")
                    radioRow(.timesPerWeek,  "\(timesPerWeek) times per week")
                    radioRow(.timesPerMonth, "\(timesPerMonth) times per month")
                    radioRow(.timesInPeriod, "\(timesInN) times in \(timesInM) days")
                    radioRow(.specificDays,  "Specific days of week")
                }

                if frequencyType == .everyNDays {
                    Section {
                        Stepper("Every \(everyNDays) days", value: $everyNDays, in: 2...365)
                    }
                }
                if frequencyType == .timesPerWeek {
                    Section {
                        Stepper("\(timesPerWeek) times per week", value: $timesPerWeek, in: 1...7)
                    }
                }
                if frequencyType == .timesPerMonth {
                    Section {
                        Stepper("\(timesPerMonth) times per month", value: $timesPerMonth, in: 1...31)
                    }
                }
                if frequencyType == .timesInPeriod {
                    Section {
                        Stepper("\(timesInN) times", value: $timesInN, in: 1...365)
                        Stepper("in \(timesInM) days", value: $timesInM, in: 2...365)
                    }
                }
                if frequencyType == .specificDays {
                    Section("Days of week") {
                        HStack(spacing: 6) {
                            ForEach(1...7, id: \.self) { day in
                                let on = daysOfWeek.contains(day)
                                Text(dayLabels[day - 1])
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(on ? Color.accentColor : Color(.systemGray5))
                                    .foregroundStyle(on ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .onTapGesture {
                                        if on { daysOfWeek.remove(day) }
                                        else  { daysOfWeek.insert(day) }
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Frequency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { commitAndDismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .onAppear { loadCurrentValues() }
    }

    // Populate local steppers from current bindings
    private func loadCurrentValues() {
        switch frequencyType {
        case .everyNDays:    everyNDays = max(2, denominator)
        case .timesPerWeek:  timesPerWeek = max(1, numerator)
        case .timesPerMonth: timesPerMonth = max(1, numerator)
        case .timesInPeriod: timesInN = max(1, numerator); timesInM = max(2, denominator)
        default: break
        }
    }

    // Write back to bindings on Save
    private func commitAndDismiss() {
        switch frequencyType {
        case .everyDay:
            numerator = 1; denominator = 1
        case .everyNDays:
            numerator = 1; denominator = everyNDays
        case .timesPerWeek:
            numerator = timesPerWeek; denominator = 7
        case .timesPerMonth:
            numerator = timesPerMonth; denominator = 30
        case .timesInPeriod:
            numerator = timesInN; denominator = timesInM
        case .specificDays:
            numerator = daysOfWeek.count; denominator = 7
        }
        dismiss()
    }

    private func radioRow(_ type: FrequencyType, _ label: String) -> some View {
        Button {
            frequencyType = type
        } label: {
            HStack {
                Image(systemName: frequencyType == type ? "record.circle.fill" : "circle")
                    .foregroundStyle(frequencyType == type ? Color.accentColor : .secondary)
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
