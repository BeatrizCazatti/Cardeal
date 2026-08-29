import Foundation

// MARK: - TeamDTO
// Espelha GET/POST /api/teams (TeamController.swift).
// Nota: lead e relatedProject são aceitos mas não persistidos no create.

struct TeamDTO: Identifiable, Codable {
    var id: UUID?
    var name: String
    var lead: UUID?
    var relatedProject: UUID?
}
