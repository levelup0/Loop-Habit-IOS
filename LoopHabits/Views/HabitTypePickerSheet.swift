import SwiftUI

struct HabitTypePickerSheet: View {
    @Binding var selectedType: HabitType?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("New Habit")
                .font(.headline)
                .padding(.top, 24)
                .padding(.bottom, 20)

            HStack(spacing: 16) {
                typeButton(.yesNo,
                           title: "Yes or No",
                           subtitle: "Did you exercise today?",
                           icon: "checkmark.circle.fill")
                typeButton(.measurable,
                           title: "Measurable",
                           subtitle: "How many miles did you run?",
                           icon: "number.circle.fill")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
    }

    private func typeButton(_ type: HabitType, title: String, subtitle: String, icon: String) -> some View {
        Button {
            selectedType = type
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
