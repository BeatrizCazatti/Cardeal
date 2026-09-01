import SwiftUI

// MARK: - Abas de filtro

/// Barra de filtros baseada no `ClearSegmentedPicker`: seus segmentos têm
/// largura natural, indicador de vidro, toque, arrasto e snap com spring.
struct FilterTabsView: View {
    @ObservedObject var badgeStore: DashboardBadgeStore
    @Binding var selection: FilterTab

    private var tabs: [FilterTab] { badgeStore.tabs }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            tabTrack
                .fixedSize(horizontal: true, vertical: false)

            ScrollView(.horizontal, showsIndicators: false) {
                tabTrack
                    .fixedSize(horizontal: true, vertical: false)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.84),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        // Mantém a largura natural das abas para não comprimir os controles
        // que as acompanham na barra do dashboard.
        .layoutPriority(0)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filtros do dashboard")
    }

    private var tabTrack: some View {
        ClearSegmentedPicker(
            tabs: tabs.map(\.title),
            colors: tabs.map { color(for: $0.destination) },
            badges: tabs.map(\.count),
            selectedTextColor: Color.Token.textPrimary,
            unselectedTextColor: Color.Token.textNavigation,
            currentTab: selectedIndex
        )
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.Token.surfaceRaised, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Color.Token.borderSubtle.opacity(0.65), lineWidth: 1)
        }
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
        case .archived: Color.Token.themeMunimAccent
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
