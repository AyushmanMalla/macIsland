import AppKit
import Combine
import SwiftUI

final class DynamicNotch<Content>: ObservableObject where Content: View {
    var windowController: NSWindowController?

    @Published var nowPlayingService: NowPlayingService
    @Published var pomodoroService: PomodoroTimerService
    @Published var content: () -> Content
    @Published var contentID: UUID
    @Published var isVisible = false
    @Published var isNotificationVisible = false
    @Published var notchWidth: CGFloat = 0
    @Published var notchHeight: CGFloat = 0
    @Published var isMouseInside = false

    var workItem: DispatchWorkItem?
    private var subscription: AnyCancellable?
    private let notchStyle: Style

    enum Style {
        case notch
        case auto
    }

    var animation: Animation {
        if #available(macOS 14.0, *), notchStyle == .notch {
            return .spring(.bouncy(duration: 0.4))
        }

        return .timingCurve(0.16, 1, 0.3, 1, duration: 0.7)
    }

    init(
        contentID: UUID = .init(),
        style: Style = .auto,
        nowPlayingService: NowPlayingService,
        pomodoroService: PomodoroTimerService,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.contentID = contentID
        self.content = content
        self.notchStyle = style
        self.nowPlayingService = nowPlayingService
        self.pomodoroService = pomodoroService
        self.subscription = NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                guard let self, let screen = NSScreen.screens.first else { return }
                self.initializeWindow(screen: screen)
            }
    }

    deinit {
        workItem?.cancel()
        deinitializeWindow()
    }
}

extension DynamicNotch {
    func setContent(contentID: UUID = .init(), content: @escaping () -> Content) {
        self.content = content
        self.contentID = contentID
    }

    func refreshContent(contentID: UUID = .init()) {
        self.contentID = contentID
    }

    func show(on screen: NSScreen? = NSScreen.screens.first, for time: Double = 0) {
        guard let screen else { return }

        func scheduleHide(_ delay: Double) {
            let workItem = DispatchWorkItem { [weak self] in
                self?.hide()
            }
            self.workItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }

        workItem?.cancel()

        guard !isVisible else {
            if time > 0 {
                scheduleHide(time)
            }
            return
        }

        if windowController == nil {
            initializeWindow(screen: screen)
        } else {
            refreshNotchSize(screen)
        }

        DispatchQueue.main.async {
            withAnimation(self.animation) {
                self.isVisible = true
                self.isNotificationVisible = true
            }
        }

        if time > 0 {
            scheduleHide(time)
        }
    }

    func hide() {
        guard isVisible || isNotificationVisible else { return }

        guard !isMouseInside else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.hide()
            }
            return
        }

        withAnimation(animation) {
            isVisible = false
            isNotificationVisible = false
        }
    }

    func refreshNotchSize(_ screen: NSScreen) {
        if let notchSize = screen.notchSize {
            notchWidth = notchSize.width
            notchHeight = notchSize.height
        } else {
            notchWidth = 300
            notchHeight = screen.frame.maxY - screen.visibleFrame.maxY
        }
    }

    func initializeWindow(screen: NSScreen) {
        deinitializeWindow()
        refreshNotchSize(screen)

        let rootView = NotchView(dynamicNotch: self).foregroundStyle(.white)
        let hostingView = NSHostingView(rootView: rootView)

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.fullSizeContentView, .borderless, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isMovable = false
        panel.isOpaque = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = .clear
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        panel.setFrame(screen.frame, display: false)
        panel.hasShadow = false
        panel.isReleasedWhenClosed = false
        panel.level = .mainMenu + 3
        panel.collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle,
        ]

        windowController = .init(window: panel)
    }

    func deinitializeWindow() {
        guard let windowController else { return }
        windowController.close()
        self.windowController = nil
    }
}
