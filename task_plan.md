# NotchFlow Clone — Task Plan

## Phase 1: Project Scaffolding
- [ ] Create Xcode project structure (SwiftUI App, macOS target)
- [ ] Configure `Info.plist` — `LSUIElement = true`, bundle ID, app name
- [ ] Set up file/folder structure for Views, Services, Models
- [ ] Add entitlements (User Notifications)

## Phase 2: Core Window System
- [ ] Create `NotchPanel` (NSPanel subclass) — borderless, transparent, floating
- [ ] Create `NotchPositionManager` — detect notch bounds, position panel
- [ ] Create `MouseTrackingManager` — NSTrackingArea for hover detection
- [ ] Wire up `AppDelegate` with `@NSApplicationDelegateAdaptor`
- [ ] Verify panel appears and anchors to notch correctly

## Phase 3: Pomodoro Timer Service (TDD)
- [ ] Write tests for `PomodoroTimerService` — state machine, timing, session counting
- [ ] Implement `PomodoroTimerService` — 25/5/15 classic cycle
- [ ] Write tests for `NotificationService` — notification content, scheduling
- [ ] Implement `NotificationService` — macOS native notifications on session end

## Phase 4: Now Playing Service (TDD)
- [ ] Write tests for `NowPlayingService` — track info parsing, state management
- [ ] Implement `NowPlayingService` — MediaRemote framework bridge
- [ ] Test with Spotify playback

## Phase 5: UI — Collapsed State
- [ ] Build `CollapsedNotchView` — notch-shaped container
- [ ] Build `PomodoroRingIndicator` — circular progress ring
- [ ] Build `MiniWaveformBars` — tiny waveform indicator
- [ ] Animate collapse/expand transition

## Phase 6: UI — Expanded State
- [ ] Build `ExpandedNotchView` — frosted glass container
- [ ] Build `MediaPlayerView` — album art, track info, controls
- [ ] Build `AudioWaveformView` — animated sine-wave bars
- [ ] Build `PomodoroTimerView` — timer display, progress, controls
- [ ] Build `SessionIndicatorView` — dot indicators for Pomodoro cycles
- [ ] Wire views to services

## Phase 7: Polish & Integration
- [ ] Adaptive accent color from album art
- [ ] Spring animations for expand/collapse
- [ ] Sound alerts for Pomodoro transitions
- [ ] Visual testing with user feedback
- [ ] Edge cases: no music playing, multiple screens, notch-less Macs

## Phase 8: Final Verification
- [ ] All unit tests pass
- [ ] Build succeeds with no warnings
- [ ] Visual review with user
- [ ] Test Spotify integration end-to-end
