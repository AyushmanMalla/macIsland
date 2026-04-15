# Daily Tasks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current hover-expanded music-only island with a segmented `Music | Tasks` experience backed by persistent JSON storage, inline task editing, and graceful content-driven height changes.

**Architecture:** The active hover UI lives in `DynamicNotchKit/NotchView.swift`, so this feature should be implemented by extracting a new expanded island surface and wiring it into the existing `DynamicNotch` path instead of reviving the older fixed-size `ExpandedNotchView` path. Task data lives in a lightweight `TaskStore`, while the expanded island owns only session-scoped tab state and uses a shared layout helper to clamp animated height growth.

**Tech Stack:** SwiftUI, AppKit `NSPanel`, Combine, JSON persistence with `FileManager`, XCTest, `xcodebuild`

---

## File Structure

### Create

- `macIsland/Models/TaskItem.swift`
  Defines the persistent task model and the session-only `ExpandedTab` enum.
- `macIsland/Services/TaskStore.swift`
  Owns load/save/mutate logic for tasks and exposes a sorted task list for the UI.
- `macIsland/Views/Expanded/ExpandedIslandLayout.swift`
  Centralizes width, base heights, max heights, and clamping logic for animated growth.
- `macIsland/Views/Expanded/ExpandedIslandView.swift`
  New top-level expanded hover surface with segmented control and animated tab switching.
- `macIsland/Views/Expanded/MusicTabView.swift`
  Extracts the current hover music view out of `NotchView.swift`.
- `macIsland/Views/Expanded/TasksView.swift`
  Renders the inline add-task field, empty state, and scrollable task list.
- `macIsland/Views/Expanded/TaskRowView.swift`
  Renders one task row, inline edit state, completion styling, and context menu.
- `macIslandTests/TaskStoreTests.swift`
  Covers task ordering and persistence.
- `macIslandTests/ExpandedIslandLayoutTests.swift`
  Covers dynamic height clamping rules.

### Modify

- `macIsland/AppDelegate.swift`
  Creates and injects `TaskStore`; removes Pomodoro startup wiring from the active app path.
- `macIsland/DynamicNotchKit/DynamicNotchInfo.swift`
  Stops threading Pomodoro through the active notch path and passes the task store onward.
- `macIsland/DynamicNotchKit/DynamicNotch.swift`
  Stores `TaskStore` and session tab state on the active notch object.
- `macIsland/DynamicNotchKit/NotchView.swift`
  Replaces the inline hover player with `ExpandedIslandView`.

### Optional Cleanup After Feature Is Working

- Delete stale, unused Pomodoro-facing UI files once the new path is verified:
  - `macIsland/Views/NotchContentView.swift`
  - `macIsland/Views/Expanded/ExpandedNotchView.swift`
  - `macIsland/Views/Expanded/PomodoroTimerView.swift`
  - `macIsland/Views/Collapsed/CollapsedNotchView.swift`
  - `macIsland/Views/Collapsed/PomodoroRingIndicator.swift`
  - `macIsland/Services/NotificationService.swift`

### Git Preference

Do not create commits while executing this plan. Hand git staging and commits back to the user.

## Task 1: Build The Persistent Task Model And Store

**Files:**
- Create: `macIsland/Models/TaskItem.swift`
- Create: `macIsland/Services/TaskStore.swift`
- Test: `macIslandTests/TaskStoreTests.swift`

- [ ] **Step 1: Write the failing tests for task ordering and persistence**

```swift
import XCTest
@testable import macIsland

final class TaskStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testAddTask_createsIncompleteTaskAtTopGroup() throws {
        let store = TaskStore(storageURL: tempDirectory.appendingPathComponent("tasks.json"))

        store.addTask(title: "Write plan")

        XCTAssertEqual(store.tasks.map(\.title), ["Write plan"])
        XCTAssertEqual(store.tasks.first?.isCompleted, false)
    }

    func testToggleCompletion_movesTaskBelowIncompleteTasks() throws {
        let store = TaskStore(storageURL: tempDirectory.appendingPathComponent("tasks.json"))
        store.addTask(title: "First")
        store.addTask(title: "Second")

        let firstID = try XCTUnwrap(store.tasks.first?.id)
        store.toggleCompletion(id: firstID)

        XCTAssertEqual(store.tasks.map(\.title), ["Second", "First"])
        XCTAssertEqual(store.tasks.last?.isCompleted, true)
    }

    func testEditTask_updatesTitleWithoutChangingOrdering() throws {
        let store = TaskStore(storageURL: tempDirectory.appendingPathComponent("tasks.json"))
        store.addTask(title: "Draft")

        let id = try XCTUnwrap(store.tasks.first?.id)
        store.editTask(id: id, title: "Final")

        XCTAssertEqual(store.tasks.map(\.title), ["Final"])
    }

    func testDeleteTask_removesTask() throws {
        let store = TaskStore(storageURL: tempDirectory.appendingPathComponent("tasks.json"))
        store.addTask(title: "Remove me")

        let id = try XCTUnwrap(store.tasks.first?.id)
        store.deleteTask(id: id)

        XCTAssertTrue(store.tasks.isEmpty)
    }

    func testPersistenceRoundTrip_restoresSortedTasks() throws {
        let url = tempDirectory.appendingPathComponent("tasks.json")
        let writer = TaskStore(storageURL: url)
        writer.addTask(title: "Active")
        writer.addTask(title: "Done")

        let doneID = try XCTUnwrap(writer.tasks.last?.id)
        writer.toggleCompletion(id: doneID)

        let reader = TaskStore(storageURL: url)
        XCTAssertEqual(reader.tasks.map(\.title), ["Active", "Done"])
        XCTAssertEqual(reader.tasks.last?.isCompleted, true)
    }
}
```

- [ ] **Step 2: Run the new test target and verify it fails**

Run:

```bash
xcodebuild test \
  -project macIsland.xcodeproj \
  -scheme macIsland \
  -destination 'platform=macOS' \
  -only-testing:macIslandTests/TaskStoreTests
```

Expected: FAIL with errors such as `Cannot find 'TaskStore' in scope` and `Cannot find type 'TaskItem' in scope`.

- [ ] **Step 3: Implement `TaskItem` and `TaskStore` with injected JSON storage**

`macIsland/Models/TaskItem.swift`

```swift
import Foundation

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    let createdAt: Date
    var completedAt: Date?
    var updatedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.updatedAt = updatedAt
    }
}

enum ExpandedTab: String, CaseIterable, Identifiable {
    case music
    case tasks

    var id: Self { self }
}
```

`macIsland/Services/TaskStore.swift`

```swift
import Foundation
import Combine

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []

    private let storageURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? Self.defaultStorageURL()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    func addTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        tasks.append(TaskItem(title: trimmed))
        sortAndSave()
    }

    func toggleCompletion(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted.toggle()
        tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
        tasks[index].updatedAt = Date()
        sortAndSave()
    }

    func editTask(id: UUID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].title = trimmed
        tasks[index].updatedAt = Date()
        sortAndSave()
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else {
            tasks = []
            return
        }
        tasks = (try? decoder.decode([TaskItem].self, from: data)) ?? []
        sortInPlace()
    }

    private func sortAndSave() {
        sortInPlace()
        save()
    }

    private func sortInPlace() {
        tasks.sort {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            if $0.isCompleted {
                return ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast)
            }
            return $0.createdAt < $1.createdAt
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            let data = try encoder.encode(tasks)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("macIsland: Failed to save tasks: \\(error)")
        }
    }

    private static func defaultStorageURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base
            .appendingPathComponent("macIsland", isDirectory: true)
            .appendingPathComponent("tasks.json")
    }
}
```

- [ ] **Step 4: Run the tests again and verify they pass**

Run:

```bash
xcodebuild test \
  -project macIsland.xcodeproj \
  -scheme macIsland \
  -destination 'platform=macOS' \
  -only-testing:macIslandTests/TaskStoreTests
```

Expected: PASS for all `TaskStoreTests`.

- [ ] **Step 5: Review the diff and hand git actions to the user**

Check:

```bash
git diff -- macIsland/Models/TaskItem.swift macIsland/Services/TaskStore.swift macIslandTests/TaskStoreTests.swift
```

Expected: new task model, new persistent store, and passing tests with no unrelated file churn.

## Task 2: Add Dynamic Height Rules For The Expanded Island

**Files:**
- Create: `macIsland/Views/Expanded/ExpandedIslandLayout.swift`
- Test: `macIslandTests/ExpandedIslandLayoutTests.swift`

- [ ] **Step 1: Write the failing tests for height growth and clamping**

```swift
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
```

- [ ] **Step 2: Run the layout tests and verify they fail**

Run:

```bash
xcodebuild test \
  -project macIsland.xcodeproj \
  -scheme macIsland \
  -destination 'platform=macOS' \
  -only-testing:macIslandTests/ExpandedIslandLayoutTests
```

Expected: FAIL with errors such as `Cannot find 'ExpandedIslandLayout' in scope`.

- [ ] **Step 3: Implement shared layout constants and clamping helpers**

`macIsland/Views/Expanded/ExpandedIslandLayout.swift`

```swift
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
        let measured = verticalPadding * 2 + segmentedControlHeight + inputRowHeight + 16 + rowsHeight + spacingHeight
        return min(max(measured, musicHeight), maxHeight)
    }
}
```

Use these constants everywhere the expanded island computes width or height so animation targets stay consistent.

- [ ] **Step 4: Run the tests again and verify they pass**

Run:

```bash
xcodebuild test \
  -project macIsland.xcodeproj \
  -scheme macIsland \
  -destination 'platform=macOS' \
  -only-testing:macIslandTests/ExpandedIslandLayoutTests
```

Expected: PASS for all `ExpandedIslandLayoutTests`.

- [ ] **Step 5: Review the diff and hand git actions to the user**

Check:

```bash
git diff -- macIsland/Views/Expanded/ExpandedIslandLayout.swift macIslandTests/ExpandedIslandLayoutTests.swift
```

Expected: one small layout helper and a focused test file.

## Task 3: Build The `Music | Tasks` Expanded Island UI

**Files:**
- Create: `macIsland/Views/Expanded/ExpandedIslandView.swift`
- Create: `macIsland/Views/Expanded/MusicTabView.swift`
- Create: `macIsland/Views/Expanded/TasksView.swift`
- Create: `macIsland/Views/Expanded/TaskRowView.swift`
- Modify: `macIsland/DynamicNotchKit/NotchView.swift`

- [ ] **Step 1: Extract the current hover music UI into `MusicTabView`**

`macIsland/Views/Expanded/MusicTabView.swift`

```swift
import SwiftUI

struct MusicTabView: View {
    @ObservedObject var nowPlayingService: NowPlayingService

    private var title: String {
        nowPlayingService.trackInfo.hasContent ? nowPlayingService.trackInfo.title : "No Music"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: nowPlayingService.openCurrentPlayerApp) {
                PlayerArtworkView(image: nowPlayingService.trackInfo.albumArt)
            }
            .buttonStyle(.plain)

            VStack(alignment: .center, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                if !nowPlayingService.trackInfo.artist.isEmpty {
                    Text(nowPlayingService.trackInfo.artist)
                        .foregroundStyle(.secondary)
                        .font(.headline)
                        .lineLimit(1)
                }
                PlaybackButtons(nowPlayingService: nowPlayingService)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: ExpandedIslandLayout.width - 30)
    }
}
```

Move `PlaybackButtons` and `PlayerArtworkView` into this file so `NotchView.swift` stops owning the expanded content details.

- [ ] **Step 2: Create `TaskRowView` with inline edit mode and context menu**

`macIsland/Views/Expanded/TaskRowView.swift`

```swift
import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let isEditing: Bool
    @Binding var draftTitle: String
    let onToggle: () -> Void
    let onBeginEdit: () -> Void
    let onCommitEdit: () -> Void
    let onCancelEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("Edit task", text: $draftTitle)
                    .textFieldStyle(.plain)
                    .onSubmit(onCommitEdit)
                Button(action: onCommitEdit) {
                    Image(systemName: "checkmark.circle.fill")
                }
                .buttonStyle(.plain)
                Button(action: onCancelEdit) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
            } else {
                Text(task.title)
                    .strikethrough(task.isCompleted, color: .white.opacity(0.6))
                    .foregroundStyle(task.isCompleted ? .white.opacity(0.5) : .white.opacity(0.92))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(height: ExpandedIslandLayout.taskRowHeight)
        .contentShape(Rectangle())
        .contextMenu {
            Button(task.isCompleted ? "Mark Incomplete" : "Complete", action: onToggle)
            Button("Edit", action: onBeginEdit)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
```

- [ ] **Step 3: Create `TasksView` with inline input, list, scrolling, and task-triggered height animation**

`macIsland/Views/Expanded/TasksView.swift`

```swift
import SwiftUI

struct TasksView: View {
    @ObservedObject var taskStore: TaskStore
    @State private var newTaskTitle = ""
    @State private var editingTaskID: UUID?
    @State private var editingDraft = ""

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .foregroundStyle(.white.opacity(0.65))
                TextField("Add a task for today", text: $newTaskTitle)
                    .textFieldStyle(.plain)
                    .onSubmit(addTask)
            }
            .padding(.horizontal, 12)
            .frame(height: ExpandedIslandLayout.inputRowHeight)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: ExpandedIslandLayout.rowSpacing) {
                    ForEach(taskStore.tasks) { task in
                        TaskRowView(
                            task: task,
                            isEditing: editingTaskID == task.id,
                            draftTitle: Binding(
                                get: { editingTaskID == task.id ? editingDraft : task.title },
                                set: { editingDraft = $0 }
                            ),
                            onToggle: { taskStore.toggleCompletion(id: task.id) },
                            onBeginEdit: {
                                editingTaskID = task.id
                                editingDraft = task.title
                            },
                            onCommitEdit: {
                                taskStore.editTask(id: task.id, title: editingDraft)
                                editingTaskID = nil
                            },
                            onCancelEdit: { editingTaskID = nil },
                            onDelete: { taskStore.deleteTask(id: task.id) }
                        )
                    }
                }
            }
            .frame(maxHeight: ExpandedIslandLayout.maxHeight - 110)
        }
        .animation(.snappy(duration: 0.28, extraBounce: 0.02), value: taskStore.tasks)
    }

    private func addTask() {
        taskStore.addTask(title: newTaskTitle)
        newTaskTitle = ""
    }
}
```

- [ ] **Step 4: Create `ExpandedIslandView` and swap it into `NotchView.swift`**

`macIsland/Views/Expanded/ExpandedIslandView.swift`

```swift
import SwiftUI

struct ExpandedIslandView: View {
    @ObservedObject var nowPlayingService: NowPlayingService
    @ObservedObject var taskStore: TaskStore
    @Binding var selectedTab: ExpandedTab

    private var animatedHeight: CGFloat {
        switch selectedTab {
        case .music:
            ExpandedIslandLayout.musicHeight
        case .tasks:
            ExpandedIslandLayout.tasksHeight(forVisibleTaskCount: taskStore.tasks.count)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            Picker("", selection: $selectedTab) {
                Text("Music").tag(ExpandedTab.music)
                Text("Tasks").tag(ExpandedTab.tasks)
            }
            .pickerStyle(.segmented)
            .frame(width: 164)

            ZStack {
                switch selectedTab {
                case .music:
                    MusicTabView(nowPlayingService: nowPlayingService)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                case .tasks:
                    TasksView(taskStore: taskStore)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .frame(height: animatedHeight - 50, alignment: .top)
        }
        .padding(.horizontal, 15)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .frame(width: ExpandedIslandLayout.width, height: animatedHeight, alignment: .top)
        .animation(.snappy(duration: 0.30, extraBounce: 0.04), value: selectedTab)
        .animation(.snappy(duration: 0.30, extraBounce: 0.02), value: taskStore.tasks.count)
    }
}
```

`macIsland/DynamicNotchKit/NotchView.swift`

```swift
if dynamicNotch.isMouseInside {
    ExpandedIslandView(
        nowPlayingService: dynamicNotch.nowPlayingService,
        taskStore: dynamicNotch.taskStore,
        selectedTab: $dynamicNotch.selectedTab
    )
    .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 15) }
    .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: 15) }
    .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: 15) }
    .blur(radius: dynamicNotch.isVisible ? 0 : 10)
    .scaleEffect(dynamicNotch.isVisible ? 1 : 0.8)
    .offset(y: dynamicNotch.isVisible ? 0 : 5)
    .padding(.horizontal, 15)
    .transition(.blur.animation(.smooth))
}
```

- [ ] **Step 5: Build the app and manually verify the new expanded UI compiles**

Run:

```bash
xcodebuild build \
  -project macIsland.xcodeproj \
  -scheme macIsland \
  -destination 'platform=macOS'
```

Expected: `BUILD SUCCEEDED`.

Manual check:

- Hovering the island shows the segmented `Music | Tasks` control.
- `Music` appears first.
- Switching tabs animates horizontally with fade.
- Task rows render with inline input and scroll once the list becomes tall.

## Task 4: Wire Session State Into The Live Notch Path And Remove Active Pomodoro Plumbing

**Files:**
- Modify: `macIsland/AppDelegate.swift`
- Modify: `macIsland/DynamicNotchKit/DynamicNotchInfo.swift`
- Modify: `macIsland/DynamicNotchKit/DynamicNotch.swift`

- [ ] **Step 1: Remove Pomodoro and notification startup from `AppDelegate.swift`**

Replace the active app-level setup with only the services still used by the live UI:

```swift
import AppKit
import Combine
import SwiftUI

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
}
```

- [ ] **Step 2: Thread `TaskStore` through `DynamicNotchInfo` and `DynamicNotch`**

`macIsland/DynamicNotchKit/DynamicNotchInfo.swift`

```swift
final class DynamicNotchInfo {
    init(
        contentID: UUID = .init(),
        style: DynamicNotch<InfoView>.Style = .auto,
        nowPlayingService: NowPlayingService,
        taskStore: TaskStore
    ) {
        self.internalDynamicNotch = DynamicNotch(
            contentID: contentID,
            style: style,
            nowPlayingService: nowPlayingService,
            taskStore: taskStore
        ) {
            InfoView(nowPlayingService: nowPlayingService)
        }
    }
}
```

`macIsland/DynamicNotchKit/DynamicNotch.swift`

```swift
final class DynamicNotch<Content>: ObservableObject where Content: View {
    @Published var nowPlayingService: NowPlayingService
    @Published var taskStore: TaskStore
    @Published var selectedTab: ExpandedTab = .music
    @Published var content: () -> Content
    @Published var contentID: UUID
    @Published var isVisible = false
    @Published var isNotificationVisible = false
    @Published var notchWidth: CGFloat = 0
    @Published var notchHeight: CGFloat = 0
    @Published var isMouseInside = false

    init(
        contentID: UUID = .init(),
        style: Style = .auto,
        nowPlayingService: NowPlayingService,
        taskStore: TaskStore,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.contentID = contentID
        self.content = content
        self.notchStyle = style
        self.nowPlayingService = nowPlayingService
        self.taskStore = taskStore
        // keep the rest of the existing screen-change subscription intact
    }
}
```

Session rule: do not write `selectedTab` to disk. It should default to `.music` on every app launch.

- [ ] **Step 3: Rebuild the app and verify there are no remaining active Pomodoro references**

Run:

```bash
rg -n "pomodoroService|setupPomodoroNotifications|NotificationService" macIsland/AppDelegate.swift macIsland/DynamicNotchKit
xcodebuild build \
  -project macIsland.xcodeproj \
  -scheme macIsland \
  -destination 'platform=macOS'
```

Expected:

- `rg` returns no matches in the active app path.
- `xcodebuild` prints `BUILD SUCCEEDED`.

- [ ] **Step 4: Manually verify session-only tab state and animated resizing**

Manual check:

- Launch the app and hover to expand; `Music` is selected.
- Switch to `Tasks`, collapse, and hover again; `Tasks` is still selected within the same app session.
- Quit and relaunch the app; `Music` is selected again.
- Add tasks until the island grows; verify height changes animate instead of snapping.
- Add enough tasks to hit the height cap; verify the island stops growing and the list scrolls inside it.
- Complete, edit, and delete tasks from the context menu; verify the list reorders smoothly.

- [ ] **Step 5: Review the diff and hand git actions to the user**

Check:

```bash
git diff -- \
  macIsland/AppDelegate.swift \
  macIsland/DynamicNotchKit/DynamicNotchInfo.swift \
  macIsland/DynamicNotchKit/DynamicNotch.swift \
  macIsland/DynamicNotchKit/NotchView.swift
```

Expected: the active notch path knows about `TaskStore` and `ExpandedTab`, while Pomodoro startup wiring is gone.

## Task 5: Final Verification And Optional Cleanup

**Files:**
- Optional delete: `macIsland/Views/NotchContentView.swift`
- Optional delete: `macIsland/Views/Expanded/ExpandedNotchView.swift`
- Optional delete: `macIsland/Views/Expanded/PomodoroTimerView.swift`
- Optional delete: `macIsland/Views/Collapsed/CollapsedNotchView.swift`
- Optional delete: `macIsland/Views/Collapsed/PomodoroRingIndicator.swift`
- Optional delete: `macIsland/Services/NotificationService.swift`

- [ ] **Step 1: Run the focused unit tests together**

Run:

```bash
xcodebuild test \
  -project macIsland.xcodeproj \
  -scheme macIsland \
  -destination 'platform=macOS' \
  -only-testing:macIslandTests/TaskStoreTests \
  -only-testing:macIslandTests/ExpandedIslandLayoutTests
```

Expected: PASS for all new task-related tests.

- [ ] **Step 2: Run a full build to catch integration issues**

Run:

```bash
xcodebuild build \
  -project macIsland.xcodeproj \
  -scheme macIsland \
  -destination 'platform=macOS'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Remove stale Pomodoro-facing UI files if they are still unused**

Before deleting, verify they are not referenced:

```bash
rg -n "NotchContentView|ExpandedNotchView|CollapsedNotchView|PomodoroTimerView|PomodoroRingIndicator" macIsland
```

If the only hits are the files themselves or comments, delete the stale files listed above and rerun the full build.

- [ ] **Step 4: Perform the final manual UX pass**

Manual checklist:

- The expanded island feels like a native macOS surface rather than a separate popup.
- Segment switching uses the same motion quality as height changes.
- Empty `Music` state still looks clean when nothing is playing.
- Empty `Tasks` state shows only the inline entry field.
- Completed tasks stay visible, strikethrough, and below active ones.
- Right-click menu actions do not steal focus or break hover collapse.

- [ ] **Step 5: Hand off summary and git actions to the user**

Summarize:

- Which files were added
- Which files were modified
- Which stale Pomodoro files were deleted, if any
- Test commands run and their results
- Any known follow-up, especially if `contextMenu` behavior inside the nonactivating panel needs refinement

## Self-Review

### Spec Coverage Check

- Segmented `Music | Tasks` control: covered by Task 3.
- Session-only tab state: covered by Task 4.
- Persistent JSON tasks: covered by Task 1.
- Inline add/edit/delete/complete flow: covered by Tasks 1 and 3.
- Completed tasks sink to the bottom: covered by Task 1 ordering tests and store implementation.
- Dynamic island height growth with capped scrolling: covered by Tasks 2, 3, and 4 manual verification.
- Remove active Pomodoro wiring: covered by Task 4.

### Placeholder Scan

No `TODO`, `TBD`, or “implement later” placeholders remain. The only optional area is stale-file cleanup, which is intentionally deferred until the new hover path is proven unused elsewhere.

### Type Consistency Check

- `TaskItem`, `TaskStore`, `ExpandedTab`, and `ExpandedIslandLayout` are introduced before later tasks reference them.
- `selectedTab` is session-only state on `DynamicNotch`.
- `taskStore.tasks` is the single ordered list consumed by `TasksView`.
