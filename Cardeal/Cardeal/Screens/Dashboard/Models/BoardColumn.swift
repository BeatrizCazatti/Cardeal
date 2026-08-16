import SwiftUI

/// Uma coluna do board (ex.: "Atendimento", "Design"...).
struct BoardColumn: Identifiable, Hashable {
    let id: UUID
    let title: String
    var items: [BoardItem]

    init(id: UUID = UUID(), title: String, items: [BoardItem]) {
        self.id = id
        self.title = title
        self.items = items
    }

    func filtered(by category: DashboardItemCategory?) -> BoardColumn {
        guard let category else { return self }

        return BoardColumn(
            id: id,
            title: title,
            items: items.filter { $0.category == category }
        )
    }

    @discardableResult
    mutating func markAsReviewed(itemID: BoardItem.ID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == itemID }),
              items[index].badgeCount != nil else { return false }
        items[index].markAsReviewed()
        return true
    }

    mutating func update(itemID: BoardItem.ID, with draft: BoardItemDraft) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[index].apply(draft)
    }

    mutating func remove(itemID: BoardItem.ID) -> (item: BoardItem, index: Int)? {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return nil }
        return (items.remove(at: index), index)
    }

    mutating func restore(_ item: BoardItem, at index: Int) {
        items.insert(item, at: min(index, items.count))
    }

    func unreadItemCount(for category: DashboardItemCategory?) -> Int {
        items.filter { item in
            item.badgeCount != nil && (category == nil || item.category == category)
        }.count
    }
}

/// Um card individual dentro de uma coluna do board.
struct BoardItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    /// Número exibido no badge circular no canto superior do card (opcional).
    var badgeCount: Int?
    var assignees: [Assignee]
    /// Texto livre de data (ex.: "Amanhã - 17h").
    var dateText: String?
    /// Se `true`, destaca a data como "Nova data" (ex.: reagendamento).
    let isRescheduled: Bool
    var location: String?
    /// Usado por cards de "decisão", que mostram um parágrafo em vez de metadados.
    var descriptionText: String?
    let category: DashboardItemCategory

    init(
        title: String,
        badgeCount: Int? = nil,
        assignees: [Assignee] = [],
        dateText: String? = nil,
        isRescheduled: Bool = false,
        location: String? = nil,
        descriptionText: String? = nil,
        category: DashboardItemCategory
    ) {
        self.title = title
        self.badgeCount = badgeCount
        self.assignees = assignees
        self.dateText = dateText
        self.isRescheduled = isRescheduled
        self.location = location
        self.descriptionText = descriptionText
        self.category = category
    }

    init(draft: BoardItemDraft, category: DashboardItemCategory) {
        self.init(
            title: draft.title,
            assignees: draft.assignees,
            dateText: draft.dateText.emptyAsNil,
            location: draft.location.emptyAsNil,
            descriptionText: draft.description.emptyAsNil,
            category: category
        )
    }

    mutating func markAsReviewed() {
        badgeCount = nil
    }

    mutating func apply(_ draft: BoardItemDraft) {
        title = draft.title
        descriptionText = draft.description.emptyAsNil
        assignees = draft.assignees
        dateText = draft.dateText.emptyAsNil
        location = draft.location.emptyAsNil
    }
}

struct BoardItemDraft {
    var title: String
    var description: String
    var assignees: [Assignee]
    var dateText: String
    var location: String

    init() {
        title = ""
        description = ""
        assignees = []
        dateText = ""
        location = ""
    }

    init(item: BoardItem) {
        title = item.title
        description = item.descriptionText ?? ""
        assignees = item.assignees
        dateText = item.dateText ?? ""
        location = item.location ?? ""
    }
}

private extension String {
    var emptyAsNil: String? {
        isEmpty ? nil : self
    }
}
