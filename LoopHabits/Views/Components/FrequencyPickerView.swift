import SwiftUI

struct FrequencyPickerView: View {
    @Binding var frequencyType: FrequencyType
    @Binding var numerator: Int
    @Binding var denominator: Int
    @Binding var daysOfWeek: Set<Int>
    @Environment(\.dismiss) private var dismiss

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    row(.everyDay,      "Every day")
                    row(.everyNDays,    "Every \(denominator) days")
                    row(.timesPerWeek,  "\(numerator) times per week")
                    row(.timesPerMonth, "\(numerator) times per month")
                    row(.timesInPeriod, "\(numerator) times in \(denominator) days")
                    row(.specificDays,  "Specific days of week")
                }

                // Contextual steppers
                if frequencyType == .everyNDays {
                    Section("Every N days") {
                        Stepper("Every \(denominator) days", value: $denominator, in: 2...365)
                    }
                }
                if frequencyType == .timesPerWeek {
                    Section("Times per week") {
                        Stepper("\(numerator) times per week", value: $numerator, in: 1...7)
                    }
                }
                if frequencyType == .timesPerMonth {
                    Section("Times per month") {
                        Stepper("\(numerator) times per month", value: $numerator, in: 1...31)
                    }
                }
                if frequencyType == .timesInPeriod {
                    Section("Custom") {
                        Stepper("\(numerator) times", value: $numerator, in: 1...365)
                        Stepper("in \(denominator) days", value: $denominator, in: 1...365)
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
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ type: FrequencyType, _ label: String) -> some View {
        Button {
            frequencyType = type
        } label: {
            HStack {
                Image(systemName: frequencyType == type ? "record.circle.fill" : "circle")
                    .foregroundStyle(frequencyType == type ? Color.accentColor : Color.secondary)
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
            }
        }
    }
}
