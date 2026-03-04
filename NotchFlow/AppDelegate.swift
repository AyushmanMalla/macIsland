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

        // ALWAYS map the AppKit window to the fully expanded frame. 
        // We use a zero-lag transparent canvas where only SwiftUI animates.
        let expandedFrame = positionManager.calculateExpandedFrame(for: screen)

        let contentView = NotchContentView(
            isExpanded: Binding(
                get: { self.isExpanded },
                set: { self.isExpanded = $0 }
            ),
            pomodoroService: pomodoroService,
            nowPlayingService: nowPlayingService
        )

        let panel = NotchPanel(
            contentRect: expandedFrame,
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
        guard !isExpanded, let _ = notchPanel else { return }
        isExpanded = true
    }

    private func collapsePanel() {
        guard isExpanded, let _ = notchPanel else { return }
        isExpanded = false
    }

    private func repositionPanel() {
        guard let screen = NSScreen.main, let panel = notchPanel else { return }
        
        let expandedFrame = positionManager.calculateExpandedFrame(for: screen)
        panel.setFrame(expandedFrame, display: true, animate: false)
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
