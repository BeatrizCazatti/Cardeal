import SwiftUI
import Combine

/// Armazena e gerencia o histórico de pesquisas recentes do usuário.
/// Usa @AppStorage para persistência automática entre lançamentos do app.
final class RecentSearchesStore: ObservableObject {
    static let shared = RecentSearchesStore()

    @AppStorage("recentSearches") private var storedSearchesData: Data = Data()

    @Published private(set) var recentSearches: [String] = []

    private let maxRecentSearches = 10

    private init() {
        loadRecentSearches()
    }

    /// Carrega as pesquisas recentes do armazenamento persistente
    private func loadRecentSearches() {
        guard !storedSearchesData.isEmpty,
              let searches = try? JSONDecoder().decode([String].self, from: storedSearchesData) else {
            recentSearches = []
            return
        }
        recentSearches = searches
    }

    /// Salva as pesquisas recentes no armazenamento persistente
    private func saveRecentSearches() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            storedSearchesData = data
        }
    }

    /// Adiciona uma nova pesquisa ao histórico (remove duplicatas e mantém ordem de mais recente)
    func addSearch(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        // Remove se já existir (para mover para o topo)
        recentSearches.removeAll { $0.caseInsensitiveCompare(trimmedQuery) == .orderedSame }

        // Adiciona no início
        recentSearches.insert(trimmedQuery, at: 0)

        // Limita ao máximo configurado
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }

        saveRecentSearches()
    }

    /// Remove uma pesquisa específica do histórico
    func removeSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        saveRecentSearches()
    }

    /// Limpa todo o histórico de pesquisas
    func clearAllSearches() {
        recentSearches.removeAll()
        saveRecentSearches()
    }

    /// Retorna sugestões filtradas baseadas no texto digitado
    func filteredSuggestions(for query: String) -> [String] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedQuery.isEmpty else { return [] }

        return recentSearches.filter { search in
            search.lowercased().contains(trimmedQuery)
        }
    }
}