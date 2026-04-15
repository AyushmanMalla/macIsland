import Foundation
import AppKit

/// Represents media playback state
enum PlaybackState: Equatable {
    case playing
    case paused
    case stopped
}

/// Track information from Now Playing
struct TrackInfo: Equatable {
    let title: String
    let artist: String
    let album: String
    let albumArt: NSImage?
    let duration: TimeInterval
    let elapsedTime: TimeInterval

    static let empty = TrackInfo(
        title: "Not Playing",
        artist: "",
        album: "",
        albumArt: nil,
        duration: 0,
        elapsedTime: 0
    )

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(elapsedTime / duration, 1.0)
    }

    var hasContent: Bool {
        !stableIdentity.isEmpty
    }

    var stableIdentity: String {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty, normalizedTitle != Self.empty.title else {
            return ""
        }

        let normalizedArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAlbum = album.trimmingCharacters(in: .whitespacesAndNewlines)
        return [normalizedTitle, normalizedArtist, normalizedAlbum].joined(separator: "\u{1F}")
    }

    static func == (lhs: TrackInfo, rhs: TrackInfo) -> Bool {
        return lhs.title == rhs.title
            && lhs.artist == rhs.artist
            && lhs.album == rhs.album
            && lhs.duration == rhs.duration
            && lhs.elapsedTime == rhs.elapsedTime
    }
}
