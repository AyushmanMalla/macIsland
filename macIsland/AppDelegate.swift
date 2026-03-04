import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var notchPanel: NotchPanel?
    private var positionManager = NotchPositionManager()
    private var pomodoroService = PomodoroTimerService()
    private var nowPlayingService = NowPlayingService()
    private var notificationService = NotificationService()
    private var hoverMonitor = HoverMonitor()
    private var cancellables = Set<AnyCancellable>()

    @Published var isExpanded = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        notificationService.requestPermission()
        setupNotchPanel()
        setupPomodoroNotifications()
        nowPlayingService.startObserving()
        
        // Start pure polling for 100% reliable hover tracking independent of Window Server
        hoverMonitor.startMonitoring()
        hoverMonitor.$isHovering
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isHovering in
                if isHovering {
                    self?.expandPanel()
                } else {
                    self?.collapsePanel()
                }
            }
            .store(in: &cancellables)
    }

    private func setupNotchPanel() {
        guard let screen = NSScreen.main else { return }

        // Start with the collapsed frame to avoid blocking the screen
        let initialFrame = positionManager.calculateCollapsedFrame(for: screen)

        let contentView = NotchContentView(
            isExpanded: Binding(
                get: { self.isExpanded },
                set: { self.isExpanded = $0 }
            ),
            pomodoroService: pomodoroService,
            nowPlayingService: nowPlayingService
        )

        let panel = NotchPanel(
            contentRect: initialFrame,
            contentView: contentView
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
        guard !isExpanded, let panel = notchPanel, let screen = NSScreen.main else { return }
        
        // 1. Immediately resize window to expanded size so the animation isn't clipped
        let expandedFrame = positionManager.calculateExpandedFrame(for: screen)
        panel.setFrame(expandedFrame, display: true, animate: false)
        
        // 2. Trigger SwiftUI animation
        isExpanded = true
    }

    private func collapsePanel() {
        guard isExpanded, let panel = notchPanel, let screen = NSScreen.main else { return }
        
        // 1. Trigger SwiftUI animation first
        isExpanded = false
        
        // 2. Delay shrinking the window frame until the animation is likely finished
        // to avoid clipping the collapsing island.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self, !self.isExpanded, let screen = NSScreen.main else { return }
            let collapsedFrame = self.positionManager.calculateCollapsedFrame(for: screen)
            self.notchPanel?.setFrame(collapsedFrame, display: true, animate: false)
        }
    }

    private func repositionPanel() {
        guard let screen = NSScreen.main, let panel = notchPanel else { return }
        
        let frame = isExpanded 
            ? positionManager.calculateExpandedFrame(for: screen)
            : positionManager.calculateCollapsedFrame(for: screen)
            
        panel.setFrame(frame, display: true, animate: false)
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
