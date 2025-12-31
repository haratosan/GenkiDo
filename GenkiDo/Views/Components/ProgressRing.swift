import SwiftUI

struct ProgressRing: View {
    let progress: Double
    var color: Color = .blue
    var lineWidth: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.2))

                Capsule()
                    .fill(color)
                    .frame(width: max(geometry.size.height, geometry.size.width * progress))
            }
        }
    }
}

struct CircularProgressRing: View {
    let progress: Double
    var color: Color = .blue
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressRing(progress: 0.7, color: .blue)
            .frame(height: 10)
            .padding()

        CircularProgressRing(progress: 0.7, color: .green)
            .frame(width: 100, height: 100)
    }
}
