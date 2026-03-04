import AppKit

struct NotchPositionManager {
    // Notch dimensions — spans the hardware notch with transparent center
    static let collapsedWidth: CGFloat = 340
    static let collapsedHeight: CGFloat = 38

    // Expanded panel dimensions - horizontal pill shape
    static let expandedWidth: CGFloat = 480
    static let expandedHeight: CGFloat = 124

    /// Calculate the collapsed panel frame — flush with the top edge of the screen
    func calculateCollapsedFrame(for screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame

        // Flush to the very top of the screen, centered horizontally
        let x = screenFrame.midX - (Self.collapsedWidth / 2)
        let y = screenFrame.maxY - Self.collapsedHeight

        return NSRect(
            x: x,
            y: y,
            width: Self.collapsedWidth,
            height: Self.collapsedHeight
        )
    }

    /// Calculate the expanded panel frame — drops down from top edge like Dynamic Island
    func calculateExpandedFrame(for screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame

        // Stays flush to top, extends downward
        let x = screenFrame.midX - (Self.expandedWidth / 2)
        let y = screenFrame.maxY - Self.expandedHeight

        return NSRect(
            x: x,
            y: y,
            width: Self.expandedWidth,
            height: Self.expandedHeight
        )
    }

    /// Check if the current Mac has a notch
    var hasNotch: Bool {
        guard let screen = NSScreen.main else { return false }
        if #available(macOS 12.0, *) {
            return screen.safeAreaInsets.top > 0
        }
        return false
    }
}
