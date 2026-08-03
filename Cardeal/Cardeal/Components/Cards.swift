import SwiftUI

struct SectionHeading: View {
    let title: String
    let actionTitle: String
    var body: some View { HStack { Text(title).font(.system(size: 16, weight: .bold)).foregroundStyle(Color.cardealInk); Spacer(); Button(actionTitle) { }.buttonStyle(.plain).font(.system(size: 11, weight: .medium)).foregroundStyle(Color.cardealPurple) } }
}

struct Tag: View {
    let text: String
    let color: Color
    var body: some View { Text(text).font(.system(size: 10, weight: .medium)).foregroundStyle(color).padding(.horizontal, 7).padding(.vertical, 4).background(color.opacity(0.10), in: Capsule()) }
}

struct MetricCard: View {
    let title: String; let value: String; let note: String; let icon: String; let tint: Color
    var body: some View { VStack(alignment: .leading, spacing: 17) { HStack { Image(systemName: icon).foregroundStyle(tint).font(.system(size: 14)); Spacer(); Image(systemName: "arrow.up.right").font(.system(size: 11)).foregroundStyle(Color.cardealMuted) }; Text(value).font(.system(size: 27, weight: .bold)).foregroundStyle(Color.cardealInk); VStack(alignment: .leading, spacing: 3) { Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.cardealInk); Text(note).font(.system(size: 10)).foregroundStyle(Color.cardealMuted) } }.padding(17).frame(maxWidth: .infinity, alignment: .leading).background(.white, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardealLine)) }
}

struct TimelineCard: View {
    let items: [MemoryItem]
    var body: some View { VStack(spacing: 0) { ForEach(Array(items.enumerated()), id: \.element.id) { index, item in TimelineRow(item: item, showsConnector: index < items.count - 1) } }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardealLine)) }
}

private struct TimelineRow: View {
    let item: MemoryItem
    let showsConnector: Bool
    var body: some View { HStack(alignment: .top, spacing: 13) { VStack(spacing: 0) { ZStack { Circle().fill(item.kind.color.opacity(0.14)).frame(width: 31, height: 31); Image(systemName: item.kind.symbol).font(.system(size: 12, weight: .semibold)).foregroundStyle(item.kind.color) }; if showsConnector { Rectangle().fill(Color.cardealLine).frame(width: 1, height: 42) } }; VStack(alignment: .leading, spacing: 5) { HStack { Text(item.title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.cardealInk); Spacer(); Text(item.time).font(.system(size: 10)).foregroundStyle(Color.cardealMuted) }; Text(item.detail).font(.system(size: 11)).foregroundStyle(Color.cardealMuted).lineLimit(2); HStack(spacing: 6) { Tag(text: item.kind.rawValue, color: item.kind.color); Text(item.project).font(.system(size: 10)).foregroundStyle(Color.cardealMuted) } }.padding(.bottom, showsConnector ? 13 : 0) } }
}

struct TaskCard: View {
    let tasks: [OperationalTask]
    let onToggle: (OperationalTask.ID) -> Void
    var body: some View { VStack(spacing: 0) { ForEach(tasks) { task in Button { onToggle(task.id) } label: { HStack(spacing: 10) { Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle").foregroundStyle(task.isDone ? Color.cardealGreen : Color.cardealMuted); VStack(alignment: .leading, spacing: 3) { Text(task.title).font(.system(size: 12, weight: .medium)).strikethrough(task.isDone).foregroundStyle(Color.cardealInk); Text(task.dueDate.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 10)).foregroundStyle(task.status.color) }; Spacer(); Image(systemName: task.symbol).font(.system(size: 11)).foregroundStyle(Color.cardealMuted) }.padding(.vertical, 12) }.buttonStyle(.plain); if task.id != tasks.last?.id { Divider().overlay(Color.cardealLine) } } }.padding(.horizontal, 15).background(.white, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardealLine)) }
}
