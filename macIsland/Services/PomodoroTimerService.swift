import Foundation
import Combine

/// Classic Pomodoro timer: 25min work / 5min break / 15min long break every 4 cycles
class PomodoroTimerService: ObservableObject {
    @Published var currentState: PomodoroState = .idle
    @Published var timeRemaining: TimeInterval = 0
    @Published var completedSessions: Int = 0

    private var timer: AnyCancellable?
    private let sessionsBeforeLongBreak = 4

    /// Progress from 0.0 to 1.0
    var progress: Double {
        let total = currentState.duration
        guard total > 0 else { return 0 }
        return 1.0 - (timeRemaining / total)
    }

    /// Formatted time string (mm:ss)
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func start() {
        guard case .idle = currentState else { return }
        transitionTo(.working)
    }

    func pause() {
        switch currentState {
        case .working, .shortBreak, .longBreak:
            let previousState = currentState
            stopTimer()
            currentState = .paused(previousState: previousState)
        default:
            break
        }
    }

    func resume() {
        guard case .paused(let previousState) = currentState else { return }
        currentState = previousState
        startTimer()
    }

    func reset() {
        stopTimer()
        currentState = .idle
        timeRemaining = 0
        completedSessions = 0
    }

    func toggleStartPause() {
        switch currentState {
        case .idle:
            start()
        case .working, .shortBreak, .longBreak:
            pause()
        case .paused:
            resume()
        }
    }

    // MARK: - Internal

    func transitionTo(_ state: PomodoroState) {
        currentState = state
        timeRemaining = state.duration
        startTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        guard timeRemaining > 0 else { return }
        timeRemaining -= 1

        if timeRemaining <= 0 {
            advanceToNextState()
        }
    }

    private func advanceToNextState() {
        stopTimer()

        switch currentState {
        case .working:
            completedSessions += 1
            if completedSessions % sessionsBeforeLongBreak == 0 {
                transitionTo(.longBreak)
            } else {
                transitionTo(.shortBreak)
            }
        case .shortBreak, .longBreak:
            transitionTo(.working)
        default:
            break
        }
    }
}
