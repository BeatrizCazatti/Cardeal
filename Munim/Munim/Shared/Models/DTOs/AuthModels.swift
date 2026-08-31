import Foundation

// MARK: - Auth DTOs
// Espelham os shapes definidos no backend (GoogleAuthController.swift).
//
// O backend retorna respostas em camelCase (sem keyEncodingStrategy).
// O APIClient.decoder usa convertFromSnakeCase, que é compatível com camelCase também.

// Resposta de GET /api/auth/google/auth-url e /api/integrations/google/auth-url
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
