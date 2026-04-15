import AppKit
import Combine
import SwiftUI

final class DynamicNotch<Content>: ObservableObject where Content: View {
    var windowController: NSWindowController?

    @Published var nowPlayingService: NowPlayingService
    @Published var taskStore: TaskStore
    @Published var selectedTab: ExpandedTab = .music
    @Published var content: () -> Content
    @Published var contentID: UUID
    @Published var isVisible = false
    @Published var isNotificationVisible = false
    @Published var notchWidth: CGFloat = 0
    @Published var notchHeight: CGFloat = 0
    @Published var isMouseInside = false

    var workItem: DispatchWorkItem?
    private var subscription: AnyCancellable?
    private let hoverMonitor = HoverMonitor()
    private var hoverSubscription: AnyCancellable?
    private var interactivitySubscription: AnyCancellable?
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
        taskStore: TaskStore,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.contentID = contentID
        self.content = content
        self.notchStyle = style
        self.nowPlayingService = nowPlayingService
        self.taskStore = taskStore
        self.subscription = NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                guard let self, let screen = NSScreen.screens.first else { return }
                self.initializeWindow(screen: screen)
            }
        configureHoverPipeline()
        hoverMonitor.startMonitoring()
    }

    deinit {
        workItem?.cancel()
        hoverMonitor.stopMonitoring()
        deinitializeWindow()
    }
}

extension DynamicNotch {
    private func configureHoverPipeline() {
        syncCollapsedActivationGeometry()

        hoverSubscription = hoverMonitor.$isHovering
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hovering in
                guard hovering else { return }
                self?.setMouseInside(true)
            }

        interactivitySubscription = $isMouseInside
            .removeDuplicates()
            .sink { [weak self] hovering in
                self?.syncPanelInteractivity(isHovering: hovering)
            }
    }

    private func setMouseInside(_ hovering: Bool) {
        withAnimation(animation) {
            isMouseInside = hovering
            isVisible = hovering || isNotificationVisible
        }

        if hovering {
            workItem?.cancel()
            isNotificationVisible = false
        }
    }

    private func syncPanelInteractivity(isHovering: Bool) {
        guard let panel = windowController?.window else { return }

        panel.ignoresMouseEvents = !isHovering

        if isHovering {
            panel.orderFrontRegardless()
        } else if panel.isKeyWindow {
            panel.resignKey()
        }
    }

    private func syncCollapsedActivationGeometry() {
        let collapsedWidth = max(notchWidth, 1)
        let collapsedHeight = max(notchHeight, 1)
        hoverMonitor.updateCollapsedNotchSize(
            NSSize(width: collapsedWidth, height: collapsedHeight)
        )
    }

    func setViewHovering(_ hovering: Bool) {
        setMouseInside(hovering)
    }

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
        syncCollapsedActivationGeometry()
    }

    func initializeWindow(screen: NSScreen) {
        deinitializeWindow()
        refreshNotchSize(screen)

        let rootView = NotchView(dynamicNotch: self).foregroundStyle(.white)
        let panel = NotchPanel(
            contentRect: .zero,
            contentView: rootView
        )
        panel.setFrame(screen.frame, display: false)
        windowController = .init(window: panel)
        syncPanelInteractivity(isHovering: isMouseInside)
        panel.orderFrontRegardless()
    }

    func deinitializeWindow() {
        guard let windowController else { return }
        windowController.close()
        self.windowController = nil
    }
}

struct HoverActivationGeometry {
    static let topEdgeTolerance: CGFloat = 1

    static func activationRect(
        screenFrame: NSRect,
        collapsedNotchSize: NSSize
    ) -> NSRect {
        let collapsedWidth = max(collapsedNotchSize.width, 1)
        let collapsedHeight = max(collapsedNotchSize.height, 1)

        return NSRect(
            x: screenFrame.midX - (collapsedWidth / 2.0),
            y: screenFrame.maxY - collapsedHeight,
            width: collapsedWidth,
            height: collapsedHeight + topEdgeTolerance
        )
    }
}

private final class HoverMonitor: ObservableObject {
    @Published var isHovering = false

    private var localMonitor: Any?
    private var globalMonitor: Any?

    private var collapsedNotchSize = NSSize(width: 300, height: 38)
    deinit {
        stopMonitoring()
    }

    func updateCollapsedNotchSize(_ size: NSSize) {
        collapsedNotchSize = size
        checkMouseLocation()
    }

    func startMonitoring() {
        guard localMonitor == nil, globalMonitor == nil else { return }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.checkMouseLocation()
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.checkMouseLocation()
        }

        checkMouseLocation()
    }

    func stopMonitoring() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }

        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }

    private func checkMouseLocation() {
        let mouseLoc = NSEvent.mouseLocation
        guard let screen = screenContaining(mouseLoc) else { return }

        let activeRect = HoverActivationGeometry.activationRect(
            screenFrame: screen.frame,
            collapsedNotchSize: collapsedNotchSize
        )

        let isNowHovering = activeRect.contains(mouseLoc)
        if isNowHovering != isHovering {
            isHovering = isNowHovering
        }
    }

    private func screenContaining(_ point: NSPoint) -> NSScreen? {
        let expandedScreens = NSScreen.screens.filter { screen in
            NSRect(
                x: screen.frame.minX,
                y: screen.frame.minY,
                width: screen.frame.width,
                height: screen.frame.height + HoverActivationGeometry.topEdgeTolerance
            ).contains(point)
        }

        return expandedScreens.first ?? NSScreen.screenWithMouse ?? NSScreen.screens.first
    }
}
