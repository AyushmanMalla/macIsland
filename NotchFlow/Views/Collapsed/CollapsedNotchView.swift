import SwiftUI

struct CollapsedNotchView: View {
    @ObservedObject var pomodoroService: PomodoroTimerService
    var isPlaying: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Mini waveform bars on the left
            if isPlaying {
                MiniWaveformBars()
            }

            Spacer()

            // Pomodoro progress ring on the right
            if pomodoroService.currentState != .idle {
                PomodoroRingIndicator(
                    progress: pomodoroService.progress,
                    state: pomodoroService.currentState
                )
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear) // Transparent! hardware notch provides the black center
        .contentShape(Rectangle()) // Crucial: lets the clear background receive hover events
    }
}
