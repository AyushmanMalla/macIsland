import SwiftUI

struct ExpandedIslandView: View {
    @ObservedObject var nowPlayingService: NowPlayingService
    @ObservedObject var taskStore: TaskStore
    @Binding var selectedTab: ExpandedTab

    private enum Metrics {
        static let stackSpacing: CGFloat = 10
        static let tasksContentHeightInset: CGFloat = 42
        static let defaultHorizontalPadding: CGFloat = 15
        static let defaultTopPadding: CGFloat = 10
        static let defaultBottomPadding: CGFloat = 14
        static let musicHorizontalPadding: CGFloat = 12
        static let musicTopPadding: CGFloat = 8
        static let musicBottomPadding: CGFloat = 11
        static let segmentedWidth: CGFloat = 144
    }

    private var tasksHeight: CGFloat {
        ExpandedIslandLayout.tasksHeight(forVisibleTaskCount: taskStore.tasks.count)
    }

    private var horizontalPadding: CGFloat {
        selectedTab == .music ? Metrics.musicHorizontalPadding : Metrics.defaultHorizontalPadding
    }

    private var topPadding: CGFloat {
        selectedTab == .music ? Metrics.musicTopPadding : Metrics.defaultTopPadding
    }

    private var bottomPadding: CGFloat {
        selectedTab == .music ? Metrics.musicBottomPadding : Metrics.defaultBottomPadding
    }

    var body: some View {
        VStack(spacing: Metrics.stackSpacing) {
            Picker("", selection: $selectedTab) {
                Text("Music").tag(ExpandedTab.music)
                Text("Tasks").tag(ExpandedTab.tasks)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.small)
            .frame(width: Metrics.segmentedWidth)

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
            .frame(height: selectedTab == .tasks ? tasksHeight - Metrics.tasksContentHeightInset : nil, alignment: .top)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .fixedSize(horizontal: selectedTab == .music, vertical: selectedTab == .music)
        .frame(
            width: selectedTab == .tasks ? ExpandedIslandLayout.width : nil,
            height: selectedTab == .tasks ? tasksHeight : nil,
            alignment: .top
        )
        .animation(.snappy(duration: 0.30, extraBounce: 0.04), value: selectedTab)
        .animation(.snappy(duration: 0.30, extraBounce: 0.02), value: taskStore.tasks.count)
    }
}
