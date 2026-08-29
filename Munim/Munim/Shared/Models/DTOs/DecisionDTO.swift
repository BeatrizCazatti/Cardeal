import Foundation

// MARK: - DecisionDTO
// Espelha GET/POST /api/decisions (DecisionController.swift).
// Nota: people, relatedProject, attachments aceitos mas não persistidos no create.

struct DecisionDTO: Identifiable, Codable {
    var id: UUID?
    var summary: String
    var rationale: String
    var date: Date
    var people: [UUID]
    var relatedProject: UUID?
    var attachments: [UUID]
    var confidence: Double
}
