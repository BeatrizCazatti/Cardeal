
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

enum DashboardTabDestination: Hashable {
    case active(DashboardItemCategory?)
    case archived
    case deleted
}

/// Uma aba de filtro no topo (ex.: "Geral", "Reuniões"...), com contador.
struct FilterTab: Identifiable, Hashable {
    let id = UUID()
    let title: String
    var count: Int
    let destination: DashboardTabDestination

    var category: DashboardItemCategory? {
        guard case let .active(category) = destination else { return nil }
        return category
    }

    init(title: String, count: Int, destination: DashboardTabDestination = .active(nil)) {
        self.title = title
        self.count = count
        self.destination = destination
    }

    static func == (lhs: FilterTab, rhs: FilterTab) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
