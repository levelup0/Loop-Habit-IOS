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

    private var isDone: Bool   { value == CheckmarkValue.yesManual.rawValue }
    private var isAuto: Bool   { value == CheckmarkValue.yesAuto.rawValue }
    private var isSkip: Bool   { value == CheckmarkValue.skip.rawValue }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isDone {
                    // YES_MANUAL: solid filled checkmark, habit color
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(color)
                } else if isAuto {
                    // YES_AUTO: outlined/hollow checkmark — achieved via stacked icons
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(color.opacity(0.45))
                } else if isSkip {
                    // SKIP: thick horizontal dash, habit color
                    Image(systemName: "minus")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(color)
                } else if isScheduled {
                    // NO but scheduled: faint X
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isToday ? color.opacity(0.55) : color.opacity(0.25))
                }
                // Unscheduled: empty
            }
            .frame(width: columnWidth, height: rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.1), value: value)
    }
}
