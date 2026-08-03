//
//  WeeklyBriefingDashboard.swift
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

// MARK: - Modelos de dados

/// Uma pessoa (ou grupo) atribuída a um item do board.
struct Assignee: Identifiable, Hashable {
    let id = UUID()
    let name: String
    /// Se `true`, usa o símbolo "person.2.fill" (grupo). Caso contrário, "person.fill".
    let isGroup: Bool
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

/// Uma coluna do board (ex.: "Atendimento", "Design"...).
struct BoardColumn: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let items: [BoardItem]
}

/// Uma aba de filtro no topo (ex.: "Geral", "Reuniões"...), com contador.
struct FilterTab: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let count: Int
}

/// Item de navegação da sidebar recolhível.
struct SidebarItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let systemImage: String
}

// MARK: - View principal

struct WeeklyBriefingDashboard: View {
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var selectedSidebarItem: SidebarItem? = MockData.sidebarItems.first
    @State private var selectedTab: FilterTab = MockData.filterTabs.first!
    @State private var searchText: String = ""
    @State private var weekRangeText: String = "26 de julho a 01 de agosto, 2026"

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(items: MockData.sidebarItems, selection: $selectedSidebarItem)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 260)
        } detail: {
            DashboardContentView(
                searchText: $searchText,
                weekRangeText: $weekRangeText,
                selectedTab: $selectedTab
            )
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// MARK: - Sidebar recolhível

/// Sidebar de navegação seguindo o padrão `NavigationSplitView` do macOS,
/// que já oferece o botão nativo de recolher/expandir na toolbar.
struct SidebarView: View {
    let items: [SidebarItem]
    @Binding var selection: SidebarItem?

    var body: some View {
        List(items, selection: $selection) { item in
            Label(item.title, systemImage: item.systemImage)
                .tag(item)
        }
        .listStyle(.sidebar)
        .navigationTitle("Painel")
    }
}

// MARK: - Conteúdo principal do dashboard

struct DashboardContentView: View {
    @Binding var searchText: String
    @Binding var weekRangeText: String
    @Binding var selectedTab: FilterTab

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                GreetingHeaderView(name: "Fabíola")

                WeekNavigatorView(rangeText: $weekRangeText)

                HStack(alignment: .center, spacing: 16) {
                    FilterTabsView(tabs: MockData.filterTabs, selection: $selectedTab)
                    Spacer(minLength: 12)
                    ToolbarActionsView()
                }

                BoardView(columns: MockData.columns)

                FooterView(lastUpdated: "29 de julho, 14:30h")
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .principal) {
                SearchFieldView(text: $searchText)
                    .frame(width: 280)
            }
        }
        .navigationTitle("")
    }
}

// MARK: - Cabeçalho de saudação

struct GreetingHeaderView: View {
    let name: String

    var body: some View {
        Text("Olá, ")
            .font(.system(size: 26, weight: .regular))
            .foregroundStyle(.blue)
        Text(name + "!")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(.blue)
    }
}

// MARK: - Navegador de semana

struct WeekNavigatorView: View {
    @Binding var rangeText: String

    var body: some View {
        HStack(spacing: 12) {
            Button {
                // Ação: semana anterior
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Text(rangeText)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.blue)

            Button {
                // Ação: próxima semana
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.blue)
    }
}

// MARK: - Abas de filtro (com badges) usando Liquid Glass

struct FilterTabsView: View {

    let tabs: [FilterTab]
    @Binding var selection: FilterTab
    @Namespace private var glassSelection: Namespace.ID

    var body: some View {

        HStack(spacing: 4) {

            ForEach(tabs) { tab in

                FilterTabButton(
                    tab: tab,
                    isSelected: tab == selection,
                    glassSelection: glassSelection
                ) {
                    withAnimation(.snappy(duration: 0.35)) {
                        selection = tab
                    }
                }

            }

        }
        .padding(4)
        .background {

            RoundedRectangle(cornerRadius: 20)
                .glassEffect()

        }
    }
}

struct FilterTabButton: View {

    let tab: FilterTab
    let isSelected: Bool
    let glassSelection: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {

            Text(tab.title)
                .font(.headline)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(.rect)

        }
        .buttonStyle(.plain)
        .background {

            if isSelected {

                RoundedRectangle(cornerRadius: 16)
                    .glassEffect()
                    .matchedGeometryEffect(
                        id: "selection",
                        in: glassSelection
                    )

            }

        }
    }
}

/// Badge circular numerado, reutilizado nas abas e nos cards.
struct CountBadge: View {
    let count: Int
    var prominent: Bool = false

    var body: some View {
        Text("\(count)")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(
                Circle()
                    .fill(prominent ? AnyShapeStyle(Color.white.opacity(0.25)) : AnyShapeStyle(Color.red.gradient))
            )
    }
}

// MARK: - Botões de ação da toolbar (filtro, ordenar, atualizar, novo item)

struct ToolbarActionsView: View {
    var body: some View {
        GlassEffectContainerCompat(spacing: 8) {
            HStack(spacing: 8) {
                GlassIconButton(systemImage: "line.3.horizontal.decrease") {
                    // Ação: filtrar
                }
                GlassIconButton(systemImage: "arrow.up.arrow.down") {
                    // Ação: ordenar
                }
                GlassLabeledButton(title: "Atualizar", systemImage: "arrow.clockwise") {
                    // Ação: atualizar
                }
                GlassLabeledButton(title: "Novo item", systemImage: "plus", prominent: true) {
                    // Ação: novo item
                }
            }
        }
    }
}

private struct GlassIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .modifier(GlassPillModifier(tint: .accentColor, isSelected: true, cornerRadius: 18))
    }
}

private struct GlassLabeledButton: View {
    let title: String
    let systemImage: String
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 9)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .modifier(GlassPillModifier(tint: .accentColor, isSelected: true))
    }
}

// MARK: - Board (colunas estilo Kanban)

struct BoardView: View {
    let columns: [BoardColumn]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 32) {
                ForEach(columns) { column in
                    BoardColumnView(column: column)
                        .frame(width: 320)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .scrollClipDisabled()
    }
}

struct BoardColumnView: View {
    let column: BoardColumn

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(column.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.blue)

            Divider()

            if column.items.isEmpty {
                EmptyColumnView()
            } else {
                ForEach(column.items) { item in
                    BoardItemCardView(item: item)
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
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary)
            Text("Tudo calmo por aqui!")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding(.top, 24)
    }
}

// MARK: - Card de item, com material Liquid Glass

struct BoardItemCardView: View {
    let item: BoardItem
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                if let badgeCount = item.badgeCount {
                    CountBadge(count: badgeCount)
                }

                Menu {
                    Button("Editar", systemImage: "pencil") {}
                    Button("Arquivar", systemImage: "archivebox") {}
                    Button("Excluir", systemImage: "trash", role: .destructive) {}
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(90))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            if let description = item.descriptionText {
                Text(description)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !item.assignees.isEmpty {
                ForEach(item.assignees) { assignee in
                    MetadataRow(
                        systemImage: assignee.isGroup ? "person.2.fill" : "person.fill",
                        text: assignee.name
                    )
                }
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
        .modifier(GlassCardModifier())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovering = hovering }
        }
        .scaleEffect(isHovering ? 1.01 : 1.0)
    }
}

private struct MetadataRow: View {
    let systemImage: String
    let text: String
    var highlighted: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11))
                .foregroundStyle(.blue)
            Text(text)
                .font(.system(size: 12.5, weight: highlighted ? .semibold : .regular))
                .foregroundStyle(highlighted ? .red : .secondary)
        }
    }
}

// MARK: - Rodapé

struct FooterView: View {
    let lastUpdated: String

    var body: some View {
        HStack {
            Spacer()
            Text("Última atualização em \(lastUpdated)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Campo de busca da toolbar

struct SearchFieldView: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Buscar informações e arquivos...", text: $text)
                .textFieldStyle(.plain)
        }
        .font(.system(size: 13))
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .modifier(GlassPillModifier(tint: nil, isSelected: false))
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
/// botões, abas e no campo de busca.
struct GlassPillModifier: ViewModifier {
    let tint: Color?
    let isSelected: Bool
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        if #available(macOS 26.0, iOS 26.0, *) {
            content
                .glassEffect(
                    tint.map { .regular.tint($0).interactive() } ?? .regular.interactive(),
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint != nil ? AnyShapeStyle(tint!.gradient) : AnyShapeStyle(.ultraThinMaterial))
                )
        }
    }
}

/// Aplica o efeito de vidro em cards retangulares de conteúdo (colunas do board).
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, iOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: 14))
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06))
                )
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        }
    }
}

// MARK: - Preview

#Preview {
    WeeklyBriefingDashboard()
        .frame(minWidth: 1200, minHeight: 800)
}
