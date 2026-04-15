# Daily Tasks For macIsland — Design Document

## Overview

Add a minimalist `Tasks` experience to the expanded dynamic island using a native-feeling segmented tab control:

- `Music` is the default tab.
- `Tasks` is the secondary tab.
- The selected tab persists for the current app session only.
- Tasks persist across app restarts until they are manually deleted or cleared.

This feature replaces the old expanded Pomodoro UI. The Pomodoro backend may remain in the codebase for now, but it is out of scope for the visible island interface.

## Goals

- Add a compact, hover-only daily task list to the full-sized expanded island.
- Keep the interaction lightweight and native to macOS and iOS patterns.
- Make task capture fast with inline entry.
- Keep completion reversible and distinct from deletion.
- Avoid introducing unnecessary complexity such as priorities, filters, or multi-surface editing flows.

## Non-Goals

- No priority system in v1.
- No drag-and-drop or manual reordering in v1.
- No due dates, tags, reminders, or grouping.
- No cross-device sync or cloud storage.
- No persistence of the selected tab across app relaunches.

## User Experience

### Expanded Island Layout

The expanded island becomes a single-content surface with a centered segmented control near the top:

- `Music`
- `Tasks`

Only one content panel is visible at a time.

- `Music` shows the current now-playing panel.
- `Tasks` shows the inline input and task list.
- The expanded island grows and shrinks smoothly as the visible task list changes, up to a capped maximum height.
- Once the tasks content exceeds that maximum height, the task list scrolls inside the expanded island rather than continuing to stretch the island downward.

The collapsed island stays unchanged in this feature.

### Tab Behavior

- On app launch, the expanded island defaults to `Music`.
- If the user switches to `Tasks`, that selection remains active until the app quits or relaunches.
- Switching between `Music` and `Tasks` uses a subtle horizontal slide with a small fade so the interaction feels like navigating between pages in one surface.
- Height changes caused by task add, delete, complete, edit, or tab switches animate smoothly in a macOS-style motion curve rather than snapping.
- The segmented control label uses `Music` rather than `Now Playing` to keep the control compact.

### Tasks Experience

The `Tasks` tab is intentionally sparse:

- A single inline input row appears at the top with placeholder copy such as `Add a task for today`.
- Submitting creates a new task immediately below the input.
- Active tasks appear first.
- Completed tasks remain visible in the same list with strikethrough styling and lower emphasis.
- Completed tasks automatically move to the bottom of the list.

### Per-Task Actions

Right-clicking a task row opens a context menu:

- `Complete` or `Mark Incomplete`
- `Edit`
- `Delete`

`Edit` converts the row into an inline editing state with confirm/cancel behavior. No separate sheet or popover is used in v1.

### Empty States

- `Music` remains the default tab even when no media is currently playing.
- If no media is active, `Music` shows the existing empty state behavior for now-playing.
- If there are no tasks, the `Tasks` tab shows only the input row and an otherwise empty list.

## Data Model

Add a small task model with only the fields needed for v1:

- `id`
- `title`
- `isCompleted`
- `createdAt`
- `completedAt` optional
- `updatedAt` optional

This model should be `Codable` so it can be stored directly as JSON.

## Ordering Rules

List order is derived rather than manually managed:

1. Incomplete tasks sort above completed tasks.
2. Within the incomplete group, tasks preserve creation order.
3. Within the completed group, tasks preserve completion order by using `completedAt`, with older completed tasks above newer ones.
4. If a completed task is marked incomplete, it returns to the active group.

This keeps the list stable while still making completion visually meaningful.

## State And Persistence

### Task Persistence

Use a lightweight local JSON file for persistence.

Responsibilities:

- Load tasks when the app starts.
- Keep tasks in memory for rendering.
- Save immediately after add, edit, complete/incomplete, or delete operations.

Preferred storage location:

- The app support directory or another app-owned local file path suitable for persistent user data on macOS.

If the JSON file does not exist, the app starts with an empty task list.

### Session State

The selected expanded tab is session-only state:

- Not written to disk.
- Reset to `Music` on next launch.

## Architecture

### UI Components

- `ExpandedIslandView`
  - Becomes the shell for the segmented control and active tab content.
- `ExpandedTab`
  - Small enum with `music` and `tasks`.
- `MusicTabView`
  - Either wraps the current media panel or reuses the existing `MediaPlayerView`.
- `TasksView`
  - Owns the inline input row and the rendered task list.
- `TaskRowView`
  - Renders one task row, completion styling, editing state, and context menu.

### Data Components

- `TaskItem`
  - Shared model for one task.
- `TaskStore` or `TasksService`
  - Observable object that loads, saves, and mutates tasks.

### Existing Code Cleanup Included In Scope

The expanded island UI should stop depending on the Pomodoro panel:

- Remove Pomodoro from the expanded visible layout.
- Remove Pomodoro plumbing from the notch content path where it is no longer needed for rendering this feature.
- Keep any untouched backend timer code only if it does not complicate the new UI flow.

## Interaction Notes And Best Practices

This design follows compact-task-list conventions used by Notes, Notion, Obsidian, and similar apps:

- Make capture frictionless with one obvious input.
- Treat completion as a reversible state change.
- Keep destructive actions secondary and tucked into contextual affordances.
- De-emphasize completed items rather than hiding them immediately.
- Avoid metadata-heavy rows in tight layouts.

For this notch-sized surface, a single focused list is preferable to filters, badges, or property-rich tasks.

## Error Handling

- If task loading fails because the file is missing, initialize an empty list.
- If task loading fails because the file is corrupted or unreadable, log the failure and fall back to an empty list instead of crashing the app.
- If saving fails, log the failure and keep the current in-memory state so the interface remains usable for the session.
- Invalid or empty task submissions should be ignored after trimming whitespace.

## Testing Strategy

### Unit Tests

- Task creation
- Task editing
- Task deletion
- Toggle complete/incomplete
- Ordering rules: incomplete above completed
- Ordering rules: stable ordering inside each group
- JSON persistence round-trip

### Manual Verification

- Expanded island defaults to `Music`
- Switching tabs animates and updates session state correctly
- New tasks appear immediately
- Completed tasks move to the bottom with strikethrough styling
- Right-click context menu exposes `Complete`, `Edit`, and `Delete`
- Inline edit mode updates the row correctly
- Expanded island height grows and shrinks smoothly as task count changes
- Long task lists stay capped and scroll internally without breaking hover behavior
- Tasks persist across app relaunches

## Implementation Scope

This design is intentionally small enough for a single implementation pass:

- Replace the expanded two-pane `music + pomodoro` layout with a single-pane `Music | Tasks` shell
- Add a persistent local task store
- Add inline task creation
- Add inline editing
- Add contextual task actions
- Remove visible Pomodoro UI from the expanded island

## Open Decisions Resolved

- Tab control style: segmented pill
- Left tab label: `Music`
- Default expanded tab: `Music`
- Tab persistence: current app session only
- Task persistence: until manual deletion or clearing
- Task input: inline at top of tasks tab
- Completion display: inline with strikethrough, moved to bottom
- Deletion/edit actions: right-click context menu
- Prioritization: out of scope for v1
