import SwiftUI

struct ScoreRingShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let startAngle = Angle(degrees: -90)
        let endAngle = Angle(degrees: -90 + 360 * progress)
        path.addArc(center: center, radius: radius,
                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}

struct ScoreRingView: View {
    let score: Double
    let color: Color
    var size: CGFloat = 36
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.25), lineWidth: lineWidth)
            ScoreRingShape(progress: max(0.001, score))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.4), value: score)
    }
}

#Preview {
    HStack(spacing: 20) {
        ScoreRingView(score: 0.0, color: .green)
        ScoreRingView(score: 0.45, color: .blue)
        ScoreRingView(score: 0.9, color: .red)
        ScoreRingView(score: 1.0, color: .purple, size: 60, lineWidth: 6)
    }
    .padding()
    .background(Color(hex: "#212121")!)
}
