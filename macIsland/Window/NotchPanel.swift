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
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        setupHostingView(contentView)
    }

    private func configurePanel() {
        self.level = .mainMenu + 3
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovable = false
        self.isReleasedWhenClosed = false

        self.becomesKeyOnlyIfNeeded = true
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false

        self.acceptsMouseMovedEvents = true
        self.ignoresMouseEvents = false
    }

    private func setupHostingView<Content: View>(_ content: Content) {
        let hosting = NSHostingView(rootView: AnyView(content))
        hosting.frame = NSRect(origin: .zero, size: frame.size)
        hosting.autoresizingMask = [.width, .height]
        self.contentView = hosting
        self.hostingView = hosting
    }

    /// CRITICAL: This prevents macOS from forcing the window below the menu bar!
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect 
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
