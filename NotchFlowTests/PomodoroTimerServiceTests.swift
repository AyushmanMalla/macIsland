import XCTest
@testable import NotchFlow

final class PomodoroTimerServiceTests: XCTestCase {

    var sut: PomodoroTimerService!

    override func setUp() {
        super.setUp()
        sut = PomodoroTimerService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateIsIdle() {
        XCTAssertEqual(sut.currentState, .idle)
        XCTAssertEqual(sut.timeRemaining, 0)
        XCTAssertEqual(sut.completedSessions, 0)
    }

    func testInitialProgressIsZero() {
        XCTAssertEqual(sut.progress, 0)
    }

    func testInitialTimeStringIsZero() {
        XCTAssertEqual(sut.timeString, "00:00")
    }

    // MARK: - Start

    func testStartTransitionsToWorking() {
        sut.start()
        XCTAssertEqual(sut.currentState, .working)
    }

    func testStartSetsTimeRemainingTo25Minutes() {
        sut.start()
        XCTAssertEqual(sut.timeRemaining, 25 * 60)
    }

    func testStartOnlyWorksFromIdle() {
        sut.transitionTo(.shortBreak)
        let state = sut.currentState
        sut.start()
        XCTAssertEqual(sut.currentState, state) // Should not change
    }

    // MARK: - Pause / Resume

    func testPauseFromWorking() {
        sut.start()
        sut.pause()
        XCTAssertEqual(sut.currentState, .paused(previousState: .working))
    }

    func testResumeFromPaused() {
        sut.start()
        sut.pause()
        sut.resume()
        XCTAssertEqual(sut.currentState, .working)
    }

    func testPauseFromIdle_doesNothing() {
        sut.pause()
        XCTAssertEqual(sut.currentState, .idle)
    }

    func testResumeFromNonPaused_doesNothing() {
        sut.start()
        sut.resume() // Not paused, should do nothing
        XCTAssertEqual(sut.currentState, .working)
    }

    // MARK: - Toggle

    func testToggleFromIdle_starts() {
        sut.toggleStartPause()
        XCTAssertEqual(sut.currentState, .working)
    }

    func testToggleFromWorking_pauses() {
        sut.start()
        sut.toggleStartPause()
        XCTAssertEqual(sut.currentState, .paused(previousState: .working))
    }

    func testToggleFromPaused_resumes() {
        sut.start()
        sut.pause()
        sut.toggleStartPause()
        XCTAssertEqual(sut.currentState, .working)
    }

    // MARK: - Reset

    func testResetGoesBackToIdle() {
        sut.start()
        sut.reset()
        XCTAssertEqual(sut.currentState, .idle)
        XCTAssertEqual(sut.timeRemaining, 0)
        XCTAssertEqual(sut.completedSessions, 0)
    }

    // MARK: - State Durations

    func testWorkingDuration() {
        XCTAssertEqual(PomodoroState.working.duration, 25 * 60)
    }

    func testShortBreakDuration() {
        XCTAssertEqual(PomodoroState.shortBreak.duration, 5 * 60)
    }

    func testLongBreakDuration() {
        XCTAssertEqual(PomodoroState.longBreak.duration, 15 * 60)
    }

    func testIdleDuration() {
        XCTAssertEqual(PomodoroState.idle.duration, 0)
    }

    // MARK: - Display Names

    func testDisplayNames() {
        XCTAssertEqual(PomodoroState.idle.displayName, "Ready")
        XCTAssertEqual(PomodoroState.working.displayName, "Focus")
        XCTAssertEqual(PomodoroState.shortBreak.displayName, "Short Break")
        XCTAssertEqual(PomodoroState.longBreak.displayName, "Long Break")
        XCTAssertEqual(PomodoroState.paused(previousState: .working).displayName, "Paused")
    }

    // MARK: - Progress Calculation

    func testProgressCalculation() {
        sut.transitionTo(.working)
        // At start, timeRemaining = 25*60, so progress should be ~0
        XCTAssertEqual(sut.progress, 0, accuracy: 0.01)
    }

    func testProgressAtHalfway() {
        sut.transitionTo(.working)
        sut.timeRemaining = 12.5 * 60 // Half of 25 minutes
        XCTAssertEqual(sut.progress, 0.5, accuracy: 0.01)
    }

    // MARK: - Time String Format

    func testTimeStringFormat() {
        sut.transitionTo(.working)
        XCTAssertEqual(sut.timeString, "25:00")
    }

    func testTimeStringFormatWithSeconds() {
        sut.transitionTo(.working)
        sut.timeRemaining = 5 * 60 + 30
        XCTAssertEqual(sut.timeString, "05:30")
    }
}
