import SwiftUI

struct NumberButton: View {
    let value: Double?   // nil = not entered
    let unit: String
    let color: Color
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let v = value, v > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: 34, height: 34)
                    Text(formattedValue(v))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: 30)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(color.opacity(isToday ? 0.7 : 0.35), lineWidth: 1.5)
                        .frame(width: 34, height: 34)
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(color.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: 40)
        .animation(.easeInOut(duration: 0.12), value: value)
    }

    private func formattedValue(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
}
