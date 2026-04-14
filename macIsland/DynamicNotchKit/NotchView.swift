import SwiftUI

struct NotchView<Content>: View where Content: View {
    @ObservedObject var dynamicNotch: DynamicNotch<Content>

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    Spacer()
                        .frame(width: dynamicNotch.notchWidth, height: dynamicNotch.notchHeight)

                    if dynamicNotch.isNotificationVisible {
                        dynamicNotch.content()
                            .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 15) }
                            .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: 15) }
                            .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: 15) }
                            .blur(radius: dynamicNotch.isVisible ? 0 : 10)
                            .scaleEffect(dynamicNotch.isVisible ? 1 : 0.8)
                            .offset(y: dynamicNotch.isVisible ? 0 : 5)
                            .padding(.horizontal, 15)
                            .transition(.blur.animation(.smooth))
                    }

                    if dynamicNotch.isMouseInside {
                        NotchPlayerView(nowPlayingService: dynamicNotch.nowPlayingService)
                            .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 15) }
                            .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: 15) }
                            .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: 15) }
                            .blur(radius: dynamicNotch.isVisible ? 0 : 10)
                            .scaleEffect(dynamicNotch.isVisible ? 1 : 0.8)
                            .offset(y: dynamicNotch.isVisible ? 0 : 5)
                            .padding(.horizontal, 15)
                            .transition(.blur.animation(.smooth))
                    }
                }
                .fixedSize()
                .frame(minWidth: dynamicNotch.notchWidth)
                .onHover { hovering in
                    withAnimation(dynamicNotch.animation) {
                        dynamicNotch.isMouseInside = hovering
                        dynamicNotch.isVisible = hovering || dynamicNotch.isNotificationVisible
                    }
                }
                .onChange(of: dynamicNotch.isMouseInside) { _, hovering in
                    if hovering {
                        dynamicNotch.workItem?.cancel()
                        dynamicNotch.isNotificationVisible = false
                    }
                }
                .background {
                    Rectangle()
                        .foregroundStyle(.black)
                        .padding(-50)
                }
                .mask {
                    GeometryReader { _ in
                        HStack {
                            Spacer(minLength: 0)
                            NotchShape(cornerRadius: dynamicNotch.isVisible ? 20 : nil)
                                .frame(
                                    width: dynamicNotch.isVisible ? nil : dynamicNotch.notchWidth,
                                    height: dynamicNotch.isVisible ? nil : dynamicNotch.notchHeight
                                )
                            Spacer(minLength: 0)
                        }
                    }
                }
                .shadow(color: .black.opacity(0.6), radius: dynamicNotch.isVisible ? 10 : 0)
                .animation(dynamicNotch.animation, value: dynamicNotch.contentID)

                Spacer()
            }

            Spacer()
        }
    }
}

private struct NotchPlayerView: View {
    @ObservedObject var nowPlayingService: NowPlayingService

    private var title: String {
        nowPlayingService.trackInfo.hasContent ? nowPlayingService.trackInfo.title : "No Music"
    }

    private var artist: String {
        nowPlayingService.trackInfo.artist
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
                if !artist.isEmpty {
                    Text(artist)
                        .foregroundStyle(.secondary)
                        .font(.headline)
                        .lineLimit(1)
                }
                PlaybackButtons(nowPlayingService: nowPlayingService)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: 350)
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
                            Color(hex: "6C5CE7").opacity(0.55),
                            Color(hex: "A29BFE").opacity(0.28)
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
