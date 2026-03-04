import SwiftUI

struct ExpandedNotchView: View {
    @ObservedObject var pomodoroService: PomodoroTimerService
    @ObservedObject var nowPlayingService: NowPlayingService

    var body: some View {
        HStack(spacing: 20) {
            // Media Player Section (Left Side)
            MediaPlayerView(nowPlayingService: nowPlayingService)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Subtle vertical divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, 4)

            // Pomodoro Timer Section (Right Side)
            // Push content toward trailing edge
            PomodoroTimerView(pomodoroService: pomodoroService)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.top, 40) // Space for the hardware notch
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            ZStack {
                // Pure black base
                Color.black

                // Subtle gradient overlay for depth
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(white: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 42,
                bottomTrailingRadius: 42,
                topTrailingRadius: 0
            )
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        .drawingGroup()
    }
}
