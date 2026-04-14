import AppKit
import Combine
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var pomodoroService = PomodoroTimerService()
    private var nowPlayingService = NowPlayingService()
    private var notificationService = NotificationService()
    private var dynamicNotchInfo: DynamicNotchInfo?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        notificationService.requestPermission()
        setupPomodoroNotifications()
        setupDynamicNotch()
        nowPlayingService.startObserving()
        setupNowPlayingNotifications()
    }

    func applicationWillTerminate(_ notification: Notification) {
        dynamicNotchInfo?.deinitializeNotchWindow()
        nowPlayingService.stopObserving()
    }

    private func setupDynamicNotch() {
        let dynamicNotchInfo = DynamicNotchInfo(
            style: .auto,
            nowPlayingService: nowPlayingService,
            pomodoroService: pomodoroService
        )
        dynamicNotchInfo.initializeNotchWindow()
        self.dynamicNotchInfo = dynamicNotchInfo
    }

    private func setupNowPlayingNotifications() {
        nowPlayingService.trackDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let dynamicNotchInfo = self.dynamicNotchInfo else { return }

                if !dynamicNotchInfo.isMouseInside {
                    dynamicNotchInfo.show(for: 2.2)
                }
            }
            .store(in: &cancellables)
    }

    private func setupPomodoroNotifications() {
        pomodoroService.$currentState
            .removeDuplicates()
            .sink { [weak self] state in
                self?.notificationService.sendPomodoroNotification(for: state)
            }
            .store(in: &cancellables)
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
