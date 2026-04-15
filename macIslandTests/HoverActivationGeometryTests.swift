import XCTest
@testable import macIsland

final class HoverActivationGeometryTests: XCTestCase {
    func testCollapsedRectUsesCurrentNotchWidth() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let rect = HoverActivationGeometry.activationRect(
            screenFrame: screenFrame,
            collapsedNotchSize: NSSize(width: 220, height: 38)
        )

        XCTAssertEqual(rect.width, 220, accuracy: 0.001)
    }

    func testActivationRectTracksCurrentNotchHeight() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let collapsedHeight: CGFloat = 38
        let rect = HoverActivationGeometry.activationRect(
            screenFrame: screenFrame,
            collapsedNotchSize: NSSize(width: 220, height: collapsedHeight)
        )

        let expectedHeight =
            collapsedHeight
            + HoverActivationGeometry.topEdgeTolerance
        XCTAssertEqual(rect.height, expectedHeight, accuracy: 0.001)
    }

    func testActivationRectDoesNotUseExpandedRegionHeight() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let collapsedSize = NSSize(width: 220, height: 38)

        let rect = HoverActivationGeometry.activationRect(
            screenFrame: screenFrame,
            collapsedNotchSize: collapsedSize
        )

        let pointBelowCollapsedRegion = CGPoint(x: screenFrame.midX, y: screenFrame.maxY - 100)
        XCTAssertFalse(rect.contains(pointBelowCollapsedRegion))
    }

    func testTopEdgePointIsStillInsideActivationRect() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let rect = HoverActivationGeometry.activationRect(
            screenFrame: screenFrame,
            collapsedNotchSize: NSSize(width: 220, height: 38)
        )

        let topCenterPoint = CGPoint(x: screenFrame.midX, y: screenFrame.maxY)
        XCTAssertTrue(rect.contains(topCenterPoint))
    }
}
