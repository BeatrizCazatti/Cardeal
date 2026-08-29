import Foundation

// MARK: - APIClient
// Cliente HTTP centralizado para o backend Vapor 4.
//
// Injeção automática de headers:
//   • Authorization: Bearer <JWT>       (se autenticado)
//   • X-Organization-ID: <UUID>         (se org selecionada)
//   • Content-Type: application/json    (em POST/PUT/PATCH)
//   • Accept: application/json
//
// Suporta múltiplos formatos de data ISO 8601 (com/sem milissegundos).

@MainActor
final class APIClient {

    // MARK: - Singleton
    static let shared = APIClient()
    private init() {}

    // MARK: - Configuração
    private let baseURL: URL = APIConfig.baseURL

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase

        d.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            
            // Tentativa 1: Double (timestamp unix)
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }
            
            let dateStr = try container.decode(String.self)
            
            let iso8601Full = ISO8601DateFormatter()
            iso8601Full.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            if let date = iso8601Full.date(from: dateStr) {
                return date
            }
            
            let iso8601Standard = ISO8601DateFormatter()
            iso8601Standard.formatOptions = [.withInternetDateTime]
            
            if let date = iso8601Standard.date(from: dateStr) {
                return date
            }

            let dateOnly = DateFormatter()
            dateOnly.locale = Locale(identifier: "en_US_POSIX")
            dateOnly.dateFormat = "yyyy-MM-dd"
            
            if let date = dateOnly.date(from: dateStr) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Data inválida: \(dateStr)"
            )
        }

        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    // MARK: - Auth state (injetado pelo AuthService)
    var bearerToken: String?
    var organizationID: String?

    // MARK: - Notificação de 401
    static let unauthorizedNotification = Notification.Name("APIClientUnauthorized")

    // MARK: - Request genérico

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = bearerToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let orgID = organizationID {
            req.setValue(orgID, forHTTPHeaderField: "X-Organization-ID")
        }

        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            DebugLogger.shared.log(
                "Erro de rede em \(method) \(path)",
                level: .error,
                category: "HTTP",
                details: error.localizedDescription
            )
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        let rawBody = String(data: data, encoding: .utf8)

        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoded = try decoder.decode(T.self, from: data)
                DebugLogger.shared.log(
                    "\(method) \(path) → \(httpResponse.statusCode) OK",
                    level: .success,
                    category: "HTTP",
                    details: rawBody
                )
                return decoded
            } catch {
                DebugLogger.shared.log(
                    "Decodificação falhou em \(method) \(path)",
                    level: .error,
                    category: "HTTP",
                    details: "Erro: \(error)\n\nResposta bruta: \(rawBody ?? "")"
                )
                throw APIError.decodingError(error)
            }
        case 401:
            DebugLogger.shared.log(
                "\(method) \(path) → 401 Unauthorized",
                level: .warning,
                category: "HTTP",
                details: rawBody
            )
            NotificationCenter.default.post(name: APIClient.unauthorizedNotification, object: nil)
            throw APIError.unauthorized
        case 404:
            DebugLogger.shared.log(
                "\(method) \(path) → 404 Not Found",
                level: .warning,
                category: "HTTP",
                details: rawBody
            )
            throw APIError.notFound
        case 409:
            let reason = (try? decoder.decode(VaporErrorBody.self, from: data))?.reason ?? "Conflito."
            DebugLogger.shared.log(
                "\(method) \(path) → 409 Conflict: \(reason)",
                level: .error,
                category: "HTTP",
                details: rawBody
            )
            throw APIError.conflict(reason)
        default:
            let reason = (try? decoder.decode(VaporErrorBody.self, from: data))?.reason
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            DebugLogger.shared.log(
                "\(method) \(path) → \(httpResponse.statusCode): \(reason)",
                level: .error,
                category: "HTTP",
                details: rawBody
            )
            throw APIError.serverError(reason)
        }
    }

    // MARK: - Request sem corpo de resposta (ex: DELETE → 204)

    func requestVoid(
        _ path: String,
        method: String = "DELETE",
        body: (any Encodable)? = nil
    ) async throws {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = bearerToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let orgID = organizationID {
            req.setValue(orgID, forHTTPHeaderField: "X-Organization-ID")
        }

        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            NotificationCenter.default.post(name: APIClient.unauthorizedNotification, object: nil)
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            let reason = (try? decoder.decode(VaporErrorBody.self, from: data))?.reason
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw APIError.serverError(reason)
        }
    }
}
