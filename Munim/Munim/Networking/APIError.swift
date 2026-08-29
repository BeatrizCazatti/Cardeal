import Foundation

// MARK: - APIError
// Erros tipados retornados pela camada de networking.
// O backend Vapor emite sempre { "error": true, "reason": "..." }.

enum APIError: LocalizedError {
    case unauthorized
    case notFound
    case conflict(String)
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Sessão expirada. Faça login novamente."
        case .notFound:
            return "Recurso não encontrado."
        case .conflict(let reason):
            return reason
        case .serverError(let reason):
            return reason
        case .decodingError(let error):
            return "Erro ao processar resposta: \(error.localizedDescription)"
        case .networkError(let error):
            return "Erro de rede: \(error.localizedDescription)"
        case .invalidURL:
            return "URL inválida."
        }
    }
}

// MARK: - VaporErrorBody
// Estrutura de erro padrão do Vapor: { "error": true, "reason": "..." }
struct VaporErrorBody: Decodable {
    let error: Bool
    let reason: String
}
