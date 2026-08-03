import Combine
import Foundation
import UserNotifications

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published private(set) var timelineItems: [MemoryItem]
    @Published var tasks: [OperationalTask]
    @Published private(set) var projects: [Project] = []
    @Published private(set) var documents: [DocumentRecord] = []
    @Published private(set) var isDemoMode = false

    private let storageKey = "cardeal.workspace.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        if let snapshot = Self.loadSnapshot(using: JSONDecoder()) {
            timelineItems = snapshot.items
            tasks = snapshot.tasks
        } else {
            timelineItems = []
            tasks = []
        }
    }

    func add(_ item: MemoryItem) {
        timelineItems.insert(item, at: 0)
        persist()
    }

    func toggleCompletion(for taskID: OperationalTask.ID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].isDone.toggle()
        persist()
    }

    func scheduleTask(title: String, dueDate: Date) {
        let task = OperationalTask(title: title, dueDate: dueDate, owner: "Você", status: .scheduled, symbol: "bell.badge")
        tasks.insert(task, at: 0)
        persist()
        ReminderScheduler.schedule(title: title, date: dueDate)
    }

    func searchMemories(matching query: String) -> [MemoryItem] {
        guard !query.isEmpty else { return timelineItems }
        return timelineItems.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.detail.localizedCaseInsensitiveContains(query) ||
            $0.project.localizedCaseInsensitiveContains(query)
        }
    }

    func loadDemoData() {
        timelineItems = MemoryItem.samples
        tasks = OperationalTask.samples
        projects = Project.samples
        documents = DocumentRecord.samples
        isDemoMode = true
        persist()
    }

    func clearDemoData() {
        timelineItems = []
        tasks = []
        projects = []
        documents = []
        isDemoMode = false
        persist()
    }

    private func persist() {
        let snapshot = WorkspaceSnapshot(items: timelineItems, tasks: tasks)
        guard let data = try? encoder.encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private static func loadSnapshot(using decoder: JSONDecoder) -> WorkspaceSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: "cardeal.workspace.v1") else { return nil }
        return try? decoder.decode(WorkspaceSnapshot.self, from: data)
    }
}

private struct WorkspaceSnapshot: Codable {
    let items: [MemoryItem]
    let tasks: [OperationalTask]
}

private enum ReminderScheduler {
    static func schedule(title: String, date: Date) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Cardeal: ação agendada"
            content.body = title
            content.sound = .default
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
        }
    }
}
