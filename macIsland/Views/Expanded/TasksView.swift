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
                            onToggle: {
                                if editingTaskID == task.id {
                                    editingTaskID = nil
                                }
                                taskStore.toggleCompletion(id: task.id)
                            },
                            onBeginEdit: {
                                editingTaskID = task.id
                                editingDraft = task.title
                            },
                            onCommitEdit: {
                                taskStore.editTask(id: task.id, title: editingDraft)
                                editingTaskID = nil
                            },
                            onCancelEdit: {
                                editingTaskID = nil
                                editingDraft = ""
                            },
                            onDelete: {
                                if editingTaskID == task.id {
                                    editingTaskID = nil
                                }
                                taskStore.deleteTask(id: task.id)
                            }
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
