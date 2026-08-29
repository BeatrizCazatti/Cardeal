import Foundation

// MARK: - MeetingDTO
// Espelha GET/POST /api/meetings (MeetingController.swift).
// Nota: participants é aceito mas não persistido no create (toModel() ignora).

struct MeetingDTO: Identifiable, Codable {
    var id: UUID?
    var title: String
    var date: Date
    var time: String
    var location: String?
    var meetingLink: String?
    var meetingType: String
    var participants: [UUID]
    var agenda: String?
    var confidence: Double
}
