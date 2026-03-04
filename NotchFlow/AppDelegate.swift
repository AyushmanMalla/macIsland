import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var notchPanel: NotchPanel?
    private var positionManager = NotchPositionManager()
    private var pomodoroService = PomodoroTimerService()
    private var nowPlayingService = NowPlayingService()
    private var notificationService = NotificationService()
    private var cancellables = Set<AnyCancellable>()

    @Published var isExpanded = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        notificationService.requestPermission()
        setupNotchPanel()
        setupPomodoroNotifications()
        nowPlayingService.startObserving()
    }

    private func setupNotchPanel() {
        guard let screen = NSScreen.main else { return }

        let collapsedFrame = positionManager.calculateCollapsedFrame(for: screen)

        let contentView = NotchContentView(
            isExpanded: Binding(
                get: { self.isExpanded },
                set: { self.isExpanded = $0 }
            ),
            pomodoroService: pomodoroService,
            nowPlayingService: nowPlayingService
        )

        let panel = NotchPanel(
            contentRect: collapsedFrame,
            contentView: contentView,
            onMouseEntered: { [weak self] in
                self?.expandPanel()
            },
            onMouseExited: { [weak self] in
                self?.collapsePanel()
            }
        )

        panel.orderFrontRegardless()
        self.notchPanel = panel

        // Listen for screen changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.repositionPanel()
            }
            .store(in: &cancellables)
    }

    private func expandPanel() {
        guard !isExpanded, let screen = NSScreen.main, let panel = notchPanel else { return }
        isExpanded = true
        let expandedFrame = positionManager.calculateExpandedFrame(for: screen)
        panel.animateToFrame(expandedFrame, duration: 0.45)
    }

    private func collapsePanel() {
        guard isExpanded, let screen = NSScreen.main, let panel = notchPanel else { return }

        // Debounce: verify the mouse is ACTUALLY outside the panel's current frame
        let mouseLoc = NSEvent.mouseLocation
        if panel.frame.contains(mouseLoc) {
            return
        }

        isExpanded = false
        let collapsedFrame = positionManager.calculateCollapsedFrame(for: screen)
        panel.animateToFrame(collapsedFrame, duration: 0.35)
    }

    private func repositionPanel() {
        guard let screen = NSScreen.main, let panel = notchPanel else { return }
        let frame = isExpanded
            ? positionManager.calculateExpandedFrame(for: screen)
            : positionManager.calculateCollapsedFrame(for: screen)
        panel.setFrame(frame, display: true)
        panel.setupTrackingArea()
    }

    private func setupPomodoroNotifications() {
        pomodoroService.$currentState
            .removeDuplicates()
            .sink { [weak self] state in
                self?.notificationService.sendPomodoroNotification(for: state)
            }
            .store(in: &cancellables)
    }
}
