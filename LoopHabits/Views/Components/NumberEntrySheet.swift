import SwiftUI

struct NumberEntrySheet: View {
    let habitName: String
    let unit: String
    let targetValue: Double
    let currentValue: Double?
    let onSave: (Double) -> Void   // called with the entered value before dismiss

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
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
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .multilineTextAlignment(.center)
                    .focused($focused)
                    .onAppear {
                        if let v = currentValue, v > 0 {
                            text = formatValue(v)
                        }
                        // Delay so sheet animation finishes first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            focused = true
                        }
                    }

                Spacer()
            }
            .padding(.horizontal, 32)
            .navigationTitle("Enter Value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { commit() }
                        .fontWeight(.semibold)
                        .disabled(parsedValue == nil)
                }
            }
        }
        .presentationDetents([.medium])
        // Also allow confirm by pressing Return (numeric pad has no Return, but just in case)
        .onSubmit { commit() }
    }

    private var parsedValue: Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    private func commit() {
        guard let v = parsedValue else { return }
        onSave(v)
        dismiss()
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
