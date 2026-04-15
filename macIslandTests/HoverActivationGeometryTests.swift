import XCTest
@testable import macIsland

final class HoverActivationGeometryTests: XCTestCase {
    func testCollapsedRectUsesCurrentNotchWidth() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let rect = HoverActivationGeometry.activeRect(
            screenFrame: screenFrame,
            isHovering: false,
            collapsedNotchSize: NSSize(width: 220, height: 38),
            expandedContentHeight: ExpandedIslandLayout.musicHeight
        )

        XCTAssertEqual(rect.width, 220, accuracy: 0.001)
    }

    func testExpandedRectUsesCurrentExpandedHeight() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let rect = HoverActivationGeometry.activeRect(
            screenFrame: screenFrame,
            isHovering: true,
            collapsedNotchSize: NSSize(width: 220, height: 38),
            expandedContentHeight: ExpandedIslandLayout.musicHeight
        )

        XCTAssertEqual(rect.height, ExpandedIslandLayout.musicHeight + 24 + 1, accuracy: 0.001)

        let pointWellBelowMusicHeight = CGPoint(x: screenFrame.midX, y: screenFrame.maxY - 200)
        XCTAssertFalse(rect.contains(pointWellBelowMusicHeight))
    }

    func testTopEdgePointIsStillInsideActivationRect() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let rect = HoverActivationGeometry.activeRect(
            screenFrame: screenFrame,
            isHovering: false,
            collapsedNotchSize: NSSize(width: 220, height: 38),
            expandedContentHeight: ExpandedIslandLayout.musicHeight
        )

        let topCenterPoint = CGPoint(x: screenFrame.midX, y: screenFrame.maxY)
        XCTAssertTrue(rect.contains(topCenterPoint))
    }
}
