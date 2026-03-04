import Foundation
import AppKit
import Combine

/// Bridges MediaRemote.framework for System Now Playing info, with robust Spotify fallback
class NowPlayingService: ObservableObject {
    @Published var trackInfo: TrackInfo = .empty
    @Published var playbackState: PlaybackState = .stopped
    @Published var isPlaying: Bool = false

    private var pollingTimer: AnyCancellable?
    private var mediaRemoteBundle: CFBundle?

    // MediaRemote function types
    private typealias MRMediaRemoteGetNowPlayingInfoFunction =
        @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction =
        @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    private typealias MRMediaRemoteSendCommandFunction =
        @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool
    private typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction =
        @convention(c) (DispatchQueue) -> Void

    private var MRMediaRemoteGetNowPlayingInfo: MRMediaRemoteGetNowPlayingInfoFunction?
    private var MRMediaRemoteGetNowPlayingApplicationIsPlaying: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction?
    private var MRMediaRemoteSendCommand: MRMediaRemoteSendCommandFunction?
    private var MRMediaRemoteRegisterForNowPlayingNotifications: MRMediaRemoteRegisterForNowPlayingNotificationsFunction?

    // MediaRemote command constants
    private enum MediaRemoteCommand: UInt32 {
        case play = 0
        case pause = 1
        case togglePlayPause = 2
        case stop = 3
        case nextTrack = 4
        case previousTrack = 5
    }

    init() {
        loadMediaRemoteFramework()
    }

    deinit {
        stopObserving()
    }

    // MARK: - Framework Loading

    private func loadMediaRemoteFramework() {
        let bundlePath = "/System/Library/PrivateFrameworks/MediaRemote.framework"
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, URL(fileURLWithPath: bundlePath) as CFURL) else {
            print("macIsland: Failed to load MediaRemote.framework")
            return
        }
        self.mediaRemoteBundle = bundle

        MRMediaRemoteGetNowPlayingInfo = loadFunction(bundle: bundle, name: "MRMediaRemoteGetNowPlayingInfo")
        MRMediaRemoteGetNowPlayingApplicationIsPlaying = loadFunction(bundle: bundle, name: "MRMediaRemoteGetNowPlayingApplicationIsPlaying")
        MRMediaRemoteSendCommand = loadFunction(bundle: bundle, name: "MRMediaRemoteSendCommand")
        MRMediaRemoteRegisterForNowPlayingNotifications = loadFunction(bundle: bundle, name: "MRMediaRemoteRegisterForNowPlayingNotifications")
    }

    private func loadFunction<T>(bundle: CFBundle, name: String) -> T? {
        guard let ptr = CFBundleGetFunctionPointerForName(bundle, name as CFString) else {
            return nil
        }
        return unsafeBitCast(ptr, to: T.self)
    }

    // MARK: - Observation

    func startObserving() {
        MRMediaRemoteRegisterForNowPlayingNotifications?(DispatchQueue.main)

        let notificationNames = [
            "kMRMediaRemoteNowPlayingInfoDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationDidChangeNotification"
        ]
        for name in notificationNames {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(nowPlayingInfoChanged),
                name: NSNotification.Name(name),
                object: nil
            )
        }

        // Fast polling for Spotify fallback and waveform sync
        pollingTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchSpotifyInfoIfActive()
            }

        fetchSpotifyInfoIfActive()
    }

    func stopObserving() {
        pollingTimer?.cancel()
        pollingTimer = nil
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func nowPlayingInfoChanged() {
        fetchSpotifyInfoIfActive()
    }

    // MARK: - Info Fetching

    /// Tries Spotify first (since user prefers it), falls back to MediaRemote
    private func fetchSpotifyInfoIfActive() {
        let scriptSource = """
        if application "Spotify" is running then
            tell application "Spotify"
                try
                    set tState to player state as string
                    set tName to name of current track
                    set tArtist to artist of current track
                    set tAlbum to album of current track
                    set tDur to duration of current track
                    set tPos to player position
                    set tArtURL to artwork url of current track
                    return tState & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (tDur/1000) & "|||" & tPos & "|||" & tArtURL
                on error
                    return "ERROR"
                end try
            end tell
        else
            return "NOT_RUNNING"
        end if
        """

        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            let result = script.executeAndReturnError(&error)
            if let stringValue = result.stringValue {
                if stringValue == "NOT_RUNNING" || stringValue == "ERROR" {
                    // Fall back to MediaRemote
                    fetchMediaRemoteInfo()
                    return
                }

                let parts = stringValue.components(separatedBy: "|||")
                if parts.count >= 7 {
                    let playState = parts[0]
                    let title = parts[1]
                    let artist = parts[2]
                    let album = parts[3]
                    let duration = Double(parts[4]) ?? 0.0
                    let elapsed = Double(parts[5]) ?? 0.0
                    let artUrlStr = parts[6]

                    let isPlayingNow = (playState == "playing")

                    // Download artwork async if it changed
                    if self.trackInfo.title != title || self.trackInfo.albumArt == nil {
                        if let url = URL(string: artUrlStr) {
                            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                                DispatchQueue.main.async {
                                    var img: NSImage? = nil
                                    if let data = data { img = NSImage(data: data) }
                                    self?.updateState(
                                        title: title, artist: artist, album: album,
                                        duration: duration, elapsed: elapsed, playing: isPlayingNow, img: img
                                    )
                                }
                            }.resume()
                        } else {
                            self.updateState(title: title, artist: artist, album: album, duration: duration, elapsed: elapsed, playing: isPlayingNow, img: nil)
                        }
                    } else {
                        // Keep existing artwork
                        self.updateState(title: title, artist: artist, album: album, duration: duration, elapsed: elapsed, playing: isPlayingNow, img: self.trackInfo.albumArt)
                    }
                    return
                }
            }
        }
        
        fetchMediaRemoteInfo()
    }

    private func updateState(title: String, artist: String, album: String, duration: Double, elapsed: Double, playing: Bool, img: NSImage?) {
        self.isPlaying = playing
        self.playbackState = playing ? .playing : .paused
        self.trackInfo = TrackInfo(
            title: title,
            artist: artist,
            album: album,
            albumArt: img,
            duration: duration,
            elapsedTime: elapsed
        )
    }

    private func fetchMediaRemoteInfo() {
        MRMediaRemoteGetNowPlayingInfo?(DispatchQueue.main) { [weak self] info in
            guard !info.isEmpty else {
                DispatchQueue.main.async {
                    self?.trackInfo = .empty
                    self?.isPlaying = false
                    self?.playbackState = .stopped
                }
                return
            }

            let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
            let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
            let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
            let duration = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0
            let elapsed = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0

            var albumArt: NSImage? = nil
            if let artData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data,
               !artData.isEmpty {
                albumArt = NSImage(data: artData)
            }

            self?.MRMediaRemoteGetNowPlayingApplicationIsPlaying?(DispatchQueue.main) { playing in
                DispatchQueue.main.async {
                    self?.updateState(title: title, artist: artist, album: album, duration: duration, elapsed: elapsed, playing: playing, img: albumArt)
                }
            }
        }
    }

    // MARK: - Playback Controls

    func togglePlayPause() {
        if isSpotifyRunning() {
            runAppleScript("tell application \"Spotify\" to playpause")
        } else {
            _ = MRMediaRemoteSendCommand?(MediaRemoteCommand.togglePlayPause.rawValue, nil)
        }
        refreshAfterCommand()
    }

    func nextTrack() {
        if isSpotifyRunning() {
            runAppleScript("tell application \"Spotify\" to next track")
        } else {
            _ = MRMediaRemoteSendCommand?(MediaRemoteCommand.nextTrack.rawValue, nil)
        }
        refreshAfterCommand()
    }

    func previousTrack() {
        if isSpotifyRunning() {
            runAppleScript("tell application \"Spotify\" to previous track")
        } else {
            _ = MRMediaRemoteSendCommand?(MediaRemoteCommand.previousTrack.rawValue, nil)
        }
        refreshAfterCommand()
    }

    private func isSpotifyRunning() -> Bool {
        let apps = NSWorkspace.shared.runningApplications
        return apps.contains { $0.bundleIdentifier == "com.spotify.client" }
    }

    private func runAppleScript(_ source: String) {
        if let script = NSAppleScript(source: source) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
        }
    }

    private func refreshAfterCommand() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.fetchSpotifyInfoIfActive()
        }
    }
}
