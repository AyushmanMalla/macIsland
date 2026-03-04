import AppKit
import Combine

class HoverMonitor: ObservableObject {
    @Published var isHovering: Bool = false
    private var timer: Timer?

    // Notch safe hover zone (Collapsed)
    private let collapsedWidth: CGFloat = 180
    private let collapsedHeight: CGFloat = 38

    // Expanded zone (matches ExpandedNotchView bounds + some padding)
    private let expandedWidth: CGFloat = 480
    private let expandedHeight: CGFloat = 130

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.checkMouseLocation()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkMouseLocation() {
        guard let screen = NSScreen.main else { return }

        let mouseLoc = NSEvent.mouseLocation
        let screenFrame = screen.frame
        
        let width = isHovering ? expandedWidth : collapsedWidth
        let height = isHovering ? expandedHeight : collapsedHeight

        let xOrigin = screenFrame.midX - (width / 2.0)
        let yOrigin = screenFrame.maxY - height

        let activeRect = NSRect(
            x: xOrigin,
            y: yOrigin,
            width: width,
            height: height
        )

        let isNowHovering = activeRect.contains(mouseLoc)
        
        if isNowHovering != isHovering {
            isHovering = isNowHovering
        }
    }
}
