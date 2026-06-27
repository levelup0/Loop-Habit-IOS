import SwiftUI

struct NumberButton: View {
    let value: Double?        // nil = not entered
    let targetValue: Double
    let targetType: TargetType
    let color: Color
    let isToday: Bool
    let onTap: () -> Void

    private var meetsTarget: Bool {
        guard let v = value, targetValue > 0 else { return value != nil && value! > 0 }
        switch targetType {
        case .atLeast: return v >= targetValue
        case .atMost:  return v <= targetValue
        }
    }

    private var displayColor: Color {
        guard let v = value, v > 0 else { return color.opacity(isToday ? 0.55 : 0.25) }
        return meetsTarget ? color : Color.secondary
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let v = value, v > 0 {
                    Text(formattedValue(v))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(displayColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    // No value yet — show plus sign like Android
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isToday ? color.opacity(0.55) : color.opacity(0.25))
                }
            }
            .frame(width: columnWidth, height: rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.1), value: value)
    }

    private func formattedValue(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.0fk", v / 1000) }
        if v.truncatingRemainder(dividingBy: 1) == 0 { return "\(Int(v))" }
        return String(format: "%.1f", v)
    }
}
