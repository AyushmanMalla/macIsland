import AppKit
import SwiftUI

struct MusicTabView: View {
    @ObservedObject var nowPlayingService: NowPlayingService

    private enum Metrics {
        static let scale: CGFloat = 0.85
        static let artworkTextSpacing: CGFloat = 10 * scale
        static let textStackSpacing: CGFloat = 6 * scale
        static let titleFontSize: CGFloat = 17 * scale
        static let artistFontSize: CGFloat = 17 * scale
    }

    private var title: String {
        nowPlayingService.trackInfo.hasContent ? nowPlayingService.trackInfo.title : "No Music"
    }

    var body: some View {
        HStack(alignment: .center, spacing: Metrics.artworkTextSpacing) {
            Button(action: nowPlayingService.openCurrentPlayerApp) {
                PlayerArtworkView(image: nowPlayingService.trackInfo.albumArt)
            }
            .buttonStyle(.plain)

            VStack(alignment: .center, spacing: Metrics.textStackSpacing) {
                Text(title)
                    .font(.system(size: Metrics.titleFontSize, weight: .semibold))
                    .lineLimit(1)
                    .multilineTextAlignment(.center)

                if !nowPlayingService.trackInfo.artist.isEmpty {
                    Text(nowPlayingService.trackInfo.artist)
                        .foregroundStyle(.secondary)
                        .font(.system(size: Metrics.artistFontSize, weight: .semibold))
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                }

                PlaybackButtons(nowPlayingService: nowPlayingService)
            }
        }
        .fixedSize(horizontal: true, vertical: true)
    }
}

private struct PlaybackButtons: View {
    @ObservedObject var nowPlayingService: NowPlayingService

    private enum Metrics {
        static let scale: CGFloat = 0.85
        static let controlsSpacing: CGFloat = 20 * scale
        static let secondaryControlSize: CGFloat = 24 * scale
        static let primaryControlSize: CGFloat = 34 * scale
    }

    var body: some View {
        HStack(spacing: Metrics.controlsSpacing) {
            Button(action: nowPlayingService.previousTrack) {
                Image(systemName: "backward.fill")
                    .font(.system(size: Metrics.secondaryControlSize, weight: .bold))
            }
            .buttonStyle(.plain)

            Button(action: nowPlayingService.togglePlayPause) {
                Image(systemName: nowPlayingService.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: Metrics.primaryControlSize, weight: .bold))
            }
            .buttonStyle(.plain)

            Button(action: nowPlayingService.nextTrack) {
                Image(systemName: "forward.fill")
                    .font(.system(size: Metrics.secondaryControlSize, weight: .bold))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct PlayerArtworkView: View {
    let image: NSImage?

    private enum Metrics {
        static let scale: CGFloat = 0.85
        static let artworkSize: CGFloat = 80 * scale
        static let cornerRadius: CGFloat = 18 * scale
        static let placeholderIconSize: CGFloat = 24 * scale
    }

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
                        .font(.system(size: Metrics.placeholderIconSize, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(width: Metrics.artworkSize, height: Metrics.artworkSize)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
    }
}
