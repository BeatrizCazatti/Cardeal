import SwiftUI

// MARK: - Abas de filtro

/// Barra de filtros baseada no `ClearSegmentedPicker`: seus segmentos têm
/// largura natural, indicador de vidro, toque, arrasto e snap com spring.
struct FilterTabsView: View {
    @ObservedObject var badgeStore: DashboardBadgeStore
    @Binding var selection: FilterTab

    private var tabs: [FilterTab] { badgeStore.tabs }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ClearSegmentedPicker(
                tabs: tabs.map(\.title),
                colors: tabs.map { color(for: $0.destination) },
                badges: tabs.map(\.count),
                selectedTextColor: Color.Token.textPrimary,
                unselectedTextColor: Color.Token.textNavigation,
                currentTab: selectedIndex
            )
            // O picker mantém a largura do conteúdo; o ScrollView passa a
            // rolar em vez de comprimir/truncar os segmentos na toolbar.
            .fixedSize(horizontal: true, vertical: false)
            // Os badges avançam 9pt além do segmento. Esta área segura evita
            // que o clipping natural do ScrollView corte seu topo e direita.
            .padding(.top, 12)
            .padding(.trailing, 24)
            .padding(.leading, 4)
            .padding(.bottom, 4)
        }
        .frame(minHeight: 58, alignment: .bottomLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(1)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filtros do dashboard")
    }

    private var selectedIndex: Binding<Int> {
        Binding(
            get: {
                tabs.firstIndex { $0.destination == selection.destination } ?? 0
            },
            set: { index in
                guard tabs.indices.contains(index) else { return }
                selection = tabs[index]
            }
        )
    }

    private func color(for destination: DashboardTabDestination) -> Color {
        switch destination {
        case .active: Color.Token.interactiveAccent
        case .archived: Color.Token.themeOceanAccent
        case .deleted: Color.Token.statusAttention
        }
    }
}

private extension DashboardTabDestination {
    var systemImage: String {
        switch self {
        case .active(nil): "square.grid.2x2"
        case .active(.meeting): "person.2"
        case .active(.task): "checkmark.circle"
        case .active(.change): "arrow.triangle.2.circlepath"
        case .active(.decision): "arrow.triangle.branch"
        case .archived: "archivebox"
        case .deleted: "trash"
        }
    }
}
