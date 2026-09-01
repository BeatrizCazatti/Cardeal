import SwiftUI
import Combine

/// Armazena e gerencia o histórico de pesquisas recentes do usuário.
/// Usa UserDefaults diretamente para persistência confiável entre sessões.
final class RecentSearchesStore: ObservableObject {
    static let shared = RecentSearchesStore()

    private let storageKey = "munim.recentSearches"
    private let defaults = UserDefaults.standard

    @Published private(set) var recentSearches: [String] = []

    private let maxRecentSearches = 10

    private init() {
        loadRecentSearches()
    }

    /// Carrega as pesquisas recentes do armazenamento persistente
    private func loadRecentSearches() {
        if let array = defaults.stringArray(forKey: storageKey) {
            recentSearches = array
        } else if let data = defaults.data(forKey: storageKey),
                  let searches = try? JSONDecoder().decode([String].self, from: data) {
            recentSearches = searches
        } else {
            recentSearches = []
        }
    }

    /// Salva as pesquisas recentes no armazenamento persistente
    private func saveRecentSearches() {
        defaults.set(recentSearches, forKey: storageKey)
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
        guard !trimmedQuery.isEmpty else { return recentSearches }

        return recentSearches.filter { search in
            search.lowercased().contains(trimmedQuery)
        }
    }
}