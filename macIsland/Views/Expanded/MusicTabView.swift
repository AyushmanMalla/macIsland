import AppKit
import SwiftUI

struct MusicTabView: View {
    @ObservedObject var nowPlayingService: NowPlayingService

    private var title: String {
        nowPlayingService.trackInfo.hasContent ? nowPlayingService.trackInfo.title : "No Music"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: nowPlayingService.openCurrentPlayerApp) {
                PlayerArtworkView(image: nowPlayingService.trackInfo.albumArt)
            }
            .buttonStyle(.plain)

            VStack(alignment: .center, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)

                if !nowPlayingService.trackInfo.artist.isEmpty {
                    Text(nowPlayingService.trackInfo.artist)
                        .foregroundStyle(.secondary)
                        .font(.headline)
                        .lineLimit(1)
                }

                PlaybackButtons(nowPlayingService: nowPlayingService)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: ExpandedIslandLayout.width - 30)
    }
}

private struct PlaybackButtons: View {
    @ObservedObject var nowPlayingService: NowPlayingService

    var body: some View {
        HStack(spacing: 20) {
            Button(action: nowPlayingService.previousTrack) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 24, weight: .bold))
            }
            .buttonStyle(.plain)

            Button(action: nowPlayingService.togglePlayPause) {
                Image(systemName: nowPlayingService.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 34, weight: .bold))
            }
            .buttonStyle(.plain)

            Button(action: nowPlayingService.nextTrack) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 24, weight: .bold))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct PlayerArtworkView: View {
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
                            Color(red: 0.6353, green: 0.6078, blue: 0.9961).opacity(0.28),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "music.note")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
