import SwiftUI

struct NumberEntrySheet: View {
    let habitName: String
    let unit: String
    let targetValue: Double
    let currentValue: Double?

    @Binding var result: Double?
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text(habitName)
                        .font(.headline)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if targetValue > 0 {
                        Text("Target: \(formattedTarget)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)

                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .onAppear {
                        if let v = currentValue, v > 0 {
                            text = formatValue(v)
                        }
                    }

                Spacer()
            }
            .navigationTitle("Enter Value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        result = Double(text.replacingOccurrences(of: ",", with: "."))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var formattedTarget: String {
        targetValue.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(targetValue)) \(unit)"
            : "\(targetValue) \(unit)"
    }

    private func formatValue(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : "\(v)"
    }
}
