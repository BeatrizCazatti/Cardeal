import Foundation

// MARK: - Auth DTOs
// Espelham os shapes definidos no backend (GoogleAuthController.swift).

// Resposta de GET /api/auth/google/auth-url e /api/integrations/google/auth-url
// O backend retorna "authorize_url" (snake_case). CodingKeys explícito garante
// compatibilidade independente da keyDecodingStrategy do decoder.
struct GoogleAuthURLDTO: Decodable {
    let authorizeURL: String

    enum CodingKeys: String, CodingKey {
        case authorizeURL = "authorize_url"
    }
}

// Resposta de GET /api/auth/google/callback (sem ?redirect)
struct AuthTokenResponseDTO: Decodable {
    let token: String
    let tokenType: String
    let expiresAt: Date
    let person: PersonDTO

    enum CodingKeys: String, CodingKey {
        case token
        case tokenType = "token_type"
        case expiresAt = "expires_at"
        case person
    }
}
