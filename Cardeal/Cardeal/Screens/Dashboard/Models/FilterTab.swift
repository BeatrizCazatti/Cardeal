
import SwiftUI

/// Tipos de conteúdo que podem ser exibidos em cada time do dashboard.
enum DashboardItemCategory: String, CaseIterable, Hashable {
    case meeting
    case task
    case change
    case decision

    var title: String {
        switch self {
        case .meeting: "Reunião"
        case .task: "Tarefa"
        case .change: "Mudança"
        case .decision: "Decisão"
        }
    }
}

/// Uma aba de filtro no topo (ex.: "Geral", "Reuniões"...), com contador.
struct FilterTab: Identifiable, Hashable {
    let id = UUID()
    let title: String
    var count: Int
    /// `nil` representa a aba Geral, que exibe todos os itens.
    let category: DashboardItemCategory?

    init(title: String, count: Int, category: DashboardItemCategory? = nil) {
        self.title = title
        self.count = count
        self.category = category
    }

    static func == (lhs: FilterTab, rhs: FilterTab) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
