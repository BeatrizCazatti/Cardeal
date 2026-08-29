import Foundation

// MARK: - IntegrationDTO
// Espelha GET /api/integrations e GET /api/integrations/google/status

struct IntegrationDTO: Identifiable, Codable {
    var id: UUID
    var provider: String
    var name: String?
    var authType: String
    var scopes: [String]
    var services: [String]
    var isEnabled: Bool
    var oauthConnected: Bool
    var oauthAdminEmail: String?
    var syncIntervalMinutes: Int
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - GoogleWorkspaceStatusDTO
// Resposta de GET /api/integrations/google/status

struct GoogleWorkspaceStatusDTO: Decodable {
    let connected: Bool
    let adminEmail: String?
    let connectedAt: Date?
    let serviceAccountConfigured: Bool
}

// MARK: - DirectorySyncResultDTO
// Resposta de POST /api/integrations/directory/sync

struct DirectorySyncResultDTO: Decodable {
    let usersSynced: Int
    let groupsSynced: Int
    let membershipsLinked: Int
}

// MARK: - GmailSyncResultDTO
struct GmailSyncResultDTO: Decodable {
    let usersProcessed: Int
    let messagesSynced: Int
}

// MARK: - CalendarSyncResultDTO
struct CalendarSyncResultDTO: Decodable {
    let usersProcessed: Int
    let meetingsSynced: Int
    let participantsLinked: Int
}

// MARK: - DriveSyncResultDTO
struct DriveSyncResultDTO: Decodable {
    let usersProcessed: Int
    let documentsSynced: Int
}

// MARK: - GoogleChatSyncResultDTO
struct GoogleChatSyncResultDTO: Decodable {
    let spacesSynced: Int
    let messagesSynced: Int
}

