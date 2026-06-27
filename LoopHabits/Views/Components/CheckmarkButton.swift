import SwiftUI

// Mirrors Android Entry.nextToggleValue() exactly
func nextCheckmarkValue(_ current: Int) -> Int {
    switch current {
    case CheckmarkValue.no.rawValue:        return CheckmarkValue.yesManual.rawValue
    case CheckmarkValue.yesManual.rawValue: return CheckmarkValue.skip.rawValue
    case CheckmarkValue.skip.rawValue:      return CheckmarkValue.no.rawValue
    case CheckmarkValue.yesAuto.rawValue:   return CheckmarkValue.yesManual.rawValue
    default:                                return CheckmarkValue.yesManual.rawValue
    }
}

struct CheckmarkButton: View {
    /// Raw CheckmarkValue int (0=NO, 1=YES_AUTO, 2=YES_MANUAL, 3=SKIP)
    let value: Int
    let isScheduled: Bool
    let color: Color
    let isToday: Bool
    let onTap: () -> Void

    private var isDone: Bool  { value == CheckmarkValue.yesManual.rawValue || value == CheckmarkValue.yesAuto.rawValue }
    private var isSkip: Bool  { value == CheckmarkValue.skip.rawValue }

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
                } else if isSkip {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(color.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 34, height: 34)
                    // Horizontal dash for SKIP
                    Rectangle()
                        .fill(color.opacity(0.6))
                        .frame(width: 14, height: 2)
                } else if isScheduled {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(color.opacity(isToday ? 0.7 : 0.35), lineWidth: 1.5)
                        .frame(width: 34, height: 34)
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(color.opacity(0.35))
                } else {
                    Color.clear.frame(width: 34, height: 34)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: 40)
        .animation(.easeInOut(duration: 0.12), value: value)
    }
}
