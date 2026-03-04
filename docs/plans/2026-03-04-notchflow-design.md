# NotchFlow Clone — Design Document

## Overview

A macOS Tahoe app that anchors a floating widget to the MacBook notch, providing a **Pomodoro timer** and **Now Playing media controls** with audio waveform visualization. The app lives entirely in the notch area (no Dock icon) and expands on hover.

## Requirements Summary

| Feature | Spec |
|---------|------|
| **Interaction** | Hover to expand; collapses when mouse leaves |
| **App Presence** | Menu-bar only (`LSUIElement = true`), no Dock icon |
| **Pomodoro** | Classic: 25min work / 5min break / 15min long break (every 4 cycles) |
| **Notifications** | macOS native notifications on session end + optional sound |
| **Media Player** | System Now Playing (Spotify-focused), play/pause/skip/previous |
| **Waveform** | Animated audio bars alongside album art (iPhone-style) |
| **Visual Indicator** | Progress ring visible in collapsed notch state |

## Architecture

```
┌──────────────────────────────────────────────┐
│  SwiftUI App (@main)                         │
│  └─ @NSApplicationDelegateAdaptor            │
│     └─ AppDelegate                           │
│        ├─ NotchPanel (NSPanel subclass)       │
│        │  └─ NSHostingView<NotchContentView>  │
│        ├─ NotchPositionManager               │
│        └─ MouseTrackingManager               │
├──────────────────────────────────────────────┤
│  Views (SwiftUI)                             │
│  ├─ NotchContentView (root)                  │
│  │   ├─ CollapsedNotchView                   │
│  │   │   ├─ PomodoroRingIndicator            │
│  │   │   └─ MiniWaveformBars                 │
│  │   └─ ExpandedNotchView                    │
│  │       ├─ MediaPlayerView                  │
│  │       │   ├─ AlbumArtView                 │
│  │       │   ├─ AudioWaveformView            │
│  │       │   ├─ TrackInfoView                │
│  │       │   └─ PlaybackControlsView         │
│  │       └─ PomodoroTimerView                │
│  │           ├─ TimerDisplayView             │
│  │           ├─ SessionIndicatorView         │
│  │           └─ TimerControlsView            │
├──────────────────────────────────────────────┤
│  Services                                    │
│  ├─ NowPlayingService (MediaRemote bridge)   │
│  ├─ PomodoroTimerService                     │
│  └─ NotificationService                      │
└──────────────────────────────────────────────┘
```

### Key Technical Decisions

1. **NSPanel for window** — Borderless, transparent, `.floating` level, non-activating. This lets the widget sit above all windows without stealing focus.

2. **MediaRemote.framework** — Private framework for System Now Playing. Loads dynamically via `dlopen`. Provides track info, album art, playback state, and controls for any media source (Spotify, Apple Music, browser, etc.).

3. **Audio waveform** — Simulated animated bars driven by a timer. Since we can't access raw audio from System Now Playing, we animate bars with randomized heights synced to playback state (animated when playing, static when paused).

4. **Hover detection** — `NSTrackingArea` on the NSPanel to detect mouse enter/exit. Drives SwiftUI animation state for expand/collapse.

5. **Notch positioning** — Reads `NSScreen.main.auxiliaryTopLeftArea` and `auxiliaryTopRightArea` to compute exact notch bounds, then positions the NSPanel centered above.

## Visual Design

### Color Palette (Dark Mode native)
- **Background**: `#1A1A1A` with 80% opacity (vibrancy blur behind)
- **Surface**: `#2A2A2A`
- **Accent**: Adaptive — pulled from album art dominant color, falls back to `#6C5CE7`
- **Text Primary**: `#FFFFFF` at 90% opacity
- **Text Secondary**: `#FFFFFF` at 60% opacity
- **Progress Ring**: Gradient from `#6C5CE7` to `#A29BFE`

### Collapsed State (~notch size)
- Subtle progress ring around notch edge (Pomodoro)
- 3 tiny waveform bars if music playing

### Expanded State (~320×200pt)
- Smooth spring animation downward
- Left side: Album art (rounded corners) + waveform bars
- Right side: Track info + playback controls
- Bottom: Pomodoro timer with circular progress + controls
- Frosted glass background with vibrancy

### Animations
- Expand/collapse: `spring(response: 0.4, dampingFraction: 0.8)`
- Waveform bars: Continuous sine-wave-based height animation
- Progress ring: Smooth linear progression
- Album art: Subtle scale on track change

## Approach Comparison

| Aspect | Chosen: SwiftUI + NSPanel | Alt: Pure AppKit | Alt: Pure SwiftUI Window |
|--------|--------------------------|------------------|--------------------------|
| **UI Code** | Modern, declarative | Verbose, imperative | Cleanest |
| **Window Control** | Full (NSPanel) | Full | Limited (no floating panel) |
| **Animation** | SwiftUI native | Manual CAAnimation | SwiftUI native |
| **Complexity** | Medium | High | Low but limited |
| **Maintainability** | High | Medium | High but can't anchor to notch |

**Recommendation**: SwiftUI + NSPanel bridge. Best balance of modern UI code with full window control needed for notch anchoring.
