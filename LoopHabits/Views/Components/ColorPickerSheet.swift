import SwiftUI

struct ColorPickerSheet: View {
    @Binding var colorHex: String
    @Environment(\.dismiss) private var dismiss

    private let palette = Color.loopPalette
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)

    var body: some View {
        NavigationStack {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(palette, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex) ?? .blue)
                        .frame(height: 40)
                        .overlay {
                            if colorHex == hex {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .onTapGesture {
                            colorHex = hex
                            dismiss()
                        }
                }
            }
            .padding(20)
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
