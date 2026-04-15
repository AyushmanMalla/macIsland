import XCTest
@testable import macIsland

final class ExpandedIslandLayoutTests: XCTestCase {
    func testMusicHeight_isStableBaseline() {
        XCTAssertEqual(ExpandedIslandLayout.musicHeight, 124)
    }

    func testTasksHeight_growsWhenRowsIncrease() {
        let small = ExpandedIslandLayout.tasksHeight(forVisibleTaskCount: 1)
        let larger = ExpandedIslandLayout.tasksHeight(forVisibleTaskCount: 4)

        XCTAssertGreaterThan(larger, small)
    }

    func testTasksHeight_capsAtMaximumHeight() {
        let capped = ExpandedIslandLayout.tasksHeight(forVisibleTaskCount: 20)
        XCTAssertEqual(capped, ExpandedIslandLayout.maxHeight)
    }

    func testVisibleTaskCountCapsBeforeHeightCalculation() {
        XCTAssertEqual(
            ExpandedIslandLayout.visibleTaskCount(forTotalTaskCount: 20),
            ExpandedIslandLayout.maxVisibleTaskRows
        )
    }
}
