import SwiftUI

struct NotchContentView: View {
    @Binding var isExpanded: Bool
    @ObservedObject var pomodoroService: PomodoroTimerService
    @ObservedObject var nowPlayingService: NowPlayingService

    var body: some View {
        ZStack(alignment: .top) {
            
            // 1. Expanded view
            ExpandedNotchView(
                pomodoroService: pomodoroService,
                nowPlayingService: nowPlayingService
            )
            // CRITICAL: Fixed size prevents SwiftUI from constantly relayouting text while animating!
            .frame(width: NotchPositionManager.expandedWidth, height: NotchPositionManager.expandedHeight)
            .opacity(isExpanded ? 1 : 0)
            .scaleEffect(isExpanded ? 1.0 : 0.95, anchor: .top)
            
            // 2. Collapsed view
            CollapsedNotchView(
                pomodoroService: pomodoroService,
                isPlaying: nowPlayingService.isPlaying
            )
            .frame(width: NotchPositionManager.collapsedWidth, height: NotchPositionManager.collapsedHeight)
            .opacity(isExpanded ? 0 : 1)
            .allowsHitTesting(!isExpanded)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0), value: isExpanded)
        .frame(
            width: isExpanded ? NotchPositionManager.expandedWidth : NotchPositionManager.collapsedWidth,
            height: isExpanded ? NotchPositionManager.expandedHeight : NotchPositionManager.collapsedHeight,
            alignment: .top
        )
        // CRITICAL: Pin the morphing UI to the absolute top of the invisible 480x124 macOS window canvas!
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
