import SwiftUI

struct CheckmarkButton: View {
    let isScheduled: Bool
    let isDone: Bool
    let color: Color
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isDone {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: 34, height: 34)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                } else if isScheduled {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(color.opacity(isToday ? 0.7 : 0.35), lineWidth: 1.5)
                        .frame(width: 34, height: 34)
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(color.opacity(0.4))
                } else {
                    // Not scheduled — empty
                    Color.clear
                        .frame(width: 34, height: 34)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: 40)
    }
}
