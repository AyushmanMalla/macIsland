import SwiftUI

struct PomodoroTimerView: View {
    @ObservedObject var pomodoroService: PomodoroTimerService

    private var ringColor: LinearGradient {
        switch pomodoroService.currentState {
        case .working:
            return LinearGradient(
                colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .shortBreak, .longBreak:
            return LinearGradient(
                colors: [Color(hex: "00B894"), Color(hex: "55EFC4")],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .paused:
            return LinearGradient(
                colors: [Color.orange, Color.yellow],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .idle:
            return LinearGradient(
                colors: [Color.gray, Color.gray.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Circular progress ring with time
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)

                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(pomodoroService.progress))
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: pomodoroService.progress)

                // Time text
                Text(pomodoroService.timeString)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 56, height: 56)

            // State + session info + controls
            VStack(alignment: .leading, spacing: 6) {
                // State label
                Text(pomodoroService.currentState.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                // Session dots
                SessionIndicatorView(
                    completedSessions: pomodoroService.completedSessions,
                    totalSessions: 4
                )

                // Controls
                timerControls
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timerControls: some View {
        HStack(spacing: 16) {
            // Start / Pause button
            Button(action: { pomodoroService.toggleStartPause() }) {
                Image(systemName: controlIcon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)

            // Reset button
            if pomodoroService.currentState != .idle {
                Button(action: { pomodoroService.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var controlIcon: String {
        switch pomodoroService.currentState {
        case .idle:
            return "play.fill"
        case .working, .shortBreak, .longBreak:
            return "pause.fill"
        case .paused:
            return "play.fill"
        }
    }
}

// MARK: - Session Indicator Dots

struct SessionIndicatorView: View {
    let completedSessions: Int
    let totalSessions: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSessions, id: \.self) { index in
                Circle()
                    .fill(index < (completedSessions % totalSessions)
                          ? Color(hex: "6C5CE7")
                          : Color.white.opacity(0.2))
                    .frame(width: 5, height: 5)
            }
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
