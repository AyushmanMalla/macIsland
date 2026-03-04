import Foundation
import AppKit

/// Represents the current state of the Pomodoro timer
indirect enum PomodoroState: Equatable {
    case idle
    case working
    case shortBreak
    case longBreak
    case paused(previousState: PomodoroState)

    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .working: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        case .paused: return "Paused"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .idle: return 0
        case .working: return 25 * 60 // 25 minutes
        case .shortBreak: return 5 * 60 // 5 minutes
        case .longBreak: return 15 * 60 // 15 minutes
        case .paused(let prev): return prev.duration
        }
    }

    var accentColorName: String {
        switch self {
        case .idle: return "idle"
        case .working: return "work"
        case .shortBreak, .longBreak: return "break"
        case .paused: return "paused"
        }
    }
}

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

    static func == (lhs: TrackInfo, rhs: TrackInfo) -> Bool {
        return lhs.title == rhs.title
            && lhs.artist == rhs.artist
            && lhs.album == rhs.album
            && lhs.duration == rhs.duration
            && lhs.elapsedTime == rhs.elapsedTime
    }
}
