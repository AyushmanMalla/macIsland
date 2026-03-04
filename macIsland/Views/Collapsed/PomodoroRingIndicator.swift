import SwiftUI

struct PomodoroRingIndicator: View {
    var progress: Double
    var state: PomodoroState

    private var ringColor: Color {
        switch state {
        case .working:
            return .purple
        case .shortBreak, .longBreak:
            return .green
        case .paused:
            return .orange
        case .idle:
            return .gray
        }
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 2)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
        .drawingGroup()
        .frame(width: 18, height: 18)
    }
}
