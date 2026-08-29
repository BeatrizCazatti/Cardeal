import Foundation

// MARK: - OrganizationService
// Após o login, busca a lista de organizações e seleciona automaticamente
// a primeira organização ativa (por createdAt ASC, igual ao backend).
// O orgID selecionado é injetado no AuthService e no APIClient.

@MainActor
final class OrganizationService {

    static let shared = OrganizationService()
    private init() {}

    // MARK: - Selecionar organização automática pós-login
    // Retorna o orgID escolhido (ou lança erro se não houver orgs).
    func selectDefaultOrganization(authService: AuthService) async throws -> String {
        let orgs: [OrganizationDTO] = try await APIClient.shared.request("/api/organizations")

        guard let activeOrg = orgs.first(where: { $0.isActive }),
              let orgID = activeOrg.id?.uuidString else {
            throw APIError.serverError("Nenhuma organização ativa encontrada.")
        }

        authService.setOrganization(id: orgID)
        return orgID
    }

    // MARK: - Listar todas as organizações
    func fetchOrganizations() async throws -> [OrganizationDTO] {
        try await APIClient.shared.request("/api/organizations")
    }
}
