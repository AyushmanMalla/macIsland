import AppKit
import SwiftUI

class NotchPanel: NSPanel {
    private var hostingView: NSHostingView<AnyView>?
    private var trackingArea: NSTrackingArea?
    private var onMouseEntered: (() -> Void)?
    private var onMouseExited: (() -> Void)?

    init<Content: View>(
        contentRect: NSRect,
        contentView: Content,
        onMouseEntered: @escaping () -> Void,
        onMouseExited: @escaping () -> Void
    ) {
        self.onMouseEntered = onMouseEntered
        self.onMouseExited = onMouseExited

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        setupHostingView(contentView)
        setupTrackingArea()
    }

    private func configurePanel() {
        // Above everything, including the menu bar
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false

        // Non-activating: don't steal focus
        self.becomesKeyOnlyIfNeeded = true
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false

        // Mouse events
        self.acceptsMouseMovedEvents = true
        self.ignoresMouseEvents = false
    }

    private func setupHostingView<Content: View>(_ content: Content) {
        let hosting = NSHostingView(rootView: AnyView(content))
        hosting.frame = self.contentView?.bounds ?? .zero
        hosting.autoresizingMask = [.width, .height]
        hosting.layer?.backgroundColor = .clear

        self.contentView?.addSubview(hosting)
        self.hostingView = hosting
    }

    func setupTrackingArea() {
        if let existing = trackingArea {
            self.contentView?.removeTrackingArea(existing)
        }

        let area = NSTrackingArea(
            rect: self.contentView?.bounds ?? .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        self.contentView?.addTrackingArea(area)
        self.trackingArea = area
    }

    /// Animate the panel frame change with a smooth spring-like feel
    func animateToFrame(_ frame: NSRect, duration: TimeInterval = 0.45) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1.0)
            context.allowsImplicitAnimation = true
            self.animator().setFrame(frame, display: true)
        } completionHandler: { [weak self] in
            self?.setupTrackingArea()
        }
    }

    override func mouseEntered(with event: NSEvent) {
        onMouseEntered?()
    }

    override func mouseExited(with event: NSEvent) {
        onMouseExited?()
    }

    /// CRITICAL: This prevents macOS from forcing the window below the menu bar!
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect 
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
