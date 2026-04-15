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
                    .foregroundStyle(task.isCompleted ? .white.opacity(0.7) : .white.opacity(0.5))
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
        .padding(.horizontal, 12)
        .frame(height: ExpandedIslandLayout.taskRowHeight)
        .background(.white.opacity(task.isCompleted ? 0.05 : 0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .contextMenu {
            Button(task.isCompleted ? "Mark Incomplete" : "Complete", action: onToggle)
            Button("Edit", action: onBeginEdit)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
