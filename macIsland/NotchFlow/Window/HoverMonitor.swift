import AppKit
import Combine

class HoverMonitor: ObservableObject {
    @Published var isHovering: Bool = false
    private var localMonitor: Any?
    private var globalMonitor: Any?

    // Notch safe hover zone (Collapsed)
    private let collapsedWidth: CGFloat = 180
    private let collapsedHeight: CGFloat = 38

    // Expanded zone sized to the largest island state, with a little tolerance for motion.
    private let expandedWidth: CGFloat = ExpandedIslandLayout.width + 60
    private let expandedHeight: CGFloat = ExpandedIslandLayout.maxHeight + 24
    
    deinit {
        stopMonitoring()
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
        
        // Initial check
        checkMouseLocation()
    }

    func stopMonitoring() {
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }

    private func checkMouseLocation() {
        guard let screen = NSScreen.screenWithMouse ?? NSScreen.screens.first else { return }

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
