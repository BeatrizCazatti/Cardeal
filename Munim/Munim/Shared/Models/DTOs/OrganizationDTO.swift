import Foundation

// MARK: - OrganizationDTO
// Espelha GET/POST /api/organizations (OrganizationController.swift).
// Este controller não usa req.scoped — opera globalmente.

struct OrganizationDTO: Identifiable, Codable {
    var id: UUID?
    var name: String
    var slug: String?
    var logoUrl: String?
    var isActive: Bool
    var createdAt: Date?
}
