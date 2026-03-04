import SwiftUI

struct NotchContentView: View {
    @Binding var isExpanded: Bool
    @ObservedObject var pomodoroService: PomodoroTimerService
    @ObservedObject var nowPlayingService: NowPlayingService

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background morphs gracefully with GeometryReader bounds, drawn by ExpandedNotchView
                
                // 1. Expanded view (fades and scales slightly)
                ExpandedNotchView(
                    pomodoroService: pomodoroService,
                    nowPlayingService: nowPlayingService
                )
                .opacity(isExpanded ? 1 : 0)
                .scaleEffect(isExpanded ? 1.0 : 0.95, anchor: .top)
                
                // 2. Collapsed view (must be over everything else so hovering hits its contentShape)
                CollapsedNotchView(
                    pomodoroService: pomodoroService,
                    isPlaying: nowPlayingService.isPlaying
                )
                .opacity(isExpanded ? 0 : 1)
                // When expanded, the collapsed content shape ignores touches so the expanded controls can be clicked
                .allowsHitTesting(!isExpanded)
            }
            // Animate only the SwiftUI internal layout properties in sync with AppKit
            .animation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0), value: isExpanded)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
    }
}
