import Foundation

// MARK: - Auth DTOs
// Espelham os shapes definidos no backend (GoogleAuthController.swift).

// Resposta de GET /api/auth/google/auth-url
struct GoogleAuthURLDTO: Decodable {
    let authorizeURL: String
}

// Resposta de GET /api/auth/google/callback (sem ?redirect)
struct AuthTokenResponseDTO: Decodable {
    let token: String
    let tokenType: String
    let expiresAt: Date
    let person: PersonDTO
}
