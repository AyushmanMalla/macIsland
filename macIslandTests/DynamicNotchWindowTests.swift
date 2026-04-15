import XCTest
import SwiftUI
@testable import macIsland

@MainActor
final class DynamicNotchWindowTests: XCTestCase {
    func testInitializeWindow_usesInteractiveNotchPanel() throws {
        guard let screen = NSScreen.screens.first else {
            throw XCTSkip("No screen available for panel test.")
        }

        let storageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let notch = DynamicNotch(
            style: .auto,
            nowPlayingService: NowPlayingService(),
            taskStore: TaskStore(storageURL: storageURL)
        ) {
            EmptyView()
        }

        notch.initializeWindow(screen: screen)
        defer { notch.deinitializeWindow() }

        XCTAssertTrue(notch.windowController?.window is NotchPanel)
        XCTAssertEqual(notch.windowController?.window?.canBecomeKey, true)
    }

    func testInitializeWindow_startsIgnoringMouseEventsUntilHoverActivation() throws {
        guard let screen = NSScreen.screens.first else {
            throw XCTSkip("No screen available for pass-through test.")
        }

        let storageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let notch = DynamicNotch(
            style: .auto,
            nowPlayingService: NowPlayingService(),
            taskStore: TaskStore(storageURL: storageURL)
        ) {
            EmptyView()
        }

        notch.initializeWindow(screen: screen)
        defer { notch.deinitializeWindow() }

        XCTAssertEqual(notch.windowController?.window?.ignoresMouseEvents, true)
        XCTAssertEqual(notch.windowController?.window?.isKeyWindow, false)
    }

    func testInitializeWindow_sizesContentViewToScreenFrame() throws {
        guard let screen = NSScreen.screens.first else {
            throw XCTSkip("No screen available for sizing test.")
        }

        let storageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let notch = DynamicNotch(
            style: .auto,
            nowPlayingService: NowPlayingService(),
            taskStore: TaskStore(storageURL: storageURL)
        ) {
            EmptyView()
        }

        notch.initializeWindow(screen: screen)
        defer { notch.deinitializeWindow() }

        XCTAssertEqual(notch.windowController?.window?.frame.size.width, screen.frame.size.width)
        XCTAssertEqual(notch.windowController?.window?.frame.size.height, screen.frame.size.height)
        XCTAssertEqual(notch.windowController?.window?.contentView?.frame.size.width, screen.frame.size.width)
        XCTAssertEqual(notch.windowController?.window?.contentView?.frame.size.height, screen.frame.size.height)
    }

    func testMouseInsideState_togglesPanelInteractivity() throws {
        guard let screen = NSScreen.screens.first else {
            throw XCTSkip("No screen available for interactivity toggle test.")
        }

        let storageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let notch = DynamicNotch(
            style: .auto,
            nowPlayingService: NowPlayingService(),
            taskStore: TaskStore(storageURL: storageURL)
        ) {
            EmptyView()
        }

        notch.initializeWindow(screen: screen)
        defer { notch.deinitializeWindow() }

        notch.isMouseInside = true
        XCTAssertEqual(notch.windowController?.window?.ignoresMouseEvents, false)

        notch.isMouseInside = false
        XCTAssertEqual(notch.windowController?.window?.ignoresMouseEvents, true)
    }
}
