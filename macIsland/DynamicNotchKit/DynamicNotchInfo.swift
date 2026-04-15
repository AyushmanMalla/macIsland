import AppKit
import SwiftUI

final class DynamicNotchInfo {
    private let internalDynamicNotch: DynamicNotch<InfoView>

    var isVisible: Bool {
        internalDynamicNotch.isVisible
    }

    var isMouseInside: Bool {
        internalDynamicNotch.isMouseInside
    }

    init(
        contentID: UUID = .init(),
        style: DynamicNotch<InfoView>.Style = .auto,
        nowPlayingService: NowPlayingService,
        taskStore: TaskStore
    ) {
        self.internalDynamicNotch = DynamicNotch(
            contentID: contentID,
            style: style,
            nowPlayingService: nowPlayingService,
            taskStore: taskStore
        ) {
            InfoView(nowPlayingService: nowPlayingService)
        }
    }

    func refreshContent() {
        internalDynamicNotch.refreshContent()
    }

    func show(on screen: NSScreen? = NSScreen.screens.first, for time: Double = 0) {
        internalDynamicNotch.show(on: screen, for: time)
    }

    func hide() {
        internalDynamicNotch.hide()
    }

    func initializeNotchWindow() {
        guard let screen = NSScreen.screens.first else { return }
        internalDynamicNotch.initializeWindow(screen: screen)
    }

    func deinitializeNotchWindow() {
        internalDynamicNotch.deinitializeWindow()
    }
}

extension DynamicNotchInfo {
    struct InfoView: View {
        @ObservedObject private var nowPlayingService: NowPlayingService

        init(nowPlayingService: NowPlayingService) {
            self.nowPlayingService = nowPlayingService
        }

        var body: some View {
            HStack(spacing: 10) {
                CompactArtworkView(image: nowPlayingService.trackInfo.albumArt)

                VStack(alignment: .leading, spacing: 1) {
                    Text(nowPlayingService.trackInfo.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(nowPlayingService.trackInfo.artist)
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 50)
            .frame(maxWidth: 250)
            .contentShape(Rectangle())
            .onTapGesture {
                nowPlayingService.openCurrentPlayerApp()
            }
        }
    }
}

private struct CompactArtworkView: View {
    let image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.4235, green: 0.3608, blue: 0.9059).opacity(0.55),
                            Color(red: 0.6353, green: 0.6078, blue: 0.9961).opacity(0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
