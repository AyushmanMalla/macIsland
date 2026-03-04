import AppKit
import SwiftUI

class NotchPanel: NSPanel {
    private var hostingView: NSHostingView<AnyView>?


    init<Content: View>(
        contentRect: NSRect,
        contentView: Content
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        setupHostingView(contentView)
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

    /// CRITICAL: This prevents macOS from forcing the window below the menu bar!
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect 
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
