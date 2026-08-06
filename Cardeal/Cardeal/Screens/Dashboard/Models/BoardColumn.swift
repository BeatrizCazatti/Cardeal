import SwiftUI

/// Uma coluna do board (ex.: "Atendimento", "Design"...).
struct BoardColumn: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let items: [BoardItem]
}

/// Um card individual dentro de uma coluna do board.
struct BoardItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    /// Número exibido no badge circular no canto superior do card (opcional).
    let badgeCount: Int?
    let assignees: [Assignee]
    /// Texto livre de data (ex.: "Amanhã - 17h").
    let dateText: String?
    /// Se `true`, destaca a data como "Nova data" (ex.: reagendamento).
    let isRescheduled: Bool
    let location: String?
    /// Usado por cards de "decisão", que mostram um parágrafo em vez de metadados.
    let descriptionText: String?

    init(
        title: String,
        badgeCount: Int? = nil,
        assignees: [Assignee] = [],
        dateText: String? = nil,
        isRescheduled: Bool = false,
        location: String? = nil,
        descriptionText: String? = nil
    ) {
        self.title = title
        self.badgeCount = badgeCount
        self.assignees = assignees
        self.dateText = dateText
        self.isRescheduled = isRescheduled
        self.location = location
        self.descriptionText = descriptionText
    }
}
