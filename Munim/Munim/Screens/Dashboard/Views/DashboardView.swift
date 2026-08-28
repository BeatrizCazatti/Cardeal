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
    @Environment(\.appTheme) private var theme
    var body: some View {
        ZStack {
            // O gradiente vive no nível do SplitView para preencher
            // a janela inteira — inclusive a coluna da sidebar, que
            // fica translúcida (.ultraThinMaterial) e deixa o gradiente
            // aparecer através dos itens.
            ThemeGradientBackground(theme: theme)
                .ignoresSafeArea()

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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        case .archived:
            StoredItemsDetailView(
                title: "Arquivados",
                items: archivedItems,
                actionTitle: "Desarquivar",
                actionSystemImage: "tray.and.arrow.up",
                searchText: $searchText,
                action: unarchiveItem
            )
        case .deleted:
            StoredItemsDetailView(
                title: "Excluídos",
                items: deletedItems,
                actionTitle: "Restaurar",
                actionSystemImage: "arrow.uturn.backward",
                searchText: $searchText,
                action: restoreDeletedItem
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

private struct StoredItemsDetailView: View {
    let title: String
    let items: [StoredBoardItem]
    let actionTitle: String
    let actionSystemImage: String
    @Binding var searchText: String
    let action: (StoredBoardItem) -> Void

    private var visibleItems: [StoredBoardItem] {
        items.filter { $0.item.matches(searchQuery: searchText) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(title)
                    .font(.largeTitle.weight(.regular))
                    .foregroundStyle(Color.Token.textBrand)

                StoredItemsBoardView(
                    items: visibleItems,
                    title: title,
                    actionTitle: actionTitle,
                    actionSystemImage: actionSystemImage,
                    action: action
                )
            }
            .padding(24)
        }
        .background(Color.Token.backgroundPrimary)
        .searchable(text: $searchText, placement: .toolbar, prompt: "Buscar cards")
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
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Cabeçalho com saudação e navegador de semana
                    HStack(alignment: .center) {
                        GreetingHeaderView(name: "Fabíola")
                        Spacer()
                        WeekNavigatorView(selection: $selectedWeek)
                    }

                    HStack(alignment: .center, spacing: 12) {
                        FilterTabsView(badgeStore: badgeStore, selection: $selectedTab)

                        DashboardToolbarPrimaryButton(title: "Novo item", systemImage: "plus") {
                            isNewItemPresented = true
                        }

                        Spacer(minLength: 16)

                        DashboardRefreshStatusView()
                    }

                    dashboardBoard
                }
                .padding(24)
                .frame(
                    maxWidth: .infinity,
                    minHeight: max(0, proxy.size.height - 20),
                    alignment: .topLeading
                )
                .background {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 20,
                        style: .continuous
                    )
                    .fill(Color.Token.backgroundPrimary)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                DashboardToolbarControls(teamNames: columns.map(\.title), searchText: $searchText)
            }
        }
        .sheet(isPresented: $isNewItemPresented) {
            NewBoardItemSheet(teamNames: columns.map(\.title)) { draft, team, category in
                createItem(draft, team, category)
            }
        }
    }

    @State private var isNewItemPresented = false

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
    @Environment(\.appTheme) private var theme

    private let calendar = Calendar.dashboard

    var body: some View {
        HStack(spacing: 12) {
            Button {
                moveWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(theme.accentColor)
            }
            .buttonStyle(.plain)

            Button {
                showCalendar.toggle()
            } label: {
                Text(selectedWeekText)
                .font(.title3.weight(.medium))
                .foregroundStyle(theme.accentColor)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showCalendar, arrowEdge: .top) {
                WeekRangePicker(selection: $selection)
            }

            Button {
                moveWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(theme.accentColor)
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


// MARK: - Controles do dashboard

private struct DashboardToolbarControls: View {
    let teamNames: [String]
    @Binding var searchText: String

    @State private var isSortPopoverPresented = false
    @State private var isFilterPopoverPresented = false
    @State private var isSearchExpanded = false
    @State private var sortOption: SortOption = .oldest
    @State private var selectedPeople: Set<String> = ["Leonardo Drummond", "Eduarda Vieira"]
    @State private var selectedSubjects: Set<String> = ["Pagamentos", "Entregas"]
    @State private var selectedTeams: Set<String> = ["Atendimento"]
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            DashboardToolbarIconButton(systemImage: "line.3.horizontal.decrease", accessibilityLabel: "Filtrar") {
                isFilterPopoverPresented.toggle()
                isSortPopoverPresented = false
                collapseSearch()
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

            Divider()
                .frame(height: 18)

            DashboardToolbarIconButton(systemImage: "arrow.up.arrow.down", accessibilityLabel: "Ordenar") {
                isSortPopoverPresented.toggle()
                isFilterPopoverPresented = false
                collapseSearch()
            }
            .popover(
                isPresented: $isSortPopoverPresented,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .top
            ) {
                SortPopover(selection: $sortOption)
            }

            Divider()
                .frame(height: 18)

            // Botão de busca expansível
            ExpandableSearchButton(
                searchText: $searchText,
                isExpanded: $isSearchExpanded,
                isSearchFieldFocused: $isSearchFieldFocused,
                onCollapse: { isSearchExpanded = false }
            )
        }
        .padding(3)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Color.Token.borderSubtle.opacity(0.75), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }

    private func collapseSearch() {
        if isSearchExpanded {
            withAnimation(.easeInOut(duration: 0.15)) {
                isSearchExpanded = false
            }
        }
    }
}

/// Botão de busca que expande para mostrar o campo de texto ao ser clicado
private struct ExpandableSearchButton: View {
    @Binding var searchText: String
    @Binding var isExpanded: Bool
    @FocusState.Binding var isSearchFieldFocused: Bool
    let onCollapse: () -> Void
    @StateObject private var recentSearchesStore = RecentSearchesStore.shared
    @State private var showSuggestions: Bool = false

    private var filteredSuggestions: [String] {
        recentSearchesStore.filteredSuggestions(for: searchText)
    }

    private var showRecentSearches: Bool {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isSearchFieldFocused
    }

    private var showFilteredSuggestions: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isSearchFieldFocused
    }

    var body: some View {
        HStack(spacing: 0) {
            // Botão do ícone de lupa (sempre visível)
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                    if isExpanded {
                        // Pequeno delay para garantir que a animação termine antes de focar
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isSearchFieldFocused = true
                        }
                    } else {
                        isSearchFieldFocused = false
                        onCollapse()
                    }
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isExpanded || isSearchFieldFocused ? Color.Token.interactiveAccent : Color.Token.textSecondary)
                    .frame(width: 30, height: 30)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Buscar")

            // Campo de busca expansível
            if isExpanded {
                searchFieldContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity.combined(with: .scale(scale: 0.8, anchor: .trailing))
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isExpanded)
    }

    @ViewBuilder
    private var searchFieldContent: some View {
        HStack(spacing: 8) {
            // Campo de texto
            TextField("Buscar cards, pessoas e locais", text: $searchText)
                .textFieldStyle(.plain)
                .font(.callout)
                .foregroundStyle(Color.Token.textPrimary)
                .focused($isSearchFieldFocused)
                .frame(width: isSearchFieldFocused ? 280 : 200)
                .onChange(of: searchText) { _, newValue in
                    if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showSuggestions = true
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showSuggestions = false
                        }
                    }
                }
                .onSubmit {
                    if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        recentSearchesStore.addSearch(searchText)
                    }
                }

            // Botão de limpar (X) - aparece quando há texto
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showSuggestions = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.Token.textSecondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }

            // Botão de fechar (X) - sempre visível quando expandido
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded = false
                    isSearchFieldFocused = false
                    onCollapse()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.Token.textSecondary)
                    .frame(width: 30, height: 30)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar busca")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color.Token.surfaceRaised)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.Token.borderSubtle, lineWidth: 1)
                )
        )
        // Painel de sugestões
        .popover(
            isPresented: Binding(
                get: { showSuggestions && isSearchFieldFocused && (showFilteredSuggestions || showRecentSearches) },
                set: { showSuggestions = $0 }
            ),
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .bottom
        ) {
            suggestionsPopover
                .frame(width: 340)
        }
        .onChange(of: isSearchFieldFocused) { _, focused in
            if !focused {
                // Delay para permitir cliques no popover
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if !showSuggestions {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isExpanded = false
                            onCollapse()
                        }
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showSuggestions = true
                }
            }
        }
    }

    @ViewBuilder
    private var suggestionsPopover: some View {
        VStack(spacing: 0) {
            if showFilteredSuggestions && !filteredSuggestions.isEmpty {
                SearchSuggestionsPopoverSection(
                    title: "Sugestões de Pesquisa",
                    items: filteredSuggestions,
                    onSelect: { suggestion in
                        searchText = suggestion
                        recentSearchesStore.addSearch(suggestion)
                        isSearchFieldFocused = false
                    },
                    onDelete: { suggestion in
                        recentSearchesStore.removeSearch(suggestion)
                    }
                )
            } else if showRecentSearches && !recentSearchesStore.recentSearches.isEmpty {
                SearchSuggestionsPopoverSection(
                    title: "Pesquisas Recentes",
                    items: recentSearchesStore.recentSearches,
                    showClearAll: true,
                    onSelect: { suggestion in
                        searchText = suggestion
                        recentSearchesStore.addSearch(suggestion)
                        isSearchFieldFocused = false
                    },
                    onDelete: { suggestion in
                        recentSearchesStore.removeSearch(suggestion)
                    },
                    onClearAll: {
                        recentSearchesStore.clearAllSearches()
                    }
                )
            } else if showRecentSearches && recentSearchesStore.recentSearches.isEmpty {
                EmptyRecentSearchesPopoverView()
            }
        }
        .padding(8)
    }
}

/// Seção de sugestões para o popover
private struct SearchSuggestionsPopoverSection: View {
    let title: String
    let items: [String]
    var showClearAll: Bool = false
    let onSelect: (String) -> Void
    let onDelete: (String) -> Void
    var onClearAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.Token.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                if showClearAll {
                    Button("Limpar Tudo", action: onClearAll ?? {})
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.Token.interactiveAccent)
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                SearchSuggestionPopoverRow(
                    text: item,
                    isLast: index == items.count - 1,
                    onTap: { onSelect(item) },
                    onDelete: { onDelete(item) }
                )
            }
        }
    }
}

/// Linha de sugestão para o popover
private struct SearchSuggestionPopoverRow: View {
    let text: String
    let isLast: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var isHovering: Bool = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color.Token.iconAccent)
                    .frame(width: 20)

                Text(text)
                    .font(.callout)
                    .foregroundStyle(Color.Token.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isHovering {
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.Token.textSecondary)
                            .frame(width: 20, height: 20)
                            .background(Color.Token.surfaceRaised, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovering ? Color.Token.surfaceRaised.opacity(0.5) : Color.clear)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }

        if !isLast {
            Divider()
                .padding(.leading, 42)
        }
    }
}

/// View para estado vazio no popover
private struct EmptyRecentSearchesPopoverView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.title2.weight(.light))
                .foregroundStyle(Color.Token.textSecondary.opacity(0.5))

            Text("Nenhuma pesquisa recente")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.Token.textSecondary)

            Text("Suas pesquisas aparecerão aqui")
                .font(.caption)
                .foregroundStyle(Color.Token.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

private struct DashboardToolbarIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.Token.textSecondary)
                .frame(width: 30, height: 30)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct DashboardRefreshStatusView: View {
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Button("Atualizar", systemImage: "arrow.clockwise") {
                // Ação: atualizar
            }
            .labelStyle(.titleOnly)
            .font(.caption.weight(.semibold))
            .underline()
            .buttonStyle(.plain)
            .foregroundStyle(theme.accentColor)

            Text("Última atualização em 29 de julho, 14:30h")
                .font(.caption2)
                .foregroundStyle(Color.Token.textSecondary)
        }
        .frame(minWidth: 235, alignment: .trailing)
    }
}

private struct DashboardToolbarPrimaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    @Environment(\.appTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))

                Text(title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.Token.textOnAccent)
            .frame(minWidth: 136, minHeight: 44)
            .padding(.horizontal, 16)
            .background(Capsule().fill(theme.accentColor))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1)
        .shadow(color: Color.Token.interactiveAccent.opacity(0.16), radius: 4, y: 2)
        .accessibilityLabel(title)
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

                    BoardItemPriorityPicker(selection: $draft.priority)

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
            .frame(maxHeight: 500)

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
        .frame(width: 460, height: 670)
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
        // Altura mínima confortável para o board, sem cortar cards em telas comuns.
        // Em janelas muito altas o board cresce junto, evitando desperdiçar espaço
        // sem prender o usuário a um valor fixo pequeno demais.
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
        .frame(minHeight: 520)
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
            .frame(minHeight: 520)
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
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 12) {
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer()
                Image(systemName: "arrow.down.left.and.arrow.up.right")
            }
            .buttonStyle(.plain)
            .accessibilityHint("Abre os detalhes da equipe \(column.title)")

            Divider()

            if column.items.isEmpty {
                EmptyColumnView()
            } else {
                // Lista vertical rolável independente do scroll horizontal do board,
                // garantindo que cards longos não sejam cortados em janelas baixas.
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 12) {
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
        .frame(maxWidth: .infinity)
        .frame(minHeight: 160)
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
    @State private var isEditing = false

    /// Cards pendentes de revisão sempre usam uma superfície clara, inclusive
    /// no Dark Mode. Por isso, não podem herdar os tokens adaptativos de texto.
    private var titleColor: Color {
        item.isAwaitingReview ? .black.opacity(0.88) : Color.Token.textPrimary
    }

    private var supportingTextColor: Color {
        item.isAwaitingReview ? .black.opacity(0.64) : Color.Token.textSecondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                BoardItemPriorityTag(priority: item.priority)

                Spacer(minLength: 8)

                cardActions
            }

            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(titleColor)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            if let description = item.descriptionText {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(supportingTextColor)
                    .lineLimit(3)
                    .minimumScaleFactor(0.9)

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
                    text: item.assignees.count == 1 ? assignee.name : "\(assignee.name) +\(item.assignees.count - 1)",
                    textColor: supportingTextColor
                )
            }

            if let dateText = item.dateText {
                MetadataRow(
                    systemImage: "calendar",
                    text: item.isRescheduled ? "Nova data: \(dateText)" : dateText,
                    highlighted: item.isRescheduled && !item.isAwaitingReview,
                    textColor: supportingTextColor
                )
            }

            if let location = item.location {
                MetadataRow(
                    systemImage: "mappin.and.ellipse",
                    text: location,
                    textColor: supportingTextColor
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .modifier(BoardItemCardModifier(isAwaitingReview: item.isAwaitingReview))
        .sheet(isPresented: $isEditing) {
            BoardItemEditorSheet(item: item) { draft in
                updateItem(item.id, draft)
            }
        }
    }

    @ViewBuilder
    private var cardActions: some View {
        if item.isAwaitingReview {
            UnreadCardActionsView {
                isEditing = true
            } markAsReviewed: {
                markAsReviewed(item.id)
            }
        } else {
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
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}

private struct UnreadCardActionsView: View {
    let edit: () -> Void
    let markAsReviewed: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: edit) {
                Image(systemName: "pencil")
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Color.Token.surfaceRaised, in: Circle())
                    .contentShape(Circle())
            }
            .accessibilityLabel("Editar")

            Button(action: markAsReviewed) {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.Token.textOnAccent)
                    .frame(width: 44, height: 44)
                    .background(Color.Token.statusSuccess, in: Circle())
                    .contentShape(Circle())
            }
            .accessibilityLabel("Marcar como revisado")
        }
        .buttonStyle(.plain)
    }
}


//private struct BoardItemCardAppearanceModifier: ViewModifier {
//    let isAwaitingReview: Bool
//    @Environment(\.appTheme) private var theme
//
//    func body(content: Content) -> some View {
//        if isAwaitingReview {
//            content
//                .background(
//                    RoundedRectangle(cornerRadius: 14, style: .continuous)
//                        .fill(theme.newCardFillColor)
//                )
//                .overlay(
//                    RoundedRectangle(cornerRadius: 14, style: .continuous)
//                        .stroke(
//                            theme.newCardStrokeColor,
//                            style: StrokeStyle(lineWidth: 2, dash: [5, 6])
//                        )
//                )
////                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
//        } else {
//            content.modifier(GlassCardModifier())
//        }
//    }
//}

struct BoardItemCardModifier: ViewModifier {
    let isAwaitingReview: Bool
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background {
                if isAwaitingReview {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(theme.newCardFillColor)
                } else {
                    // Fundo sólido semitransparente/branco padrão de cartões no HIG
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(white: 1))
                }
            }
            .overlay {
                if isAwaitingReview {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            theme.newCardStrokeColor,
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                        )
                }
            }
            .shadow(
                color: Color.black.opacity(0.06),
                radius: 3,
                x: 0,
                y: 2
            )
    }
}

extension View {
    func boardItemCardStyle(isAwaitingReview: Bool = false) -> some View {
        self.modifier(BoardItemCardModifier(isAwaitingReview: isAwaitingReview))
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

                    BoardItemPriorityPicker(selection: $draft.priority)

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
            .frame(maxHeight: 400)

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
        .frame(width: 460, height: 600)
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

private struct BoardItemPriorityPicker: View {
    @Binding var selection: BoardItemPriority

    var body: some View {
        Picker("Prioridade", selection: $selection) {
            ForEach(BoardItemPriority.allCases) { priority in
                BoardItemPriorityTag(priority: priority)
                    .tag(priority)
            }
        }
    }
}

private struct BoardItemPriorityTag: View {
    let priority: BoardItemPriority

    private var accentColor: Color {
        switch priority {
        case .high: Color(hex: 0xEF626A)
        case .medium: Color(hex: 0xF5A33B)
        case .low: Color(hex: 0x4CACEF)
        case .unset: .gray.opacity(0.65)
        }
    }

    private var backgroundColor: Color {
        switch priority {
        case .high: Color(hex: 0xFDE2E4)
        case .medium: Color(hex: 0xFFE5BB)
        case .low: Color(hex: 0xD8EEFF)
        case .unset: Color.gray.opacity(0.14)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(accentColor)
                .frame(width: 10, height: 10)

            Text(priority.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.black.opacity(0.62))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(backgroundColor, in: Capsule(style: .continuous))
    }
}

private struct MetadataRow: View {
    let systemImage: String
    let text: String
    var highlighted: Bool = false
    var textColor: Color = Color.Token.textSecondary

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(Color.Token.iconAccent)
            Text(text)
                .font(.caption.weight(highlighted ? .semibold : .regular))
                .foregroundStyle(highlighted ? Color.Token.statusAttention : textColor)
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
//                .shadow(color: .red.opacity(0.06), radius: 6, y: 2)
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .frame(minWidth: 1200, minHeight: 800)
}
