import AppKit
import Combine
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var nowPlayingService = NowPlayingService()
    private var taskStore = TaskStore()
    private var dynamicNotchInfo: DynamicNotchInfo?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
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
            taskStore: taskStore
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

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
