//
//  Dashboard.swift
//  Dashboard semanal — layout tipo Kanban com sidebar recolhível
//
//  Segue as diretrizes da Apple Human Interface Guidelines (HIG) para macOS,
//  incluindo o material "Liquid Glass" introduzido nas atualizações recentes
//  de macOS/visionOS/iOS. Componentizado em Views pequenas e reutilizáveis.
//
//  Requer macOS 26 (Tahoe) ou posterior para as APIs `glassEffect` /
//  `GlassEffectContainer`. Em versões anteriores, os fallbacks usam
//  `.ultraThinMaterial`.
//

import SwiftUI
import Combine

// MARK: - View principal

struct DashboardView: View {
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var selectedDestination: SidebarDestination? = .dashboard
    @State private var selectedTab: FilterTab = MockData.filterTabs.first!
    @StateObject private var badgeStore = DashboardBadgeStore()
    @State private var columns = MockData.columns
    @State private var archivedItems: [StoredBoardItem] = []
    @State private var deletedItems: [StoredBoardItem] = []
    @State private var archivedItem: StoredBoardItem?
    @State private var isArchiveUndoPresented = false
    @State private var searchText: String = ""
    @State private var selectedWeek = WeekRange(start: Date())
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selectedDestination)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 260)
        } detail: {
            SidebarDetailView(
                selection: selectedDestination,
                searchText: $searchText,
                selectedWeek: $selectedWeek,
                selectedTab: $selectedTab,
                badgeStore: badgeStore,
                columns: columns,
                archivedItems: archivedItems,
                deletedItems: deletedItems,
                markAsReviewed: markAsReviewed,
                updateItem: updateItem,
                archiveItem: archiveItem,
                deleteItem: deleteItem,
                unarchiveItem: unarchiveItem,
                restoreDeletedItem: restoreDeletedItem,
                createItem: createItem
            )
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            purgeExpiredDeletedItems()
            refreshBadgeStore()
        }
        .alert("Card arquivado", isPresented: $isArchiveUndoPresented) {
            Button("Desfazer") {
                restoreArchivedItem()
            }
            Button("OK", role: .cancel) {
                archivedItem = nil
            }
        } message: {
            Text("O card foi removido do board.")
        }
    }

    private func markAsReviewed(itemID: BoardItem.ID, in columnID: BoardColumn.ID) {
        guard let columnIndex = columns.firstIndex(where: { $0.id == columnID }) else { return }

        var updatedColumn = columns[columnIndex]
        guard updatedColumn.markAsReviewed(itemID: itemID) else { return }
        columns[columnIndex] = updatedColumn
        refreshBadgeStore()
    }

    private func updateItem(itemID: BoardItem.ID, in columnID: BoardColumn.ID, with draft: BoardItemDraft) {
        guard let columnIndex = columns.firstIndex(where: { $0.id == columnID }) else { return }
        columns[columnIndex].update(itemID: itemID, with: draft)
        refreshBadgeStore()
    }

    private func archiveItem(itemID: BoardItem.ID, in columnID: BoardColumn.ID) {
        guard let columnIndex = columns.firstIndex(where: { $0.id == columnID }),
              let removedItem = columns[columnIndex].remove(itemID: itemID) else { return }

        archivedItem = StoredBoardItem(columnID: columnID, teamName: columns[columnIndex].title, item: removedItem.item, index: removedItem.index, storedAt: Date())
        archivedItems.append(archivedItem!)
        refreshBadgeStore()
        isArchiveUndoPresented = true
    }

    private func deleteItem(itemID: BoardItem.ID, in columnID: BoardColumn.ID) {
        guard let columnIndex = columns.firstIndex(where: { $0.id == columnID }),
              let removedItem = columns[columnIndex].remove(itemID: itemID) else { return }
        deletedItems.append(StoredBoardItem(columnID: columnID, teamName: columns[columnIndex].title, item: removedItem.item, index: removedItem.index, storedAt: Date()))
        purgeExpiredDeletedItems()
        refreshBadgeStore()
    }

    private func createItem(draft: BoardItemDraft, in team: String, category: DashboardItemCategory) {
        guard let columnIndex = columns.firstIndex(where: { $0.title == team }) else { return }
        columns[columnIndex].items.append(BoardItem(draft: draft, category: category))
        refreshBadgeStore()
    }

    private func restoreArchivedItem() {
        guard let archivedItem else { return }
        unarchiveItem(archivedItem)
    }

    private func unarchiveItem(_ storedItem: StoredBoardItem) {
        guard restoreToBoard(storedItem) else { return }
        archivedItems.removeAll { $0.id == storedItem.id }
        if archivedItem?.id == storedItem.id {
            archivedItem = nil
        }
        refreshBadgeStore()
    }

    private func restoreDeletedItem(_ storedItem: StoredBoardItem) {
        guard restoreToBoard(storedItem) else { return }
        deletedItems.removeAll { $0.id == storedItem.id }
        refreshBadgeStore()
    }

    private func restoreToBoard(_ storedItem: StoredBoardItem) -> Bool {
        guard let columnIndex = columns.firstIndex(where: { $0.id == storedItem.columnID }) else {
            return false
        }

        columns[columnIndex].restore(storedItem.item, at: storedItem.index)
        return true
    }

    private func refreshBadgeStore() {
        badgeStore.refresh(
            columns: columns,
            archivedItems: archivedItems,
            deletedItems: deletedItems
        )
    }

    private func purgeExpiredDeletedItems() {
        let expirationDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        deletedItems.removeAll { $0.storedAt < expirationDate }
    }
}

/// Fonte observável dos badges das abas. A notificação explícita evita que
/// mudanças internas em um item de `columns` fiquem invisíveis para o SwiftUI.
final class DashboardBadgeStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    @Published private(set) var tabs = MockData.filterTabs

    func refresh(
        columns: [BoardColumn],
        archivedItems: [StoredBoardItem],
        deletedItems: [StoredBoardItem]
    ) {
        let updatedTabs = MockData.filterTabs.map { tab in
            var updatedTab = tab
            switch tab.destination {
            case let .active(category):
                updatedTab.count = columns.reduce(0) { $0 + $1.unreadItemCount(for: category) }
            case .archived:
                updatedTab.count = archivedItems.count
            case .deleted:
                updatedTab.count = deletedItems.count
            }
            return updatedTab
        }

        tabs = updatedTabs
    }
}

struct StoredBoardItem: Identifiable {
    let columnID: BoardColumn.ID
    let teamName: String
    let item: BoardItem
    let index: Int
    let storedAt: Date

    var id: BoardItem.ID { item.id }
}

// MARK: - Destino da navegação

private struct SidebarDetailView: View {
    let selection: SidebarDestination?
    @Binding var searchText: String
    @Binding var selectedWeek: WeekRange
    @Binding var selectedTab: FilterTab
    let badgeStore: DashboardBadgeStore
    let columns: [BoardColumn]
    let archivedItems: [StoredBoardItem]
    let deletedItems: [StoredBoardItem]
    let markAsReviewed: (BoardItem.ID, BoardColumn.ID) -> Void
    let updateItem: (BoardItem.ID, BoardColumn.ID, BoardItemDraft) -> Void
    let archiveItem: (BoardItem.ID, BoardColumn.ID) -> Void
    let deleteItem: (BoardItem.ID, BoardColumn.ID) -> Void
    let unarchiveItem: (StoredBoardItem) -> Void
    let restoreDeletedItem: (StoredBoardItem) -> Void
    let createItem: (BoardItemDraft, String, DashboardItemCategory) -> Void

    @ViewBuilder
    var body: some View {
        switch selection {
        case .dashboard:
            DashboardContentView(
                searchText: $searchText,
                selectedWeek: $selectedWeek,
                selectedTab: $selectedTab,
                badgeStore: badgeStore,
                columns: columns,
                archivedItems: archivedItems,
                deletedItems: deletedItems,
                markAsReviewed: markAsReviewed,
                updateItem: updateItem,
                archiveItem: archiveItem,
                deleteItem: deleteItem,
                unarchiveItem: unarchiveItem,
                restoreDeletedItem: restoreDeletedItem,
                createItem: createItem
            )
        case .attachments:
            AttachmentsView()
        case nil:
            ContentUnavailableView(
                "Selecione uma opção",
                systemImage: "sidebar.left"
            )
        }
    }
}

// MARK: - Conteúdo principal do dashboard

struct DashboardContentView: View {
    @Binding var searchText: String
    @Binding var selectedWeek: WeekRange
    @Binding var selectedTab: FilterTab
    @ObservedObject var badgeStore: DashboardBadgeStore
    let columns: [BoardColumn]
    let archivedItems: [StoredBoardItem]
    let deletedItems: [StoredBoardItem]
    let markAsReviewed: (BoardItem.ID, BoardColumn.ID) -> Void
    let updateItem: (BoardItem.ID, BoardColumn.ID, BoardItemDraft) -> Void
    let archiveItem: (BoardItem.ID, BoardColumn.ID) -> Void
    let deleteItem: (BoardItem.ID, BoardColumn.ID) -> Void
    let unarchiveItem: (StoredBoardItem) -> Void
    let restoreDeletedItem: (StoredBoardItem) -> Void
    let createItem: (BoardItemDraft, String, DashboardItemCategory) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                GreetingHeaderView(name: "Fabíola")

                WeekNavigatorView(selection: $selectedWeek)

                HStack(alignment: .center, spacing: 16) {
                    FilterTabsView(badgeStore: badgeStore, selection: $selectedTab)
                    Spacer()
                    ToolbarActionsView(teamNames: columns.map(\.title), createItem: createItem)
                }

                dashboardBoard

                FooterView(lastUpdated: "29 de julho, 14:30h")
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Color.Token.backgroundPrimary)
        .searchable(
            text: $searchText,
            placement: .toolbar,
            prompt: "Buscar cards, pessoas e locais"
        )
        .navigationTitle("")
    }

    @ViewBuilder
    private var dashboardBoard: some View {
        switch selectedTab.destination {
        case let .active(category):
            BoardView(
                columns: columns,
                filter: category,
                searchText: searchText,
                markAsReviewed: markAsReviewed,
                updateItem: updateItem,
                archiveItem: archiveItem,
                deleteItem: deleteItem
            )
        case .archived:
            StoredItemsBoardView(
                items: archivedItems.filter { $0.item.matches(searchQuery: searchText) },
                title: "Arquivado em",
                actionTitle: "Desarquivar",
                actionSystemImage: "tray.and.arrow.up",
                action: unarchiveItem
            )
        case .deleted:
            StoredItemsBoardView(
                items: deletedItems.filter { $0.item.matches(searchQuery: searchText) },
                title: "Excluído em",
                actionTitle: "Restaurar",
                actionSystemImage: "arrow.uturn.backward",
                action: restoreDeletedItem
            )
        }
    }

}

// MARK: - Cabeçalho de saudação

struct GreetingHeaderView: View {
    let name: String

    var body: some View {
        (
            Text("Olá, " + name + "!")
                .font(.title.weight(.regular))
        )
        .foregroundStyle(Color.Token.textBrand)
    }
}

// MARK: - Navegador de semana

struct WeekNavigatorView: View {
    @Binding var selection: WeekRange
    @State private var showCalendar = false

    private let calendar = Calendar.dashboard

    var body: some View {
        HStack(spacing: 12) {
            Button {
                moveWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Button {
                showCalendar.toggle()
            } label: {
                Text(selectedWeekText)
                .font(.title3.weight(.medium))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showCalendar, arrowEdge: .top) {
                WeekRangePicker(selection: $selection)
            }

            Button {
                moveWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.Token.interactiveAccent)
    }
    private var selectedWeekText: String {
        let start = selection.start.formatted(.dateTime.locale(Locale(identifier: "pt_BR")).day().month(.abbreviated))
        let end = selection.end.formatted(.dateTime.locale(Locale(identifier: "pt_BR")).day().month(.abbreviated).year())
        return "\(start) - \(end)"
    }

    private func moveWeek(by value: Int) {
        guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: value, to: selection.start) else {
            return
        }

        selection = WeekRange(start: nextWeek, calendar: calendar)
    }
}


// MARK: - Botões de ação da toolbar (filtro, ordenar, atualizar, novo item)

struct ToolbarActionsView: View {
    let teamNames: [String]
    let createItem: (BoardItemDraft, String, DashboardItemCategory) -> Void

    @State private var isSortPopoverPresented = false
    @State private var isFilterPopoverPresented = false
    @State private var isNewItemPresented = false
    @State private var sortOption: SortOption = .oldest
    @State private var selectedPeople: Set<String> = ["Leonardo Drummond", "Eduarda Vieira"]
    @State private var selectedSubjects: Set<String> = ["Pagamentos", "Entregas"]
    @State private var selectedTeams: Set<String> = ["Atendimento"]

    var body: some View {
        HStack(spacing: 16) {
            ToolbarIconButton(systemImage: "line.3.horizontal.decrease", accessibilityLabel: "Filtrar") {
                isFilterPopoverPresented.toggle()
                isSortPopoverPresented = false
            }
            .popover(
                isPresented: $isFilterPopoverPresented,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .top
            ) {
                FilterPopover(
                    selectedPeople: $selectedPeople,
                    selectedSubjects: $selectedSubjects,
                    selectedTeams: $selectedTeams,
                    teams: teamNames
                )
            }

            ToolbarIconButton(systemImage: "arrow.up.arrow.down", accessibilityLabel: "Ordenar") {
                isSortPopoverPresented.toggle()
                isFilterPopoverPresented = false
            }
            .popover(
                isPresented: $isSortPopoverPresented,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .top
            ) {
                SortPopover(selection: $sortOption)
            }

            DashboardToolbarPrimaryButton(title: "Atualizar", systemImage: "arrow.clockwise") {
                // Ação: atualizar
            }
            DashboardToolbarPrimaryButton(title: "Novo Item", systemImage: "plus") {
                isNewItemPresented = true
            }
        }
        .sheet(isPresented: $isNewItemPresented) {
            NewBoardItemSheet(teamNames: teamNames) { draft, team, category in
                createItem(draft, team, category)
            }
        }
    }
}

struct DashboardToolbarPrimaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.title2.weight(.regular))
                    Text(title)
                        .font(.title3.weight(.regular))
                }
            }
            .foregroundStyle(Color.Token.textOnAccent)
            .frame(height: 48)
            .padding(.horizontal, 28)
            .background(Capsule().fill(Color.Token.interactiveAccent))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .shadow(color: Color.Token.interactiveAccent.opacity(0.22), radius: 10, y: 4)
    }
}

struct NewBoardItemSheet: View {
    let teamNames: [String]
    let createItem: (BoardItemDraft, String, DashboardItemCategory) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft = BoardItemDraft()
    @State private var assigneesText = ""
    @State private var selectedTeam = ""
    @State private var selectedCategory: DashboardItemCategory = .meeting
    @State private var scheduledDate = Date.now

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Novo item")
                .font(.title2.weight(.semibold))

            ScrollView {
                Form {
                    TextField("Título", text: $draft.title)
                    TextField("Responsáveis", text: $assigneesText)
                    DatePicker(
                        "Data e hora",
                        selection: $scheduledDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    TextField("Local", text: $draft.location)

                    Picker("Time", selection: $selectedTeam) {
                        ForEach(teamNames, id: \.self) { team in
                            Text(team).tag(team)
                        }
                    }

                    Picker("Tipo", selection: $selectedCategory) {
                        ForEach(DashboardItemCategory.allCases, id: \.self) { category in
                            Text(category.title).tag(category)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descrição")
                        TextEditor(text: $draft.description)
                            .font(.body)
                            .frame(height: 150)
                            .accessibilityLabel("Descrição")
                    }
                }
                .formStyle(.grouped)
            }
            .frame(maxHeight: 460)

            HStack {
                Spacer()
                Button("Cancelar", role: .cancel) {
                    dismiss()
                }
                Button("Criar item") {
                    draft.assignees = assignees(from: assigneesText)
                    draft.dateText = formattedDateAndTime(scheduledDate)
                    createItem(draft, selectedTeam, selectedCategory)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedTeam.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 460, height: 630)
        .onAppear {
            selectedTeam = teamNames.first ?? ""
        }
    }
}


// MARK: - Board (colunas estilo Kanban)

struct BoardView: View {
    let columns: [BoardColumn]
    let filter: DashboardItemCategory?
    let searchText: String
    let markAsReviewed: (BoardItem.ID, BoardColumn.ID) -> Void
    let updateItem: (BoardItem.ID, BoardColumn.ID, BoardItemDraft) -> Void
    let archiveItem: (BoardItem.ID, BoardColumn.ID) -> Void
    let deleteItem: (BoardItem.ID, BoardColumn.ID) -> Void
    @State private var selectedTeam: TeamDetail?
    @State private var itemPendingDeletion: PendingDeletion?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 32) {
                ForEach(columns.map { $0.filtered(by: filter, matching: searchText) }) { column in
                    BoardColumnView(
                        column: column,
                        onSelectTeam: {
                            selectedTeam = MockData.teamDetails.first { $0.name == column.title }
                        },
                        markAsReviewed: { itemID in
                            markAsReviewed(itemID, column.id)
                        },
                        updateItem: { itemID, draft in
                            updateItem(itemID, column.id, draft)
                        },
                        archiveItem: { itemID in
                            archiveItem(itemID, column.id)
                        },
                        requestDeletion: { item in
                            itemPendingDeletion = PendingDeletion(item: item, columnID: column.id)
                        }
                    )
                        .frame(width: 320)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .scrollClipDisabled()
        .sheet(item: $selectedTeam) { team in
            TeamDetailSheet(team: team)
        }
        .alert("Excluir card?", isPresented: Binding(
            get: { itemPendingDeletion != nil },
            set: { if !$0 { itemPendingDeletion = nil } }
        ), presenting: itemPendingDeletion) { pendingDeletion in
            Button("Excluir", role: .destructive) {
                deleteItem(pendingDeletion.item.id, pendingDeletion.columnID)
            }
            Button("Cancelar", role: .cancel) {}
        } message: { pendingDeletion in
            Text("\"\(pendingDeletion.item.title)\" será movido para Excluídos e poderá ser restaurado por até 7 dias.")
        }
    }
}

private struct StoredItemsBoardView: View {
    let items: [StoredBoardItem]
    let title: String
    let actionTitle: String
    let actionSystemImage: String
    let action: (StoredBoardItem) -> Void

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView(
                "Nenhum card \(title.lowercased())",
                systemImage: "tray"
            )
            .frame(maxWidth: .infinity, minHeight: 220)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 32) {
                    ForEach(teamNames, id: \.self) { teamName in
                        let teamItems = items.filter { $0.teamName == teamName }
                        if !teamItems.isEmpty {
                            StoredItemsColumnView(
                                teamName: teamName,
                                items: teamItems,
                                timestampTitle: title,
                                actionTitle: actionTitle,
                                actionSystemImage: actionSystemImage,
                                action: action
                            )
                                .frame(width: 320)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .scrollClipDisabled()
        }
    }

    private var teamNames: [String] {
        Array(Set(items.map(\.teamName))).sorted()
    }
}

private struct StoredItemsColumnView: View {
    let teamName: String
    let items: [StoredBoardItem]
    let timestampTitle: String
    let actionTitle: String
    let actionSystemImage: String
    let action: (StoredBoardItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(teamName)
                .font(.headline)
                .foregroundStyle(Color.Token.textPrimary)
            Divider()
            ForEach(items) { storedItem in
                StoredBoardItemCard(
                    item: storedItem,
                    timestampTitle: timestampTitle,
                    actionTitle: actionTitle,
                    actionSystemImage: actionSystemImage,
                    action: { action(storedItem) }
                )
            }
        }
    }
}

private struct StoredBoardItemCard: View {
    let item: StoredBoardItem
    let timestampTitle: String
    let actionTitle: String
    let actionSystemImage: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.Token.textPrimary)
            if let description = item.item.descriptionText {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.Token.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !item.item.assignees.isEmpty {
                Text(item.item.assignees.map(\.name).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(Color.Token.textSecondary)
            }
            Label(
                "\(timestampTitle) \(item.storedAt.formatted(.dateTime.day().month(.abbreviated).year().hour().minute()))",
                systemImage: "calendar"
            )
            .font(.caption)
            .foregroundStyle(Color.Token.textSecondary)
            Button(actionTitle, systemImage: actionSystemImage, action: action)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(GlassCardModifier())
    }
}

private struct PendingDeletion: Identifiable {
    let item: BoardItem
    let columnID: BoardColumn.ID

    var id: BoardItem.ID { item.id }
}

struct BoardColumnView: View {
    let column: BoardColumn
    let onSelectTeam: () -> Void
    let markAsReviewed: (BoardItem.ID) -> Void
    let updateItem: (BoardItem.ID, BoardItemDraft) -> Void
    let archiveItem: (BoardItem.ID) -> Void
    let requestDeletion: (BoardItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onSelectTeam) {
                Text(column.title)
                    .font(.headline)
                    .foregroundStyle(Color.Token.textPrimary)
                Spacer()
                Image(systemName: "arrow.down.left.and.arrow.up.right")
            }
            .buttonStyle(.plain)
            .accessibilityHint("Abre os detalhes da equipe \(column.title)")

            Divider()

            if column.items.isEmpty {
                EmptyColumnView()
            } else {
                ForEach(column.items) { item in
                    BoardItemCardView(
                        item: item,
                        markAsReviewed: markAsReviewed,
                        updateItem: updateItem,
                        archiveItem: archiveItem,
                        requestDeletion: requestDeletion
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyColumnView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wind")
                .font(.largeTitle.weight(.light))
                .foregroundStyle(Color.Token.textSecondary)
            Text("Tudo calmo por aqui!")
                .font(.subheadline)
                .foregroundStyle(Color.Token.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding(.top, 24)
    }
}

// MARK: - Card de item, com material Liquid Glass

struct BoardItemCardView: View {
    let item: BoardItem
    let markAsReviewed: (BoardItem.ID) -> Void
    let updateItem: (BoardItem.ID, BoardItemDraft) -> Void
    let archiveItem: (BoardItem.ID) -> Void
    let requestDeletion: (BoardItem) -> Void
    @State private var isHovering = false
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if item.isAwaitingReview {
                HStack(alignment: .top) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.Token.textPrimary)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    UnreadCardActionsView {
                        isEditing = true
                    } markAsReviewed: {
                        markAsReviewed(item.id)
                    }
                }
            } else {
                HStack(alignment: .top) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.Token.textPrimary)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    Menu {
                        Button("Editar", systemImage: "pencil") {
                            isEditing = true
                        }
                        Button("Arquivar", systemImage: "archivebox") {
                            archiveItem(item.id)
                        }
                        Button("Excluir", systemImage: "trash", role: .destructive) {
                            requestDeletion(item)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(90))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
            }

            if let description = item.descriptionText {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.Token.textSecondary)
                    .lineLimit(3)

                if description.count > 120 {
                    Button("Ler mais") {
                        isEditing = true
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.link)
                    .accessibilityHint("Abre o card com a descrição completa")
                }
            }

            if let assignee = item.assignees.first {
                MetadataRow(
                    systemImage: assignee.isGroup ? "person.2.fill" : "person.fill",
                    text: item.assignees.count == 1 ? assignee.name : "\(assignee.name) +\(item.assignees.count - 1)"
                )
            }

            if let dateText = item.dateText {
                MetadataRow(
                    systemImage: "calendar",
                    text: item.isRescheduled ? "Nova data: \(dateText)" : dateText,
                    highlighted: item.isRescheduled
                )
            }

            if let location = item.location {
                MetadataRow(systemImage: "mappin.and.ellipse", text: location)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 180, alignment: .topLeading)
        .modifier(BoardItemCardAppearanceModifier(isAwaitingReview: item.isAwaitingReview))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovering = hovering }
        }
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .sheet(isPresented: $isEditing) {
            BoardItemEditorSheet(item: item) { draft in
                updateItem(item.id, draft)
            }
        }
    }
}

private struct UnreadCardActionsView: View {
    let edit: () -> Void
    let markAsReviewed: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button("Editar", systemImage: "pencil", action: edit)
                .labelStyle(.iconOnly)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.Token.surfaceRaised, in: Circle())
            Button("Marcar como revisado", systemImage: "checkmark", action: markAsReviewed)
                .labelStyle(.iconOnly)
                .foregroundStyle(Color.Token.textOnAccent)
                .frame(width: 44, height: 44)
                .background(Color.Token.statusSuccess, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct BoardItemCardAppearanceModifier: ViewModifier {
    let isAwaitingReview: Bool

    func body(content: Content) -> some View {
        if isAwaitingReview {
            content
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.Token.surfaceAttention)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            Color.Token.statusWarning,
                            style: StrokeStyle(lineWidth: 2, dash: [10, 8])
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
        } else {
            content.modifier(GlassCardModifier())
        }
    }
}

private struct BoardItemEditorSheet: View {
    let item: BoardItem
    let save: (BoardItemDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: BoardItemDraft
    @State private var assigneesText: String
    @State private var scheduledDate: Date
    @State private var didChangeScheduledDate = false

    init(item: BoardItem, save: @escaping (BoardItemDraft) -> Void) {
        self.item = item
        self.save = save
        _draft = State(initialValue: BoardItemDraft(item: item))
        _assigneesText = State(initialValue: item.assignees.map(\.name).joined(separator: ", "))
        _scheduledDate = State(initialValue: .now)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Editar card")
                .font(.title2.weight(.semibold))

            ScrollView {
                Form {
                    TextField("Título", text: $draft.title)
                    TextField("Responsáveis", text: $assigneesText)
                    DatePicker(
                        "Data e hora",
                        selection: $scheduledDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .onChange(of: scheduledDate) {
                        didChangeScheduledDate = true
                    }
                    TextField("Local", text: $draft.location)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descrição")
                        TextEditor(text: $draft.description)
                            .font(.body)
                            .frame(height: 150)
                            .accessibilityLabel("Descrição")
                    }
                }
                .formStyle(.grouped)
            }
            .frame(maxHeight: 390)

            HStack {
                Spacer()
                Button("Cancelar", role: .cancel) {
                    dismiss()
                }
                Button("Salvar") {
                    draft.assignees = assignees(from: assigneesText)
                    if didChangeScheduledDate {
                        draft.dateText = formattedDateAndTime(scheduledDate)
                    }
                    save(draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 460, height: 560)
    }
}

private func assignees(from names: String) -> [Assignee] {
    names
        .split(separator: ",")
        .map { name in
            let trimmedName = name.trimmingCharacters(in: .whitespaces)
            return Assignee(name: trimmedName, isGroup: trimmedName.contains("&"))
        }
}

private func formattedDateAndTime(_ date: Date) -> String {
    date.formatted(
        .dateTime
            .locale(Locale(identifier: "pt_BR"))
            .day()
            .month(.abbreviated)
            .year()
            .hour()
            .minute()
    )
}

private struct MetadataRow: View {
    let systemImage: String
    let text: String
    var highlighted: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(Color.Token.iconAccent)
            Text(text)
                .font(.caption.weight(highlighted ? .semibold : .regular))
                .foregroundStyle(highlighted ? Color.Token.statusAttention : Color.Token.textSecondary)
        }
    }
}

// MARK: - Rodapé

struct FooterView: View {
    let lastUpdated: String

    var body: some View {
        VStack {
            Spacer()
            Text("Última atualização em \(lastUpdated)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Modificadores de "Liquid Glass"
//
// As APIs `glassEffect(_:in:)` e `GlassEffectContainer` (introduzidas nas
// plataformas Apple de 2025/2026) aplicam o material translúcido "Liquid
// Glass" recomendado pela HIG para superfícies de controle e cards
// flutuantes. Os modificadores abaixo encapsulam o uso correto (incluindo
// o agrupamento via `GlassEffectContainer`, necessário para transições
// suaves entre elementos de vidro adjacentes) e caem para `.ultraThinMaterial`
// em versões de sistema anteriores, preservando a aparência em ambos os casos.

/// Container que agrupa elementos de vidro adjacentes, permitindo que o
/// sistema funda/anime as formas entre si (comportamento nativo do
/// Liquid Glass). Faz fallback para um `HStack` simples em versões antigas.
struct GlassEffectContainerCompat<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        if #available(macOS 26.0, iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

/// Aplica o efeito de vidro em forma de "pílula" (cápsula), usado em
/// botões e no campo de busca.
struct GlassPillModifier: ViewModifier {
    let tint: Color?
    let isSelected: Bool
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        if #available(macOS 26.0, iOS 26.0, *) {
            content
                .glassEffect(
                    tint.map { .regular.tint($0).interactive() } ?? .regular.interactive(),
                    in: .capsule
                )
        } else {
            content
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            tint != nil
                            ? AnyShapeStyle(tint!.gradient)
                            : AnyShapeStyle(.ultraThinMaterial)
                        )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        }
    }
}

/// Aplica o efeito de vidro em cards retangulares de conteúdo (colunas do board).
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14

    func body(content: Content) -> some View {
        if #available(macOS 26.0, iOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06))
                )
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .frame(minWidth: 1200, minHeight: 800)
}
