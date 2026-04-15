import SwiftUI

struct ExpandedIslandView: View {
    @ObservedObject var nowPlayingService: NowPlayingService
    @ObservedObject var taskStore: TaskStore
    @Binding var selectedTab: ExpandedTab

    private var animatedHeight: CGFloat {
        switch selectedTab {
        case .music:
            ExpandedIslandLayout.musicHeight
        case .tasks:
            ExpandedIslandLayout.tasksHeight(forVisibleTaskCount: taskStore.tasks.count)
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)

                Picker("", selection: $selectedTab) {
                    Text("Music").tag(ExpandedTab.music)
                    Text("Tasks").tag(ExpandedTab.tasks)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .controlSize(.small)
                .frame(width: 144)
            }

            ZStack {
                if selectedTab == .music {
                    MusicTabView(nowPlayingService: nowPlayingService)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            )
                        )
                } else {
                    TasksView(taskStore: taskStore)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                        )
                }
            }
            .frame(height: animatedHeight - 42, alignment: .top)
        }
        .padding(.horizontal, 15)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .frame(width: ExpandedIslandLayout.width, height: animatedHeight, alignment: .top)
        .animation(.snappy(duration: 0.30, extraBounce: 0.04), value: selectedTab)
        .animation(.snappy(duration: 0.30, extraBounce: 0.02), value: taskStore.tasks.count)
    }
}
