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

// MARK: - View principal

struct DashboardView: View {
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var selectedDestination: SidebarDestination? = .dashboard
    @State private var selectedTab: FilterTab = MockData.filterTabs.first!
    @State private var searchText: String = ""
    @State private var weekRangeText: String = "26 de julho a 01 de agosto, 2026"

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selectedDestination)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 260)
        } detail: {
            SidebarDetailView(
                selection: selectedDestination,
                searchText: $searchText,
                weekRangeText: $weekRangeText,
                selectedTab: $selectedTab
            )
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// MARK: - Destino da navegação

private struct SidebarDetailView: View {
    let selection: SidebarDestination?
    @Binding var searchText: String
    @Binding var weekRangeText: String
    @Binding var selectedTab: FilterTab

    @ViewBuilder
    var body: some View {
        switch selection {
        case .dashboard:
            DashboardContentView(
                searchText: $searchText,
                weekRangeText: $weekRangeText,
                selectedTab: $selectedTab
            )
        case .timeline:
            TimelineView()
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
        (
            Text("Olá, " + name + "!")
                .font(.title.weight(.regular))
        )
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
                .font(.title3.weight(.medium))

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
                    .font(.subheadline.weight(.semibold))
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
    @State private var selectedTeam: TeamDetail?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 32) {
                ForEach(columns) { column in
                    BoardColumnView(column: column) {
                        selectedTeam = MockData.teamDetails.first { $0.name == column.title }
                    }
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
    }
}

struct BoardColumnView: View {
    let column: BoardColumn
    let onSelectTeam: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onSelectTeam) {
                Text(column.title)
                    .font(.headline)
                    .foregroundStyle(.blue)
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
                .font(.subheadline)
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
                    .font(.subheadline.weight(.semibold))
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
                    .font(.caption)
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
                .font(.caption)
                .foregroundStyle(.blue)
            Text(text)
                .font(.caption.weight(highlighted ? .semibold : .regular))
                .foregroundStyle(highlighted ? .red : .secondary)
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
        .font(.subheadline)
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
    DashboardView()
        .frame(minWidth: 1200, minHeight: 800)
}
