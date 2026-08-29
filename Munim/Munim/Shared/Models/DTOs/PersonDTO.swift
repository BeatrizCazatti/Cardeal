import Foundation

// MARK: - PersonDTO
// Espelha o shape retornado pelo backend (PersonController.swift).
// Nota: POST /api/people aceita teamID e email mas não os persiste (toModel() os ignora).

struct PersonDTO: Identifiable, Codable {
    var id: UUID?
    var name: String
    var jobTitle: String
    var teamID: UUID?
    var active: Bool
    var joinedAt: Date
    var leftAt: Date?
    var email: String?

    init(
        id: UUID? = nil,
        name: String,
        jobTitle: String,
        teamID: UUID? = nil,
        active: Bool,
        joinedAt: Date,
        leftAt: Date? = nil,
        email: String? = nil
    ) {
        self.id = id
        self.name = name
        self.jobTitle = jobTitle
        self.teamID = teamID
        self.active = active
        self.joinedAt = joinedAt
        self.leftAt = leftAt
        self.email = email
    }
}
