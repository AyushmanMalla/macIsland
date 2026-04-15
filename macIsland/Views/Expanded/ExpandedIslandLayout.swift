import CoreGraphics

enum ExpandedIslandLayout {
    static let width: CGFloat = 380
    static let musicHeight: CGFloat = 124
    static let segmentedControlHeight: CGFloat = 32
    static let inputRowHeight: CGFloat = 36
    static let taskRowHeight: CGFloat = 34
    static let verticalPadding: CGFloat = 18
    static let rowSpacing: CGFloat = 8
    static let maxVisibleTaskRows = 5
    static let maxHeight: CGFloat = 260

    static func visibleTaskCount(forTotalTaskCount count: Int) -> Int {
        min(max(count, 0), maxVisibleTaskRows)
    }

    static func tasksHeight(forVisibleTaskCount count: Int) -> CGFloat {
        let visibleRows = visibleTaskCount(forTotalTaskCount: count)
        let rowsHeight = CGFloat(visibleRows) * taskRowHeight
        let spacingHeight = CGFloat(max(visibleRows - 1, 0)) * rowSpacing
        let measured = verticalPadding * 2
            + segmentedControlHeight
            + inputRowHeight
            + 16
            + rowsHeight
            + spacingHeight

        return min(max(measured, musicHeight), maxHeight)
    }
}
