import SwiftUI

struct MediaPlayerView: View {
    @ObservedObject var nowPlayingService: NowPlayingService

    private var hasTrack: Bool {
        nowPlayingService.trackInfo.title != "Not Playing"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Album Art + Waveform overlay
            ZStack(alignment: .bottom) {
                albumArtView

                if nowPlayingService.isPlaying {
                    AudioWaveformView()
                        .frame(height: 18)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 3)
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 30)
                            .offset(y: 5),
                            alignment: .bottom
                        )
                }
            }
            .frame(width: 64, height: 64)

            // Track info + controls
            VStack(alignment: .leading, spacing: 4) {
                // Track title
                Text(hasTrack ? nowPlayingService.trackInfo.title : "No Music")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)

                // Artist
                if hasTrack {
                    Text(nowPlayingService.trackInfo.artist)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                // Playback controls
                playbackControls
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 64)
    }

    private var albumArtView: some View {
        Group {
            if let albumArt = nowPlayingService.trackInfo.albumArt {
                Image(nsImage: albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: "6C5CE7").opacity(0.5),
                            Color(hex: "A29BFE").opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var playbackControls: some View {
        HStack(spacing: 24) {
            Button(action: { nowPlayingService.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)

            Button(action: { nowPlayingService.togglePlayPause() }) {
                Image(systemName: nowPlayingService.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Button(action: { nowPlayingService.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
    }
}
