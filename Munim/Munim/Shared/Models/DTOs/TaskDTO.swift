import Foundation

// MARK: - TaskDTO
// Espelha GET/POST /api/tasks (TaskController.swift).
// PATCH /api/tasks/:id/status aceita status: "Todo" | "Doing" | "Blocked" | "Done"

struct TaskDTO: Identifiable, Codable {
    var id: UUID?
    var title: String
    var description: String
    var owner: UUID?
    var deadline: Date?
    var priority: String
    var status: String
    var relatedProject: UUID?
    var team: UUID?
    var modality: String?
    var origin: String?
    var confidence: Double
}

// MARK: - TaskStatus
enum TaskStatus: String, CaseIterable, Identifiable {
    case todo = "Todo"
    case doing = "Doing"
    case blocked = "Blocked"
    case done = "Done"

    var id: String { rawValue }

    var displayName: String { rawValue }
}

// MARK: - TaskStatusUpdateRequest
struct TaskStatusUpdateRequest: Encodable {
    let status: String
}
